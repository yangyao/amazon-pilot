# Product Service Database Design

## 概述

產品追蹤服務的完整數據庫表設計，支援 questions.md 要求的所有追蹤項目。

## 核心表設計

### 1. 產品主表

#### products (產品主表)
```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asin VARCHAR(10) UNIQUE NOT NULL,
    title TEXT,
    brand VARCHAR(255),
    category VARCHAR(255),
    subcategory VARCHAR(255),
    description TEXT,
    bullet_points JSONB,
    images JSONB,
    dimensions JSONB,
    weight DECIMAL(10,2),
    manufacturer VARCHAR(255),
    model_number VARCHAR(100),
    upc VARCHAR(20),
    ean VARCHAR(20),
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX idx_products_asin ON products(asin);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_last_updated ON products(last_updated_at);
```

#### tracked_products (用戶追蹤產品表)
```sql
CREATE TABLE tracked_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alias VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    tracking_frequency VARCHAR(20) DEFAULT 'daily',
    price_change_threshold DECIMAL(5,2) DEFAULT 10,
    bsr_change_threshold DECIMAL(5,2) DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_checked_at TIMESTAMP WITH TIME ZONE,
    next_check_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT tracked_products_user_product_unique UNIQUE (user_id, product_id),
    CONSTRAINT tracked_products_frequency_check CHECK (tracking_frequency IN ('hourly', 'daily', 'weekly'))
);

CREATE INDEX idx_tracked_products_user_id ON tracked_products(user_id);
CREATE INDEX idx_tracked_products_product_id ON tracked_products(product_id);
CREATE INDEX idx_tracked_products_next_check ON tracked_products(next_check_at);
```

## 歷史數據表 (questions.md 要求)

### 2. 價格變化追蹤

#### product_price_history (價格歷史表)
```sql
CREATE TABLE product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    buy_box_price DECIMAL(10,2),
    is_on_sale BOOLEAN DEFAULT FALSE,
    discount_percentage DECIMAL(5,2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX idx_price_history_product_recorded ON product_price_history(product_id, recorded_at DESC);
CREATE INDEX idx_price_history_recorded ON product_price_history(recorded_at);
CREATE INDEX idx_price_history_price ON product_price_history(price);
```

### 3. BSR 趨勢追蹤

#### product_ranking_history (排名歷史表)
```sql
CREATE TABLE product_ranking_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category VARCHAR(255) NOT NULL,
    bsr_rank INTEGER,
    bsr_category VARCHAR(255),
    rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX idx_ranking_history_product_recorded ON product_ranking_history(product_id, recorded_at DESC);
CREATE INDEX idx_ranking_history_recorded ON product_ranking_history(recorded_at);
CREATE INDEX idx_ranking_history_bsr ON product_ranking_history(bsr_rank);
```

### 4. 評分與評論數變化追蹤

#### product_review_history (評論歷史表)
```sql
CREATE TABLE product_review_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    review_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2),
    five_star_count INTEGER DEFAULT 0,
    four_star_count INTEGER DEFAULT 0,
    three_star_count INTEGER DEFAULT 0,
    two_star_count INTEGER DEFAULT 0,
    one_star_count INTEGER DEFAULT 0,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',

    CONSTRAINT review_history_rating_valid CHECK (average_rating >= 0 AND average_rating <= 5),
    CONSTRAINT review_history_counts_positive CHECK (
        review_count >= 0 AND five_star_count >= 0 AND four_star_count >= 0 AND
        three_star_count >= 0 AND two_star_count >= 0 AND one_star_count >= 0
    )
);

CREATE INDEX idx_review_history_product_recorded ON product_review_history(product_id, recorded_at DESC);
CREATE INDEX idx_review_history_recorded ON product_review_history(recorded_at);
CREATE INDEX idx_review_history_rating ON product_review_history(average_rating);
```

### 5. Buy Box 價格追蹤

#### product_buybox_history (Buy Box歷史表)
```sql
CREATE TABLE product_buybox_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    winner_seller VARCHAR(255),
    winner_price DECIMAL(10,2),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    is_prime BOOLEAN DEFAULT FALSE,
    is_fba BOOLEAN DEFAULT FALSE,
    shipping_info TEXT,
    availability_text VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',

    CONSTRAINT buybox_price_positive CHECK (winner_price IS NULL OR winner_price >= 0),
    CONSTRAINT buybox_currency_valid CHECK (currency IN ('USD', 'EUR', 'GBP', 'CAD', 'JPY'))
);

CREATE INDEX idx_buybox_history_product_recorded ON product_buybox_history(product_id, recorded_at DESC);
CREATE INDEX idx_buybox_history_recorded ON product_buybox_history(recorded_at);
CREATE INDEX idx_buybox_history_seller ON product_buybox_history(winner_seller);
CREATE INDEX idx_buybox_history_price ON product_buybox_history(winner_price);
```

## 異常變化檢測 (questions.md 要求)

### 应用层异步检测架构

#### 检测流程
1. **数据插入** → Apify Worker保存新价格到 `product_price_history`
2. **队列入队** → 立即发送异常检测任务到Redis队列
3. **异步处理** → 专门的检测Worker处理检测逻辑
4. **用户通知** → 根据用户设置发送个性化通知

#### 检测表设计
```sql
-- 异常检测队列表
CREATE TABLE anomaly_detection_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    detection_type VARCHAR(50) NOT NULL, -- price_check, bsr_check, review_check
    trigger_data JSONB NOT NULL,         -- 检测所需数据
    priority INTEGER DEFAULT 5,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 用户个性化设置表
CREATE TABLE user_anomaly_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    price_change_threshold DECIMAL(5,2) DEFAULT 10.0,    -- 用户自定义阈值
    bsr_change_threshold DECIMAL(5,2) DEFAULT 30.0,
    notification_enabled BOOLEAN DEFAULT true,
    notification_methods JSONB DEFAULT '["email"]'::jsonb
);
```

### 变化阈值设定
- **價格變動 > 10%** → 基於用户个性化 `user_anomaly_settings.price_change_threshold`
- **BSR 變動 > 30%** → 基於用户个性化 `user_anomaly_settings.bsr_change_threshold`

### 性能优化
- **无触发器开销** → 数据插入性能最优
- **异步处理** → 检测逻辑不阻塞数据写入
- **Redis缓存** → 历史数据查询可缓存优化
- **批量检测** → Worker可批量处理多个检测任务

## 資料分區策略

歷史表使用時間分區提升查詢性能：

```sql
-- 價格歷史表分區
CREATE TABLE product_price_history_y2025m01 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

## 相關文件

- **API設計**: `api/openapi/product.api`
- **服務實現**: `internal/product/`
- **模型定義**: `internal/pkg/models/product.go`
- **遷移文件**: `deployments/migrations/003_add_history_tables.sql`

---

**狀態**: ✅ 完全實現，支援 questions.md 所有追蹤要求
**最後更新**: 2025-09-13