# Database Partitioning Strategy

## 時間序列數據分區

### TimescaleDB 擴展

#### 1. 啟用 TimescaleDB
```sql
-- 創建 TimescaleDB 擴展
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 將歷史表轉換為 hypertable
SELECT create_hypertable('product_price_history', 'recorded_at');
SELECT create_hypertable('product_ranking_history', 'recorded_at');
SELECT create_hypertable('product_review_history', 'recorded_at');
SELECT create_hypertable('product_buybox_history', 'recorded_at');
```

#### 2. 分區配置
```sql
-- 設置分區間隔為1個月
SELECT set_chunk_time_interval('product_price_history', INTERVAL '1 month');
SELECT set_chunk_time_interval('product_ranking_history', INTERVAL '1 month');
SELECT set_chunk_time_interval('product_review_history', INTERVAL '1 month');
SELECT set_chunk_time_interval('product_buybox_history', INTERVAL '1 month');
```

### 手動分區 (無 TimescaleDB)

#### 1. 月度分區創建
```sql
-- 創建 2025年度分區表
CREATE TABLE product_price_history_y2025m01 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE product_price_history_y2025m02 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- 繼續創建其他月份...
```

#### 2. 自動分區管理
```sql
-- 創建分區管理函數
CREATE OR REPLACE FUNCTION create_monthly_partition(
    table_name TEXT,
    start_date DATE
) RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    end_date := start_date + INTERVAL '1 month';
    partition_name := table_name || '_y' ||
                     EXTRACT(year FROM start_date) || 'm' ||
                     LPAD(EXTRACT(month FROM start_date)::text, 2, '0');

    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I
                   FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;
```

#### 3. 自動創建未來分區
```sql
-- 創建未來12個月的分區
DO $$
DECLARE
    i INTEGER;
    start_date DATE;
BEGIN
    FOR i IN 0..11 LOOP
        start_date := date_trunc('month', CURRENT_DATE) + (i || ' months')::interval;
        PERFORM create_monthly_partition('product_price_history', start_date);
        PERFORM create_monthly_partition('product_ranking_history', start_date);
        PERFORM create_monthly_partition('product_review_history', start_date);
        PERFORM create_monthly_partition('product_buybox_history', start_date);
    END LOOP;
END $$;
```

### 分區查詢優化

#### 1. 分區裁剪查詢
```sql
-- 查詢特定時間範圍 (自動分區裁剪)
SELECT product_id, price, recorded_at
FROM product_price_history
WHERE recorded_at >= '2025-09-01'
  AND recorded_at < '2025-10-01'
  AND product_id = 'target-uuid';

-- 查詢最近7天數據
SELECT *
FROM product_price_history
WHERE recorded_at >= NOW() - INTERVAL '7 days'
  AND product_id = 'target-uuid'
ORDER BY recorded_at DESC;
```

#### 2. 跨分區聚合查詢
```sql
-- 月度價格統計
SELECT
    date_trunc('month', recorded_at) as month,
    product_id,
    AVG(price) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM product_price_history
WHERE recorded_at >= '2025-01-01'
GROUP BY date_trunc('month', recorded_at), product_id;
```

### 分區維護

#### 1. 自動清理舊分區
```sql
-- 清理6個月前的分區
CREATE OR REPLACE FUNCTION cleanup_old_partitions(
    table_name TEXT,
    months_to_keep INTEGER DEFAULT 6
) RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    cutoff_date DATE;
BEGIN
    cutoff_date := date_trunc('month', CURRENT_DATE) - (months_to_keep || ' months')::interval;

    FOR partition_name IN
        SELECT schemaname||'.'||tablename
        FROM pg_tables
        WHERE tablename LIKE table_name || '_y%'
        AND tablename < table_name || '_y' || EXTRACT(year FROM cutoff_date) || 'm' || LPAD(EXTRACT(month FROM cutoff_date)::text, 2, '0')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || partition_name;
        RAISE NOTICE 'Dropped old partition: %', partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

#### 2. 分區統計信息
```sql
-- 查看分區大小
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE 'product_%_history_y%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 性能優化

#### 1. 分區約束
```sql
-- 添加分區約束提升查詢性能
ALTER TABLE product_price_history_y2025m01
ADD CONSTRAINT check_recorded_at_2025m01
CHECK (recorded_at >= '2025-01-01' AND recorded_at < '2025-02-01');
```

#### 2. 並行查詢
```sql
-- 啟用並行查詢
SET max_parallel_workers_per_gather = 4;
SET parallel_tuple_cost = 0.1;
SET parallel_setup_cost = 1000;
```

### 監控和維護

#### 1. 分區監控查詢
```sql
-- 監控分區數量和大小
SELECT
    COUNT(*) as partition_count,
    SUM(pg_total_relation_size(oid)) as total_size
FROM pg_class
WHERE relname LIKE 'product_%_history_y%';
```

#### 2. 定期維護腳本
```bash
#!/bin/bash
# 每月執行的分區維護腳本

# 創建下個月分區
psql -c "SELECT create_monthly_partition('product_price_history', date_trunc('month', CURRENT_DATE) + INTERVAL '2 months');"

# 清理舊分區
psql -c "SELECT cleanup_old_partitions('product_price_history', 6);"

# 更新統計信息
psql -c "ANALYZE product_price_history;"
```

---

**推薦**: 生產環境使用 TimescaleDB，開發環境可使用手動分區
**最後更新**: 2025-09-13