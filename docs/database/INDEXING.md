# Database Indexing Strategy

## 索引策略和優化

### 核心查詢模式分析

#### 1. 用戶相關查詢
```sql
-- 用戶登錄查詢
CREATE INDEX idx_users_email_active ON users(email, is_active);

-- 用戶追蹤產品查詢
CREATE INDEX idx_tracked_products_user_active ON tracked_products(user_id, is_active);
```

#### 2. 產品搜索查詢
```sql
-- ASIN 查詢 (唯一索引)
CREATE UNIQUE INDEX idx_products_asin ON products(asin);

-- 類別搜索
CREATE INDEX idx_products_category_brand ON products(category, brand);

-- 全文搜索
CREATE INDEX idx_products_title_gin ON products USING gin(to_tsvector('english', title));
```

#### 3. 時間序列查詢優化

##### 價格歷史查詢
```sql
-- 產品價格趨勢查詢
CREATE INDEX idx_price_history_product_time ON product_price_history(product_id, recorded_at DESC);

-- 價格變化檢測
CREATE INDEX idx_price_history_price_change ON product_price_history(product_id, price, recorded_at);

-- 時間範圍查詢
CREATE INDEX idx_price_history_time_range ON product_price_history(recorded_at)
WHERE recorded_at >= '2024-01-01';
```

##### BSR排名歷史查詢
```sql
-- BSR趨勢查詢
CREATE INDEX idx_ranking_history_product_time ON product_ranking_history(product_id, recorded_at DESC);

-- BSR變化檢測
CREATE INDEX idx_ranking_history_bsr_change ON product_ranking_history(product_id, bsr_rank, recorded_at);

-- 類別排名查詢
CREATE INDEX idx_ranking_history_category_bsr ON product_ranking_history(category, bsr_rank);
```

### 複合索引設計

#### 1. 多條件查詢優化
```sql
-- 用戶追蹤產品狀態查詢
CREATE INDEX idx_tracked_user_status_updated ON tracked_products(user_id, is_active, last_checked_at);

-- 通知查詢優化
-- 通知表已移除
```

#### 2. 排序優化
```sql
-- 產品列表排序
CREATE INDEX idx_products_category_updated ON products(category, last_updated_at DESC);

-- 歷史數據排序
CREATE INDEX idx_history_product_date_desc ON product_price_history(product_id, recorded_at DESC);
```

### 部分索引 (節省空間)

#### 1. 活躍數據索引
```sql
-- 僅索引活躍追蹤產品
CREATE INDEX idx_tracked_products_active ON tracked_products(user_id, product_id, last_checked_at)
WHERE is_active = true;

-- 僅索引未讀通知
-- 通知表已移除
WHERE is_read = false;
```

#### 2. 近期數據索引
```sql
-- 僅索引最近30天的價格數據
CREATE INDEX idx_price_history_recent ON product_price_history(product_id, recorded_at DESC)
WHERE recorded_at >= NOW() - INTERVAL '30 days';
```

### 性能監控

#### 1. 索引使用統計
```sql
-- 檢查索引使用情況
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

#### 2. 未使用索引清理
```sql
-- 找出未使用的索引
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND indexname NOT LIKE '%_pkey';
```

### 查詢優化建議

#### 1. 慢查詢優化
```sql
-- 啟用慢查詢日誌
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1秒以上的查詢
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

#### 2. 執行計劃分析
```sql
-- 分析關鍵查詢的執行計劃
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM tracked_products tp
JOIN products p ON tp.product_id = p.id
WHERE tp.user_id = 'user-uuid'
AND tp.is_active = true;
```

---

**維護建議**: 定期檢查索引使用統計，清理未使用索引
**最後更新**: 2025-09-13
