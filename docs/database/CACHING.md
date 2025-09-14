# Redis Caching Strategy

## Redis 快取策略設計

### 快取架構概覽

#### 用途分類
1. **數據快取** → 減少數據庫查詢
2. **任務隊列** → Asynq 異步任務處理
3. **會話管理** → JWT token 黑名單
4. **限流計數** → API rate limiting

### 快取類型和 TTL 設定

#### 1. 產品相關快取
```redis
# 產品基本信息 (24小時)
amazon_pilot:product:{asin} → TTL: 86400s
{
  "id": "uuid",
  "title": "product title",
  "brand": "brand name",
  "category": "electronics"
}

# 用戶追蹤產品列表 (1小時)
amazon_pilot:tracked:{user_id} → TTL: 3600s
["product_id_1", "product_id_2", ...]

# 最新價格數據 (30分鐘)
amazon_pilot:price:{product_id}:latest → TTL: 1800s
{
  "price": 29.99,
  "currency": "USD",
  "recorded_at": "2025-09-13T10:00:00Z"
}
```

#### 2. 搜索結果快取
```redis
# 搜索結果 (2小時)
amazon_pilot:search:{category}:{hash} → TTL: 7200s
{
  "products": [...],
  "total": 50,
  "cached_at": "timestamp"
}

# Apify 結果快取 (4小時)
amazon_pilot:apify:{actor_id}:{input_hash} → TTL: 14400s
```

#### 3. 用戶會話快取
```redis
# JWT 黑名單 (token 過期時間)
amazon_pilot:blacklist:{token_jti} → TTL: {token_exp}

# 用戶會話信息 (1天)
amazon_pilot:session:{user_id} → TTL: 86400s
{
  "email": "user@example.com",
  "plan": "premium",
  "last_activity": "timestamp"
}
```

### 快取失效策略

#### 1. 主動失效
```go
// 產品數據更新時清理相關快取
func InvalidateProductCache(productID, userID string) {
    redis.Del("amazon_pilot:product:" + asin)
    redis.Del("amazon_pilot:tracked:" + userID)
    redis.Del("amazon_pilot:price:" + productID + ":latest")
}
```

#### 2. 被動失效
- **TTL 自動過期** → 大部分快取使用 TTL 自動清理
- **LRU 策略** → Redis 內存不足時自動清理最少使用數據

### 快取命中率優化

#### 1. 預熱策略
```redis
# 預熱熱門產品數據
MGET amazon_pilot:product:B08N5WRWNW amazon_pilot:product:B085HN41M6

# 預熱用戶追蹤列表
GET amazon_pilot:tracked:{user_id}
```

#### 2. 批量操作
```redis
# 批量設置產品價格
MSET
  amazon_pilot:price:uuid1:latest '{"price":29.99}'
  amazon_pilot:price:uuid2:latest '{"price":39.99}'
```

### 任務隊列 (Asynq)

#### 1. 隊列配置
```go
// 隊列優先級設定
queues := map[string]int{
    "critical": 6,  // 緊急任務
    "default":  3,  // 一般任務
    "apify":    2,  // Apify 數據抓取
    "email":    1,  // 郵件發送
}
```

#### 2. 任務類型
```redis
# 產品數據刷新任務
asynq:task:refresh_product_data → payload: {"product_id": "uuid", "user_id": "uuid"}

# 競品分析任務
asynq:task:competitor_analysis → payload: {"group_id": "uuid"}

# 優化建議任務
asynq:task:generate_suggestions → payload: {"product_id": "uuid"}
```

### 性能監控

#### 1. 快取指標
```redis
# 查看快取統計
INFO stats

# 關鍵指標：
# - keyspace_hits / keyspace_misses (命中率)
# - used_memory_human (內存使用)
# - connected_clients (連接數)
```

#### 2. 慢查詢監控
```redis
# 啟用慢查詢日誌
CONFIG SET slowlog-log-slower-than 10000  # 10ms 以上
CONFIG SET slowlog-max-len 128

# 查看慢查詢
SLOWLOG GET 10
```

### 容災和備份

#### 1. 數據持久化
```redis
# Redis 配置
save 900 1      # 900秒內至少1個key變化時保存
save 300 10     # 300秒內至少10個key變化時保存
save 60 10000   # 60秒內至少10000個key變化時保存
```

#### 2. 主從複製
```redis
# 主從配置 (生產環境)
replicaof redis-master 6379
replica-read-only yes
```

---

**監控工具**: Redis CLI, Prometheus Redis Exporter
**最後更新**: 2025-09-13