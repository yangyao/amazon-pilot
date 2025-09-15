# Loki 日志系统使用指南

## 🚀 快速开始

### 访问方式

1. **Grafana Web界面**: http://localhost:3001 (admin/admin123)
2. **Loki API直接访问**: http://localhost:3100

## 📊 在Grafana中查询日志

### 方法1: 使用Explore页面（推荐）

1. 登录Grafana
2. 点击左侧菜单的 **Explore** 图标（指南针图标）
3. 在顶部选择 **Loki** 数据源
4. 在查询框中输入LogQL查询

> ⚠️ **注意**: 如果看到404错误提示，这是Grafana UI的已知问题，不影响实际查询功能。请忽略错误提示，直接输入查询语句。

### 方法2: 创建Dashboard面板

1. 创建新的Dashboard
2. 添加Panel
3. 选择Loki数据源
4. 配置查询

## 🔍 常用LogQL查询示例

### 基础查询

```logql
# 查看所有Docker日志
{job="docker"}

# 查看最近10条日志
{job="docker"} | limit 10

# 查看包含error的日志
{job="docker"} |= "error"

# 查看不包含info的日志
{job="docker"} != "info"

# 使用正则表达式匹配
{job="docker"} |~ "error|ERROR|Error"
```

### 过滤和解析

```logql
# 按stream类型过滤（stdout/stderr）
{job="docker", stream="stderr"}

# 解析JSON格式日志
{job="docker"} | json

# 解析后过滤特定字段
{job="docker"} | json | level="error"

# 提取特定容器的日志
{job="docker"} |~ "amazon-pilot-product"
```

### 统计和聚合

```logql
# 统计每秒日志数量
rate({job="docker"}[5m])

# 统计错误日志速率
rate({job="docker"} |= "error" [5m])

# 按stream分组统计
sum by (stream) (rate({job="docker"}[5m]))

# 计算过去5分钟的日志总数
count_over_time({job="docker"}[5m])
```

### 高级查询

```logql
# 查找响应时间超过1秒的请求
{job="docker"}
  | json
  | duration > 1000

# 提取并显示特定字段
{job="docker"}
  | json
  | line_format "{{.level}} - {{.msg}}"

# 查找特定时间范围的日志
{job="docker"}
  |= "error"
  | timestamp >= "2024-03-15T10:00:00Z"
  | timestamp <= "2024-03-15T11:00:00Z"
```

## 🛠️ 直接使用Loki API

### 查询日志

```bash
# 即时查询
curl -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="docker"}' \
  --data-urlencode 'limit=10'

# 范围查询
curl -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="docker"}' \
  --data-urlencode 'start=2024-03-15T10:00:00Z' \
  --data-urlencode 'end=2024-03-15T11:00:00Z'
```

### 查看标签

```bash
# 获取所有标签
curl "http://localhost:3100/loki/api/v1/labels"

# 获取标签值
curl "http://localhost:3100/loki/api/v1/label/job/values"
```

## 🔧 故障排查

### 常见问题

1. **Grafana显示404错误但查询正常工作**
   - 这是UI的已知问题，不影响实际功能
   - 直接输入查询语句即可

2. **没有日志数据**
   - 检查Promtail是否运行: `docker ps | grep promtail`
   - 查看Promtail日志: `docker logs amazon-pilot-promtail`

3. **查询超时**
   - 缩小时间范围
   - 添加更多过滤条件
   - 使用limit限制返回数量

### 检查服务状态

```bash
# 检查Loki状态
curl http://localhost:3100/ready

# 检查Promtail状态
docker logs amazon-pilot-promtail --tail 20

# 查看收集的日志统计
curl "http://localhost:3100/loki/api/v1/query" \
  -G --data-urlencode 'query=sum(rate({job="docker"}[5m]))'
```

## 📈 创建监控Dashboard

### 日志监控面板配置

1. **日志流面板**
   - Panel类型: Logs
   - 查询: `{job="docker"}`
   - 显示选项: 启用时间、唯一标签

2. **错误率面板**
   - Panel类型: Graph
   - 查询: `sum(rate({job="docker"} |= "error" [5m]))`
   - 单位: ops (operations per second)

3. **日志量统计**
   - Panel类型: Stat
   - 查询: `sum(count_over_time({job="docker"}[1h]))`
   - 单位: short

4. **按服务分组的日志量**
   - Panel类型: Bar chart
   - 查询: `sum by (filename) (count_over_time({job="docker"}[5m]))`

## 📚 参考资料

- [LogQL官方文档](https://grafana.com/docs/loki/latest/logql/)
- [Grafana Loki最佳实践](https://grafana.com/docs/loki/latest/best-practices/)
- [Promtail配置指南](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)