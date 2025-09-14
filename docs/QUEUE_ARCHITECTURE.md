# Amazon Pilot 队列架构设计

## 队列架构概览

### 双模式设计

#### 🚀 实时消息驱动 (Pub/Sub模式)
**用途**: 异常检测、实时通知
**特点**: 数据更新时立即触发
**技术**: Redis + Asynq

#### ⏰ 定时任务调度 (Cron模式)
**用途**: 批量数据更新、清理、报告
**特点**: 按时间周期执行
**技术**: Cron + Redis队列

## 实时消息流程 (异常检测)

### 数据驱动的异常检测流程

```
1. 用户操作触发
   ├── 手动刷新按钮 → API调用
   └── 前端搜索添加 → API调用
                ↓
2. API发送任务到Redis
   └── refresh_product_data 任务
                ↓
3. Apify Worker处理
   ├── 获取历史数据 (1次查询)
   ├── 调用Apify API获取新数据
   ├── 保存到history表
   └── 立即检测变化
                ↓
4. 异常检测 (数据驱动)
   ├── 计算变化率
   ├── 如有异常 → 发送检测消息
   └── price_anomaly_detection 任务
                ↓
5. 异常处理Worker
   ├── 接收消息 (包含所有数据)
   ├── 获取用户阈值设置
   ├── 检查是否需要通知
   └── 发送通知给用户
```

### 消息类型设计

#### 主要任务类型
```go
// 数据刷新 (用户触发)
refresh_product_data → {
    "product_id": "uuid",
    "user_id": "uuid",
    "asin": "B08N5WRWNW"
}

// 价格异常检测 (数据驱动)
price_anomaly_detection → {
    "product_id": "uuid",
    "user_id": "uuid",
    "asin": "B08N5WRWNW",
    "old_price": 29.99,
    "new_price": 39.99,
    "change_rate": 33.4,
    "currency": "USD"
}

// BSR异常检测 (数据驱动)
bsr_anomaly_detection → {
    "product_id": "uuid",
    "user_id": "uuid",
    "old_bsr": 50,
    "new_bsr": 25,
    "change_rate": 50.0
}
```

## 定时任务流程 (Cron模式)

### 批量处理任务

#### 每日数据更新
```
⏰ 每天凌晨2点
       ↓
📊 查询所有活跃追踪产品
       ↓
🔄 批量发送 refresh_product_data 任务
       ↓
🤖 Apify Worker批量处理
       ↓
📈 自动触发异常检测 (如有变化)
```

#### 其他定时任务
```bash
# 每小时 - 紧急产品更新
"0 * * * *" → update_urgent_products

# 每天凌晨2点 - 批量数据更新
"0 2 * * *" → batch_update_all_products

# 每天凌晨3点 - 数据清理
"0 3 * * *" → cleanup_old_data

# 每周一 - 竞品分析
"0 8 * * 1" → competitor_analysis

# 每月1号 - 月度报告
"0 0 1 * *" → monthly_report
```

## 队列配置

### Redis队列分组
```go
queues := map[string]int{
    "critical": 6,  // 异常检测、紧急通知
    "default":  3,  // 一般数据刷新
    "apify":    2,  // Apify数据获取
    "cleanup":  1,  // 数据清理、报告
}
```

### 任务优先级
```go
// 优先级设计 (1-10)
price_anomaly_detection   → 9 (最高，用户关心)
bsr_anomaly_detection     → 8 (高，影响排名)
refresh_product_data      → 5 (中等，用户触发)
batch_update_products     → 3 (低，后台任务)
data_cleanup             → 1 (最低，维护任务)
```

## 性能优化

### 消息处理优化
1. **消息包含完整数据** → 避免Worker查询数据库
2. **批量处理** → 相同类型任务可批量处理
3. **失败重试** → 自动重试机制
4. **优雅降级** → 高负载时降低检测敏感度

### 队列监控
```prometheus
# 队列长度监控
asynq_queue_size{queue="critical"}
asynq_queue_size{queue="apify"}

# 处理时间监控
asynq_task_duration_seconds{task_type="price_anomaly_detection"}

# 失败率监控
asynq_task_failures_total{task_type="refresh_product_data"}
```

## Questions.md 要求支持

### ✅ 完全符合要求的架构

**实时异常检测:**
- ✅ **價格變動 > 10%** → 数据更新时立即检测
- ✅ **小類別 BSR 變動 > 30%** → 同样的实时架构

**批量数据更新:**
- ✅ **每日一次更新** → Cron触发批量Apify获取
- ✅ **用户触发更新** → 手动刷新按钮

**技术要求:**
- ✅ **Redis快取机制** → 队列 + 数据缓存
- ✅ **背景任务排程** → 实时消息 + 定时任务

---

**架构优势**: 数据驱动实时检测 + 定时批量更新，性能最优
**实现状态**: ✅ 已优化，移除定时异常检测
**最后更新**: 2025-09-13