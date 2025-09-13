# 异常检测架构设计 (优化版)

## 概述

本文档描述Amazon Pilot异常检测系统的混合架构设计，平衡了实时性、性能和可靠性需求。

## 架构选择决策

### 问题分析

**原始设计**: PostgreSQL触发器中执行复杂查询
- ✅ 数据强一致性
- ❌ 性能瓶颈 (触发器中JOIN查询)
- ❌ 扩展性限制

**纯应用层**: 定期轮询检测
- ✅ 高性能
- ✅ 灵活性强
- ❌ 数据丢失风险
- ❌ 延迟较高

**混合架构** (最终选择): 轻量级触发器 + 应用层处理 + 补偿机制
- ✅ 高性能 (触发器仅做简单计算)
- ✅ 实时性 (pg_notify零延迟)
- ✅ 数据保障 (审计表 + 补偿机制)
- ✅ 业务灵活性 (应用层智能处理)

## 技术架构

### 数据流设计

```
📊 产品数据更新 (INSERT INTO product_price_history)
    ↓
🔧 轻量级触发器 (仅计算变化率，无复杂查询)
    ↓ (并行)
📡 pg_notify('product_changes') ←→ 📋 change_events表 (审计)
    ↓                                     ↓
🎧 Go监听器 (实时处理)                    🔄 补偿任务 (5分钟检查)
    ↓                                     ↓
📨 Redis队列 (Asynq) ←←←←←←←←←←←←←←←←←←←←
    ↓
👷 Worker (邮件/推送)
```

### 核心组件

#### 1. 轻量级PostgreSQL触发器
```sql
-- 只做必要计算，避免复杂查询
CREATE OR REPLACE FUNCTION notify_price_change_hybrid()
RETURNS TRIGGER AS $$
DECLARE
    change_percentage DECIMAL(10,2);
    prev_price DECIMAL(15,2);
BEGIN
    -- 简单查询：获取前一个价格
    SELECT price INTO prev_price 
    FROM product_price_history 
    WHERE product_id = NEW.product_id 
      AND recorded_at < NEW.recorded_at 
    ORDER BY recorded_at DESC 
    LIMIT 1;

    IF prev_price IS NOT NULL AND prev_price > 0 THEN
        change_percentage := ABS((NEW.price - prev_price) / prev_price * 100);
        
        IF change_percentage >= 10.0 THEN
            -- 实时通知 (轻量级)
            PERFORM pg_notify('product_changes', json_build_object(
                'product_id', NEW.product_id,
                'change_type', 'price',
                'change_percentage', change_percentage
            )::text);
            
            -- 审计记录 (数据保障)
            INSERT INTO change_events (...) VALUES (...);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### 2. 应用层智能处理器
```go
func (detector *HybridDetector) processChangeEvent(event ChangeEvent) {
    // 1. 查询完整用户和产品信息 (应用层灵活查询)
    productInfo := detector.getProductWithUserInfo(event.ProductID)
    
    // 2. 应用业务规则
    if detector.shouldNotify(productInfo, event) {
        // 3. 创建个性化通知
        notification := detector.buildNotification(productInfo, event)
        
        // 4. 智能去重检查
        if !detector.isDuplicateNotification(notification) {
            // 5. 入队高优先级任务
            detector.queueMgr.EnqueueNotification(...)
        }
    }
    
    // 6. 标记为已处理
    detector.markEventProcessed(event.ID)
}
```

#### 3. 补偿机制
```go
// 每5分钟检查未处理事件
func (detector *HybridDetector) compensationLoop() {
    ticker := time.NewTicker(5 * time.Minute)
    for range ticker.C {
        unprocessedEvents := detector.getUnprocessedEvents()
        for _, event := range unprocessedEvents {
            detector.processChangeEvent(event) // 重新处理
        }
    }
}
```

## 性能优化特性

### 1. 触发器性能优化
- **最小化查询**: 触发器只查询必要的前一条记录
- **早期退出**: 不满足阈值的变化直接返回
- **索引优化**: 针对触发器查询优化索引

### 2. 应用层智能处理
- **异步处理**: 触发器通知后立即返回，应用层异步处理
- **批量查询**: 应用层可以批量查询相关数据
- **智能缓存**: 用户信息、产品元数据等可以缓存

### 3. 可扩展性设计
- **水平扩展**: 多个监听器实例可以并行处理
- **负载均衡**: Redis队列天然支持负载均衡
- **分片策略**: 可按产品类别或用户分片

## 可靠性保障

### 1. 数据不丢失
- **审计表**: 所有变化都记录在change_events表中
- **补偿机制**: 定期检查未处理事件
- **重试机制**: Asynq内置的重试机制

### 2. 监控和告警
- **处理延迟监控**: 监控事件处理时间
- **积压告警**: 未处理事件数量告警
- **错误率监控**: 处理失败率监控

## 业务价值

### 1. 用户体验优化
- **个性化阈值**: 不同用户可设置不同的变化阈值
- **智能去重**: 避免短时间内重复通知
- **优先级管理**: 根据用户套餐调整通知优先级

### 2. 成本优化
- **API效率**: 减少不必要的外部API调用
- **资源利用**: 优化数据库和Redis使用
- **弹性扩展**: 根据负载自动扩展

## 部署建议

### 生产环境配置
```yaml
# 高性能配置
PostgreSQL:
  max_connections: 200
  shared_buffers: 256MB
  effective_cache_size: 1GB
  
Redis:
  maxmemory: 512MB
  maxmemory-policy: allkeys-lru
  
Asynq:
  concurrency: 20
  queues:
    critical: 10  # 异常检测
    default: 8    # 常规通知
    low: 2        # 清理任务
```

## 总结

混合架构在保证数据可靠性的同时，显著提升了系统性能和扩展性。通过将复杂逻辑从数据库触发器移至应用层，我们获得了更好的可维护性和业务灵活性。