# Amazon Pilot 資料庫設計文件

## 概述

Amazon 賣家產品監控與優化工具的資料庫設計，使用 PostgreSQL with TimescaleDB 作為主要資料庫，Redis 作為快取層。

## 資料庫架構概覽

### 主要資料庫：PostgreSQL with TimescaleDB
- **版本**: PostgreSQL 15+ with TimescaleDB
- **主要用途**: 持久化資料儲存和時間序列數據
- **包含**: 用戶資料、產品資料、追蹤記錄、歷史數據、分析結果

### 快取層：Redis
- **版本**: Redis 7+
- **主要用途**: 高頻存取資料快取、任務隊列
- **TTL 策略**: 不同資料類型設定不同過期時間

## 核心資料表設計

### 1. 用戶管理相關表

#### users (用戶表)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan_type ON users(plan_type);
CREATE INDEX idx_users_created_at ON users(created_at);
```

### 2. 產品相關表

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

### 3. 產品歷史資料表（時間序列）

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
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX idx_review_history_product_recorded ON product_review_history(product_id, recorded_at DESC);
CREATE INDEX idx_review_history_recorded ON product_review_history(recorded_at);
CREATE INDEX idx_review_history_rating ON product_review_history(average_rating);
```

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
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX idx_buybox_history_product_recorded ON product_buybox_history(product_id, recorded_at DESC);
CREATE INDEX idx_buybox_history_recorded ON product_buybox_history(recorded_at);
CREATE INDEX idx_buybox_history_seller ON product_buybox_history(winner_seller);
CREATE INDEX idx_buybox_history_price ON product_buybox_history(winner_price);
```

## 追蹤項目映射 (questions.md 要求)

根據 questions.md 第66-67行要求的追蹤項目：

1. **價格變化** → `product_price_history` 表
2. **BSR 趨勢** → `product_ranking_history` 表
3. **評分與評論數變化** → `product_review_history` 表
4. **Buy Box 價格** → `product_buybox_history` 表

## 異常變化通知 (questions.md 要求)

系統支援異常變化通知：
- **價格變動 > 10%** → 基於 `product_price_history` 表數據比較
- **小類別 BSR 變動 > 30%** → 基於 `product_ranking_history` 表數據比較

## 資料分區策略

對於高頻寫入的歷史表，使用時間分區：

```sql
-- 價格歷史表按月分區
CREATE TABLE product_price_history_y2025m01 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- 其他歷史表同樣按月分區
```

## 索引策略

### 查詢優化索引
```sql
-- 用戶產品查詢
CREATE INDEX idx_tracked_products_user_active ON tracked_products(user_id, is_active);

-- 時間序列查詢
CREATE INDEX idx_price_history_product_date ON product_price_history(product_id, recorded_at DESC);

-- 變化檢測查詢
CREATE INDEX idx_price_history_price_change ON product_price_history(product_id, price, recorded_at);
```

## Redis 快取策略

### 快取類型和 TTL 設定

1. **產品基本信息** → TTL: 24小時
2. **追蹤產品列表** → TTL: 1小時
3. **最新價格數據** → TTL: 30分鐘
4. **搜索結果** → TTL: 2小時

### 快取鍵命名規範

```
amazon_pilot:product:{asin}              # 產品基本信息
amazon_pilot:tracked:{user_id}           # 用戶追蹤列表
amazon_pilot:price:{product_id}:latest   # 最新價格
amazon_pilot:search:{category}:{hash}    # 搜索結果
```

## 數據庫維護

### 定期維護任務

1. **每日** - 清理過期快取
2. **每週** - VACUUM ANALYZE 歷史表
3. **每月** - 創建新的時間分區
4. **每季** - 歸檔舊數據

### 監控指標

- 表大小增長率
- 查詢性能指標
- 索引使用統計
- 分區表性能

---

**文件版本**: v3.0 - 移除Go代碼，專注數據庫設計
**最後更新**: 2025-09-13
**符合要求**: questions.md 完整追蹤項目支援