# 缓存设计文档

## 📋 概述

Amazon Pilot 采用 Redis 作为主要缓存存储，实现了基于产品维度的分层缓存策略。本文档详细说明了缓存架构设计、键命名规范、缓存策略以及最佳实践。

## 🏗️ 缓存架构

### 技术栈
- **Redis**: 主缓存存储，支持高并发读写
- **Go-Redis**: Redis Go 客户端库
- **统一Key管理**: 集中管理缓存键生成逻辑

### 架构设计原则
1. **按产品缓存**: 以产品为单位进行缓存，提高多用户场景下的缓存命中率
2. **分层缓存**: 不同类型数据采用不同的TTL策略
3. **统一Key管理**: 集中定义缓存键，避免硬编码
4. **缓存一致性**: 数据更新时及时清理相关缓存

## 🔑 缓存Key设计

### Key命名规范
```
amazon_pilot:{category}:{identifier}
```

### Key分类管理
缓存Key统一在 `internal/pkg/cache/keys.go` 中定义：

#### 产品相关缓存
```go
// 产品完整数据缓存（新策略）
ProductDataPrefix = "amazon_pilot:product_data:"

// 产品基本信息缓存
ProductCachePrefix = "amazon_pilot:product:"

// 产品价格缓存
ProductPricePrefix = "amazon_pilot:product_price:"
PriceCachePrefix = "amazon_pilot:price:"

// 产品排名缓存
ProductRankingPrefix = "amazon_pilot:product_ranking:"
RankingCachePrefix = "amazon_pilot:ranking:"
```

#### 用户相关缓存
```go
// 用户追踪列表缓存（已弃用，改为按产品缓存）
UserTrackedPrefix = "amazon_pilot:user_tracked:"
```

### Key构建函数
```go
// 产品数据缓存键
func ProductDataKey(productID string) string {
    return fmt.Sprintf("%s%s", ProductDataPrefix, productID)
}

// 价格缓存键
func PriceCacheKey(productID string) string {
    return fmt.Sprintf("%s%s", PriceCachePrefix, productID)
}

// 排名缓存键
func RankingCacheKey(productID string) string {
    return fmt.Sprintf("%s%s", RankingCachePrefix, productID)
}
```

## 📊 缓存策略

### 1. 产品数据缓存（主要策略）

**缓存对象**: 完整的产品追踪信息
**缓存Key**: `amazon_pilot:product_data:{productID}`
**TTL**: 30分钟
**触发场景**:
- GetTrackedProducts API调用
- 数据库查询后自动缓存

**数据结构**:
```json
{
  "id": "tracked_product_id",
  "product_id": "product_uuid",
  "asin": "B08N5WRWNW",
  "title": "Product Title",
  "brand": "Brand Name",
  "current_price": 29.99,
  "currency": "USD",
  "bsr": 12345,
  "rating": 4.5,
  "review_count": 1250,
  "buybox_price": 29.99,
  "status": "active",
  "alias": "My Product",
  "images": ["url1", "url2"],
  "description": "Product description",
  "bullet_points": ["point1", "point2"]
}
```

**优势**:
- 多用户追踪同一产品时共享缓存
- 减少数据库查询压力
- 提高API响应速度

### 2. 价格历史缓存

**缓存Key**: `amazon_pilot:price:{productID}`
**TTL**: 1小时
**用途**: 缓存最新价格信息

### 3. 排名历史缓存

**缓存Key**: `amazon_pilot:ranking:{productID}`
**TTL**: 1小时
**用途**: 缓存最新BSR排名信息

## 🔄 缓存失效策略

### 自动失效场景
1. **TTL到期**: 根据不同数据类型的TTL自动过期
2. **数据更新**: 产品数据更新时主动清理缓存
3. **追踪状态变更**: 添加/停止追踪时清理相关缓存

### 缓存清理实现
```go
// 产品数据更新后清理缓存
func invalidateProductCache(ctx context.Context, productID string) {
    // 清理产品数据缓存
    productDataKey := cache.ProductDataKey(productID)
    redisClient.Del(ctx, productDataKey)

    // 清理价格缓存
    priceCacheKey := cache.PriceCacheKey(productID)
    redisClient.Del(ctx, priceCacheKey)

    // 清理排名缓存
    rankingCacheKey := cache.RankingCacheKey(productID)
    redisClient.Del(ctx, rankingCacheKey)
}
```

### 涉及的服务和场景
| 服务/场景 | 清理操作 | 清理范围 |
|-----------|----------|----------|
| AddProductTracking | 产品添加到追踪 | 清理产品数据缓存 |
| StopProductTracking | 停止追踪产品 | 清理产品数据缓存 |
| RefreshProductData | 手动刷新数据 | 清理所有产品相关缓存 |
| ApifyWorker | 数据爬取完成 | 清理所有产品相关缓存 |

## 📈 缓存性能监控

### 关键指标
1. **缓存命中率**: 通过业务日志统计
2. **响应时间**: API响应时间对比（缓存命中vs未命中）
3. **内存使用**: Redis内存使用情况
4. **键空间**: 不同类型缓存键的分布

### 监控实现
```go
// 记录缓存命中日志
if cacheHit {
    l.Infof("Cache hit for product %s", productID)
} else {
    l.Infof("Cache miss for product %s, querying database", productID)
}

// 记录缓存操作日志
l.Infof("Cached product data for product %s, TTL: 30 minutes", productID)
```

## 🔧 缓存优化策略

### 1. 预加载策略
- 热门产品数据预加载
- 用户常访问的产品优先缓存

### 2. 批量操作优化
- Pipeline操作减少网络往返
- 批量清理相关缓存

### 3. 内存优化
- 合理设置TTL避免内存泄漏
- 定期清理过期键

## 🚨 最佳实践

### DO ✅
1. **使用统一的Key构建函数**，避免硬编码
2. **数据更新后及时清理缓存**，保证数据一致性
3. **合理设置TTL**，平衡性能和数据新鲜度
4. **记录缓存操作日志**，便于问题排查
5. **按业务逻辑分层缓存**，不同类型数据采用不同策略

### DON'T ❌
1. ~~直接在代码中拼接缓存键~~
2. ~~缓存用户级别的聚合数据~~（改为按产品缓存）
3. ~~忘记在数据更新时清理缓存~~
4. ~~设置过长的TTL导致数据不一致~~
5. ~~缓存大量低频访问数据~~

## 📝 版本历史

### v2.0 (2025-09-15) - 按产品缓存重构
- 从按用户缓存改为按产品缓存
- 统一缓存Key管理
- 优化多用户场景下的缓存命中率

### v1.0 (2025-09) - 初始版本
- 基于用户维度的缓存策略
- 基础的Redis缓存实现

## 🔗 相关文档
- [监控设计文档](./MONITORING.md)
- [API设计文档](./API_DESIGN.md)
- [数据库设计文档](./DATABASE_DESIGN.md)