# Grafana 日志仪表板配置指南

## ⚠️ 重要说明

**数据源选择**：本文档中的所有查询都是 **LogQL** 语法，必须选择 **Loki** 作为数据源（Data Source），而不是 Prometheus。

- ✅ 正确：Data source = **Loki**
- ❌ 错误：Data source = Prometheus

## 日志字段说明

基于结构化日志格式，系统包含以下关键字段：

### 基础字段
- `time`: 日志时间戳
- `level`: 日志级别 (DEBUG, INFO, WARN, ERROR)
- `msg`: 日志消息
- `service`: 服务名称 (auth, product, competitor, optimization, gateway, worker)
- `component`: 组件类型 (business_logic, database, http_handler, cache, external_api)

### 业务字段
- `operation`: 操作类型 (例：get_profile, create_product, update_competitor)
- `resource_type`: 资源类型 (user, product, competitor, optimization)
- `resource_id`: 资源ID
- `result`: 操作结果 (success, failure, error)
- `user_id`: 用户ID
- `user_email`: 用户邮箱
- `user_plan`: 用户计划等级 (basic, pro, premium)

### 性能字段
- `duration_ms`: 操作耗时（毫秒）
- `query_time`: 数据库查询时间
- `cache_hit`: 缓存命中 (true/false)

### 错误字段
- `error`: 错误信息
- `error_code`: 错误码
- `stack_trace`: 堆栈跟踪

## 重要日志面板配置

### 1. 服务健康状态概览

#### 面板: Service Status Overview
**类型**: Stat Panel
**查询**:
```logql
sum by (service) (
  rate({job="docker"} | json | service != "" [5m])
)
```
**说明**: 显示每个服务的日志生成速率

#### 面板: Error Rate by Service
**类型**: Time Series
**查询**:
```logql
sum by (service) (
  rate({job="docker"} | json | level="ERROR" [5m])
)
```
**说明**: 各服务的错误率趋势

### 2. 业务操作监控

#### 面板: Top Operations by Volume
**类型**: Bar Gauge
**查询**:
```logql
topk(10,
  sum by (operation) (
    count_over_time({job="docker"} | json | operation != "" [1h])
  )
)
```
**说明**: 最频繁的业务操作

#### 面板: Operation Success Rate
**类型**: Gauge
**查询**:
```logql
sum(rate({job="docker"} | json | result="success" [5m])) /
sum(rate({job="docker"} | json | result=~"success|failure" [5m])) * 100
```
**说明**: 业务操作成功率

#### 面板: Failed Operations Table
**类型**: Logs Panel
**查询**:
```logql
{job="docker"} | json | result="failure" | line_format "{{.time}} [{{.service}}] {{.operation}}: {{.msg}} (user:{{.user_email}})"
```
**说明**: 失败操作详情表

### 3. 用户活动分析

#### 面板: Active Users
**类型**: Stat Panel
**查询**:
```logql
count(count by (user_id) (
  {job="docker"} | json | user_id != "" [5m]
))
```
**说明**: 5分钟内活跃用户数

#### 面板: User Activity by Plan
**类型**: Pie Chart
**查询**:
```logql
sum by (user_plan) (
  count_over_time({job="docker"} | json |user_plan" | json | user_plan != "" [1h])
)
```
**说明**: 不同计划用户的活跃度分布

#### 面板: Top Users by Activity
**类型**: Table
**查询**:
```logql
topk(10,
  sum by (user_email) (
    count_over_time({job="docker"} | json |user_email" | json | user_email != "" [1h])
  )
)
```
**说明**: 最活跃用户排行

### 4. API 性能监控

#### 面板: API Response Time (P50, P90, P99)
**类型**: Time Series
**查询**:
```logql
# P50
quantile_over_time(0.5,
  {job="docker"} | json |duration_ms" | json | unwrap duration_ms [5m]
) by (service)

# P90
quantile_over_time(0.9,
  {job="docker"} | json |duration_ms" | json | unwrap duration_ms [5m]
) by (service)

# P99
quantile_over_time(0.99,
  {job="docker"} | json |duration_ms" | json | unwrap duration_ms [5m]
) by (service)
```
**说明**: API响应时间分位数

#### 面板: Slow Queries
**类型**: Logs Panel
**查询**:
```logql
{job="docker"} | json |duration_ms" | json | duration_ms > 1000 | line_format "{{.time}} [{{.service}}] {{.operation}} took {{.duration_ms}}ms"
```
**说明**: 慢查询日志（>1秒）

### 5. 缓存性能

#### 面板: Cache Hit Rate
**类型**: Gauge
**查询**:
```logql
sum(rate({job="docker"} | json |cache_hit" | json | cache_hit="true" [5m])) /
sum(rate({job="docker"} | json |cache_hit" | json  [5m])) * 100
```
**说明**: 缓存命中率

#### 面板: Cache Operations by Type
**类型**: Time Series
**查询**:
```logql
sum by (operation) (
  rate({job="docker"} | json |component" | json | component="cache" [5m])
)
```
**说明**: 缓存操作类型分布

### 6. 错误和异常追踪

#### 面板: Error Distribution by Service
**类型**: Heatmap
**查询**:
```logql
sum by (service) (
  count_over_time({job="docker"} | json |level" | json | level="ERROR" [1m])
)
```
**说明**: 错误分布热力图

#### 面板: Error Details Table
**类型**: Table
**查询**:
```logql
{job="docker"} | json |level" | json | level="ERROR" | json | line_format "{{.service}} | {{.operation}} | {{.error}} | {{.user_email}}"
```
**说明**: 错误详情表格

#### 面板: Critical Errors Alert
**类型**: Alert List
**查询**:
```logql
count_over_time({job="docker"} | json |level" | json | level="ERROR" | msg=~".*critical.*|.*fatal.*|.*panic.*" [5m]) > 0
```
**说明**: 严重错误警报

### 7. 外部 API 调用监控

#### 面板: External API Calls
**类型**: Time Series
**查询**:
```logql
sum by (service) (
  rate({job="docker"} | json |component" | json | component="external_api" [5m])
)
```
**说明**: 外部API调用频率

#### 面板: Apify API Status
**类型**: Stat Panel
**查询**:
```logql
sum(rate({job="docker"} | json |Apify" | json | result="success" [5m])) /
sum(rate({job="docker"} | json |Apify" | json  [5m])) * 100
```
**说明**: Apify API成功率

### 8. 资源操作监控

#### 面板: Resource Operations by Type
**类型**: Bar Chart
**查询**:
```logql
sum by (resource_type, operation) (
  count_over_time({job="docker"} | json |resource_type" | json | resource_type != "" [1h])
)
```
**说明**: 按资源类型的操作统计

#### 面板: Product Operations Timeline
**类型**: Time Series
**查询**:
```logql
sum by (operation) (
  rate({job="docker"} | json |resource_type" | json | resource_type="product" [5m])
)
```
**说明**: 产品操作时间线

## 告警规则配置

### 1. 高错误率告警
```yaml
alert: HighErrorRate
expr: |
  sum by (service) (
    rate({job="docker"} | json |level" | json | level="ERROR" [5m])
  ) > 0.1
for: 5m
annotations:
  summary: "Service {{ $labels.service }} has high error rate"
  description: "Error rate is {{ $value }} errors/sec"
```

### 2. 响应时间告警
```yaml
alert: SlowResponse
expr: |
  quantile_over_time(0.99,
    {job="docker"} | json |duration_ms" | json | unwrap duration_ms [5m]
  ) > 5000
for: 5m
annotations:
  summary: "P99 response time exceeds 5 seconds"
```

### 3. 缓存命中率低告警
```yaml
alert: LowCacheHitRate
expr: |
  sum(rate({job="docker"} | json |cache_hit" | json | cache_hit="true" [5m])) /
  sum(rate({job="docker"} | json |cache_hit" | json [5m])) < 0.7
for: 10m
annotations:
  summary: "Cache hit rate below 70%"
```

## 仪表板导入步骤

1. 登录 Grafana (http://localhost:3001)
2. 进入 Dashboards > New > New Dashboard
3. 添加面板并配置上述查询
4. 设置合适的可视化选项和阈值
5. 保存仪表板

## 最佳实践

1. **使用变量**: 创建 `$service` 和 `$operation` 变量便于过滤
   ```logql
   label_values({job="docker"} | json |service" | json, service)
   ```

2. **时间范围**:
   - 实时监控: 5m-15m
   - 趋势分析: 1h-24h
   - 历史对比: 7d-30d

3. **性能优化**:
   - 使用 `|= "keyword"` 预过滤减少解析量
   - 合理使用 `__error__=""` 过滤解析错误
   - 避免在大时间范围使用 `unwrap`

4. **颜色方案**:
   - 绿色: 正常/成功 (>95%)
   - 黄色: 警告 (80-95%)
   - 红色: 错误/失败 (<80%)

5. **刷新频率**:
   - 实时面板: 5-10秒
   - 统计面板: 30-60秒
   - 历史面板: 5-10分钟

## 常用 LogQL 查询模板

### 按条件过滤
```logql
{job="docker"}
  |= "keyword"                      # 包含关键字
  | json                            # 解析JSON
  | service="auth"                  # 服务过滤
  | level=~"ERROR|WARN"             # 级别过滤
  | duration_ms > 1000              # 数值过滤
  | line_format "{{.time}} {{.msg}}" # 格式化输出
```

### 聚合统计
```logql
sum by (field) (                    # 按字段求和
  count_over_time({...} [5m])       # 时间窗口计数
)

avg_over_time({...} | unwrap field [5m])  # 平均值

topk(10, ...)                       # Top K
bottomk(10, ...)                    # Bottom K
```

### 比率计算
```logql
sum(rate({...} | field="value1" [5m])) /
sum(rate({...} [5m])) * 100
```

## 附录：字段映射参考

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| time | timestamp | 日志时间 | 2025-09-18T14:19:28 |
| level | string | 日志级别 | INFO, ERROR |
| service | string | 服务名 | auth, product |
| component | string | 组件类型 | business_logic |
| operation | string | 操作名称 | get_profile |
| resource_type | string | 资源类型 | user, product |
| resource_id | string | 资源ID | UUID |
| result | string | 结果状态 | success, failure |
| user_id | string | 用户ID | UUID |
| user_email | string | 用户邮箱 | test@example.com |
| user_plan | string | 用户计划 | basic, pro |
| duration_ms | number | 耗时(毫秒) | 125 |
| error | string | 错误信息 | connection timeout |
| error_code | string | 错误码 | E1001 |

---
**最后更新**: 2025-09-18
**版本**: v1.0