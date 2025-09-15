# 监控与可观测性设计文档

## 📊 概述

Amazon Pilot 采用 Prometheus + Grafana 的监控方案，实现了完整的 RED (Rate, Errors, Duration) 指标监控体系。本文档详细说明了系统的监控架构、指标设计、以及具体的 PromQL 查询配置。

## 🏗️ 监控架构

### 技术栈
- **Prometheus**: 时序数据库，负责指标收集和存储
- **Grafana**: 可视化平台，提供监控仪表板
- **Node Exporter**: 系统级指标收集
- **Redis Exporter**: Redis 指标收集
- **Custom Metrics**: Gateway 自定义业务指标

### 架构图
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Gateway   │────▶│ Prometheus  │────▶│   Grafana   │
│  (metrics)  │     │   (9090)    │     │   (3001)    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                    ▲                    │
       │                    │                    │
       ▼                    │                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Services   │     │   Exporters │     │  Dashboard  │
│(auth,product)     │(node,redis) │     │   (RED)     │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 📈 Gateway Prometheus 指标

### 核心指标定义

Gateway 暴露以下 Prometheus 指标（端口 8080/metrics）：

#### 1. HTTP 请求总数
- **指标名**: `amazon_pilot_http_requests_total`
- **类型**: Counter
- **标签**: service, method, path, status
- **用途**: 统计请求速率（QPS）

#### 2. HTTP 请求耗时
- **指标名**: `amazon_pilot_http_request_duration_milliseconds`
- **类型**: Histogram
- **标签**: service, method, path
- **桶定义**: [1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]
- **用途**: 统计响应时间分布

#### 3. HTTP 错误总数
- **指标名**: `amazon_pilot_http_errors_total`
- **类型**: Counter
- **标签**: service, method, path, status
- **用途**: 统计错误率

#### 4. 活跃连接数
- **指标名**: `amazon_pilot_active_connections`
- **类型**: Gauge
- **标签**: service
- **用途**: 监控并发连接

#### 5. 服务健康状态
- **指标名**: `amazon_pilot_service_health`
- **类型**: Gauge
- **标签**: service
- **值**: 1=健康, 0=不健康
- **用途**: 服务健康检查

#### 6. JWT 认证统计
- **指标名**: `amazon_pilot_jwt_auth_total`
- **类型**: Counter
- **标签**: service, result (success/failure)
- **用途**: 监控认证成功率

#### 7. 限流统计
- **指标名**: `amazon_pilot_rate_limit_total`
- **类型**: Counter
- **标签**: service, plan, result (allowed/blocked)
- **用途**: 监控限流触发情况

## 🎯 RED 监控 PromQL 查询

### Rate (请求速率)

```promql
# 整体 QPS
sum(rate(amazon_pilot_http_requests_total[1m]))

# 按服务划分的 QPS
sum by (service) (rate(amazon_pilot_http_requests_total[1m]))

# 按状态码划分的 QPS
sum by (status) (rate(amazon_pilot_http_requests_total[1m]))

# 按 HTTP 方法划分的 QPS
sum by (method) (rate(amazon_pilot_http_requests_total[1m]))

# 特定服务的 QPS (例如 product 服务)
sum(rate(amazon_pilot_http_requests_total{service="product"}[1m]))

# Top 10 最高请求量的 API 路径
topk(10, sum by (path) (rate(amazon_pilot_http_requests_total[5m])))

# 请求增长率（相比 5 分钟前）
rate(amazon_pilot_http_requests_total[1m]) / rate(amazon_pilot_http_requests_total[1m] offset 5m)
```

### Errors (错误率)

```promql
# 整体错误率（百分比）
sum(rate(amazon_pilot_http_requests_total{status=~"4..|5.."}[1m]))
/ sum(rate(amazon_pilot_http_requests_total[1m])) * 100

# 按服务划分的错误率
sum by (service) (rate(amazon_pilot_http_requests_total{status=~"4..|5.."}[1m]))
/ sum by (service) (rate(amazon_pilot_http_requests_total[1m])) * 100

# 4xx 客户端错误率
sum(rate(amazon_pilot_http_requests_total{status=~"4.."}[1m]))
/ sum(rate(amazon_pilot_http_requests_total[1m])) * 100

# 5xx 服务端错误率
sum(rate(amazon_pilot_http_requests_total{status=~"5.."}[1m]))
/ sum(rate(amazon_pilot_http_requests_total[1m])) * 100

# 使用专门的错误指标计算错误数
sum(rate(amazon_pilot_http_errors_total[1m]))

# 按服务和状态码分组的错误数
sum by (service, status) (rate(amazon_pilot_http_errors_total[1m]))

# 错误率趋势（5 分钟移动平均）
avg_over_time(
  (sum(rate(amazon_pilot_http_requests_total{status=~"5.."}[1m]))
  / sum(rate(amazon_pilot_http_requests_total[1m])))[5m:]
) * 100
```

### Duration (延迟/耗时)

```promql
# P50 延迟（中位数）- 毫秒
histogram_quantile(0.5,
  sum by (service, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
)

# P90 延迟 - 毫秒
histogram_quantile(0.9,
  sum by (service, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
)

# P95 延迟 - 毫秒
histogram_quantile(0.95,
  sum by (service, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
)

# P99 延迟 - 毫秒
histogram_quantile(0.99,
  sum by (service, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
)

# 平均延迟 - 毫秒
sum by (service) (rate(amazon_pilot_http_request_duration_milliseconds_sum[5m]))
/ sum by (service) (rate(amazon_pilot_http_request_duration_milliseconds_count[5m]))

# 按路径统计的 P95 延迟
histogram_quantile(0.95,
  sum by (path, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
)

# 慢请求（>1秒）的比例
(sum(rate(amazon_pilot_http_request_duration_milliseconds_bucket{le="+Inf"}[5m]))
- sum(rate(amazon_pilot_http_request_duration_milliseconds_bucket{le="1000"}[5m])))
/ sum(rate(amazon_pilot_http_request_duration_milliseconds_count[5m])) * 100

# 延迟 SLO 达成率（95% 请求 < 500ms）
sum(rate(amazon_pilot_http_request_duration_milliseconds_bucket{le="500"}[5m]))
/ sum(rate(amazon_pilot_http_request_duration_milliseconds_count[5m])) * 100
```

## 🔍 业务指标查询

### 服务健康监控

```promql
# 服务健康状态
amazon_pilot_service_health

# 不健康服务数量
count(amazon_pilot_service_health == 0)

# 服务可用率（过去 1 小时）
avg_over_time(amazon_pilot_service_health[1h]) * 100
```

### 连接监控

```promql
# 活跃连接数
sum by (service) (amazon_pilot_active_connections)

# 总活跃连接数
sum(amazon_pilot_active_connections)

# 连接数峰值（过去 1 小时）
max_over_time(sum(amazon_pilot_active_connections)[1h:])
```

### 认证监控

```promql
# JWT 认证成功率
sum(rate(amazon_pilot_jwt_auth_total{result="success"}[5m]))
/ sum(rate(amazon_pilot_jwt_auth_total[5m])) * 100

# 认证失败次数
sum(rate(amazon_pilot_jwt_auth_total{result="failure"}[5m]))

# 按服务统计认证情况
sum by (service, result) (rate(amazon_pilot_jwt_auth_total[5m]))
```

### 限流监控

```promql
# 限流触发次数
sum by (service, result) (rate(amazon_pilot_rate_limit_total[5m]))

# 限流阻塞率
sum(rate(amazon_pilot_rate_limit_total{result="blocked"}[5m]))
/ sum(rate(amazon_pilot_rate_limit_total[5m])) * 100

# 按计划类型统计限流情况
sum by (plan, result) (rate(amazon_pilot_rate_limit_total[5m]))
```

## 📐 Grafana Dashboard 配置

### Dashboard 结构

#### Row 1: 概览指标
1. **当前 QPS** (Stat Panel)
   - Query: `sum(rate(amazon_pilot_http_requests_total[1m]))`
   - Unit: reqps
   - Thresholds: 0-100 (绿), 100-500 (黄), >500 (红)

2. **错误率** (Stat Panel)
   - Query: `sum(rate(amazon_pilot_http_requests_total{status=~"5.."}[1m])) / sum(rate(amazon_pilot_http_requests_total[1m])) * 100`
   - Unit: percent
   - Thresholds: 0-1 (绿), 1-5 (黄), >5 (红)

3. **P95 延迟** (Stat Panel)
   - Query: `histogram_quantile(0.95, sum(rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m])))`
   - Unit: ms
   - Thresholds: 0-500 (绿), 500-1000 (黄), >1000 (红)

4. **服务健康** (Stat Panel)
   - Query: `count(amazon_pilot_service_health == 1) / count(amazon_pilot_service_health) * 100`
   - Unit: percent
   - Thresholds: 100 (绿), 90-99 (黄), <90 (红)

#### Row 2: RED 指标趋势
1. **请求速率趋势** (Graph Panel)
   - Query: `sum by (service) (rate(amazon_pilot_http_requests_total[1m]))`
   - Legend: {{service}}
   - Stack: false

2. **错误率趋势** (Graph Panel)
   - Query: `sum by (service) (rate(amazon_pilot_http_requests_total{status=~"4..|5.."}[1m])) / sum by (service) (rate(amazon_pilot_http_requests_total[1m])) * 100`
   - Legend: {{service}}
   - Alert line: 5%

3. **响应时间分布** (Graph Panel)
   - Queries:
     - P50: `histogram_quantile(0.5, sum by (le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m])))`
     - P90: `histogram_quantile(0.9, sum by (le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m])))`
     - P95: `histogram_quantile(0.95, sum by (le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m])))`
     - P99: `histogram_quantile(0.99, sum by (le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m])))`

#### Row 3: 服务详情
1. **服务 QPS 分布** (Pie Chart)
   - Query: `sum by (service) (rate(amazon_pilot_http_requests_total[5m]))`

2. **Top 10 API 端点** (Table Panel)
   - Query: `topk(10, sum by (path) (rate(amazon_pilot_http_requests_total[5m])))`
   - Columns: Path, QPS

3. **活跃连接数** (Graph Panel)
   - Query: `sum by (service) (amazon_pilot_active_connections)`

4. **JWT 认证成功率** (Gauge Panel)
   - Query: `sum(rate(amazon_pilot_jwt_auth_total{result="success"}[5m])) / sum(rate(amazon_pilot_jwt_auth_total[5m])) * 100`
   - Thresholds: >95 (绿), 90-95 (黄), <90 (红)

## 🚨 告警规则配置

### Prometheus Alert Rules

```yaml
groups:
  - name: amazon_pilot_gateway
    interval: 30s
    rules:
      # 高错误率告警
      - alert: HighErrorRate
        expr: |
          sum by (service) (rate(amazon_pilot_http_requests_total{status=~"5.."}[5m]))
          / sum by (service) (rate(amazon_pilot_http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
          component: gateway
        annotations:
          summary: "服务 {{ $labels.service }} 错误率过高"
          description: "服务 {{ $labels.service }} 的 5xx 错误率超过 5%，当前值: {{ $value | humanizePercentage }}"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      # 高延迟告警
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            sum by (service, le) (rate(amazon_pilot_http_request_duration_milliseconds_bucket[5m]))
          ) > 1000
        for: 5m
        labels:
          severity: warning
          component: gateway
        annotations:
          summary: "服务 {{ $labels.service }} 延迟过高"
          description: "服务 {{ $labels.service }} 的 P95 延迟超过 1 秒，当前值: {{ $value }}ms"

      # 服务不健康告警
      - alert: ServiceDown
        expr: amazon_pilot_service_health == 0
        for: 1m
        labels:
          severity: critical
          component: service
        annotations:
          summary: "服务 {{ $labels.service }} 不健康"
          description: "服务 {{ $labels.service }} 健康检查失败超过 1 分钟"

      # QPS 激增告警
      - alert: TrafficSpike
        expr: |
          sum(rate(amazon_pilot_http_requests_total[1m]))
          / sum(rate(amazon_pilot_http_requests_total[1m] offset 5m)) > 2
        for: 2m
        labels:
          severity: warning
          component: gateway
        annotations:
          summary: "流量激增"
          description: "当前 QPS 相比 5 分钟前增长超过 2 倍"

      # 限流触发告警
      - alert: RateLimitTriggered
        expr: |
          sum(rate(amazon_pilot_rate_limit_total{result="blocked"}[5m])) > 10
        for: 5m
        labels:
          severity: warning
          component: gateway
        annotations:
          summary: "限流频繁触发"
          description: "过去 5 分钟限流阻塞请求数超过 10 个/秒"

      # JWT 认证失败率高
      - alert: HighAuthFailureRate
        expr: |
          sum(rate(amazon_pilot_jwt_auth_total{result="failure"}[5m]))
          / sum(rate(amazon_pilot_jwt_auth_total[5m])) > 0.1
        for: 5m
        labels:
          severity: warning
          component: auth
        annotations:
          summary: "JWT 认证失败率过高"
          description: "JWT 认证失败率超过 10%，当前值: {{ $value | humanizePercentage }}"
```

## 🎯 SLI/SLO 定义

### 服务级别指标 (SLI)

1. **可用性 SLI**
   ```promql
   sum(rate(amazon_pilot_http_requests_total{status!~"5.."}[5m]))
   / sum(rate(amazon_pilot_http_requests_total[5m]))
   ```

2. **延迟 SLI**
   ```promql
   sum(rate(amazon_pilot_http_request_duration_milliseconds_bucket{le="500"}[5m]))
   / sum(rate(amazon_pilot_http_request_duration_milliseconds_count[5m]))
   ```

3. **错误率 SLI**
   ```promql
   1 - (sum(rate(amazon_pilot_http_requests_total{status=~"5.."}[5m]))
   / sum(rate(amazon_pilot_http_requests_total[5m])))
   ```

### 服务级别目标 (SLO)

| 指标 | 目标 | 测量窗口 |
|------|------|----------|
| 可用性 | 99.9% | 30 天滚动窗口 |
| P95 延迟 < 500ms | 95% | 7 天滚动窗口 |
| P99 延迟 < 1000ms | 99% | 7 天滚动窗口 |
| 错误率 | < 1% | 1 天滚动窗口 |

### Error Budget 计算

```promql
# 月度错误预算剩余（基于 99.9% SLO）
(1 - 0.999) - (1 - (
  sum(increase(amazon_pilot_http_requests_total{status!~"5.."}[30d]))
  / sum(increase(amazon_pilot_http_requests_total[30d]))
))
```

## 📊 性能基准

### 负载测试结果

| 场景 | QPS | P50 延迟 | P95 延迟 | P99 延迟 | 错误率 |
|------|-----|----------|----------|----------|--------|
| 正常负载 | 100 | 15ms | 45ms | 95ms | 0.01% |
| 高负载 | 500 | 25ms | 85ms | 180ms | 0.05% |
| 峰值负载 | 1000 | 45ms | 150ms | 450ms | 0.5% |
| 压力测试 | 2000 | 120ms | 850ms | 2500ms | 5.2% |

## 🔧 调优建议

### 监控优化
1. **指标采集间隔**: 15s (平衡精度与性能)
2. **数据保留策略**: 原始数据 15 天，5 分钟聚合 30 天，1 小时聚合 1 年
3. **告警评估间隔**: 30s
4. **告警去重**: 基于 alertname + service 标签

### 性能优化
1. **连接池配置**: MaxIdleConns=100, MaxOpenConns=200
2. **超时设置**: ReadTimeout=30s, WriteTimeout=30s
3. **限流配置**: 每服务 100 QPS，突发 200
4. **缓存策略**: 热点数据 5 分钟 TTL

## 📚 参考资料

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [RED Method](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

## 🚀 快速开始

### 访问监控系统

```bash
# Prometheus
http://localhost:9090

# Grafana (admin/admin123)
http://localhost:3001

# Gateway Metrics Endpoint
http://localhost:8080/metrics
```

### 导入 Dashboard

1. 登录 Grafana
2. 导航到 Dashboards → Import
3. 上传 `deployments/grafana/dashboards/gateway-red.json`
4. 选择 Prometheus 数据源
5. 点击 Import

### 验证指标

```bash
# 检查 Gateway 指标
curl http://localhost:8080/metrics | grep amazon_pilot

# 测试查询
curl -G http://localhost:9090/api/v1/query \
  --data-urlencode 'query=sum(rate(amazon_pilot_http_requests_total[1m]))'
```

---

**最后更新**: 2024-12-15
**版本**: v1.0
**维护者**: Amazon Pilot Team