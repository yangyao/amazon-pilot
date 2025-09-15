# 資料庫設計文件

## 概述

本文件描述 Amazon 賣家產品監控與優化工具的資料庫設計，使用 PostgreSQL 作為主要資料庫，Redis 作為快取層。

**实现状态**：
- ✅ **产品资料追踪系统** (questions.md 选项1) - 完整数据库设计
- ✅ **竞品分析引擎** (questions.md 选项2) - 完整数据库设计

**当前表总数**：16张表，支持完整的产品追踪、异常检测、竞品分析功能
**Migration版本**：010 (最新：修复analysis_data约束)

## 資料庫架構概覽

### 主要資料庫：PostgreSQL with TimescaleDB
- **版本**: PostgreSQL 15+ with TimescaleDB
- **主要用途**: 持久化資料儲存和時間序列數據
- **包含**: 用戶資料、產品資料、追蹤記錄、歷史數據、分析結果
- **ORM**: Gorm v2

### 快取層：Redis
- **版本**: Redis 7+
- **主要用途**: 高頻存取資料快取
- **TTL 策略**: 不同資料類型設定不同過期時間

## 資料表設計

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
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- 索引
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_plan_type_check CHECK (plan_type IN ('basic', 'premium', 'enterprise'))
);

-- 索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan_type ON users(plan_type);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### Gorm 模型定義

```go
// 用戶模型
type User struct {
    ID            string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
    Email         string    `gorm:"uniqueIndex;not null;size:255" json:"email"`
    PasswordHash  string    `gorm:"not null;size:255" json:"-"`
    CompanyName   *string   `gorm:"size:255" json:"company_name,omitempty"`
    PlanType      string    `gorm:"not null;default:basic;size:50" json:"plan_type"`
    IsActive      bool      `gorm:"default:true" json:"is_active"`
    EmailVerified bool      `gorm:"default:false" json:"email_verified"`
    CreatedAt     time.Time `gorm:"autoCreateTime" json:"created_at"`
    UpdatedAt     time.Time `gorm:"autoUpdateTime" json:"updated_at"`
    LastLoginAt   *time.Time `json:"last_login_at,omitempty"`
    
    // 關聯
    Settings      UserSettings `gorm:"foreignKey:UserID" json:"settings,omitempty"`
    Products      []Product    `gorm:"foreignKey:UserID" json:"products,omitempty"`
    CompetitorGroups []CompetitorGroup `gorm:"foreignKey:UserID" json:"competitor_groups,omitempty"`
}

// 表名
func (User) TableName() string {
    return "users"
}

// 驗證方法
func (u *User) Validate() error {
    if u.Email == "" {
        return errors.New("email is required")
    }
    if !isValidEmail(u.Email) {
        return errors.New("invalid email format")
    }
    if u.PlanType != "basic" && u.PlanType != "premium" && u.PlanType != "enterprise" {
        return errors.New("invalid plan type")
    }
    return nil
}

// 檢查密碼
func (u *User) CheckPassword(password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
    return err == nil
}

// 設置密碼
func (u *User) SetPassword(password string) error {
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return err
    }
    u.PasswordHash = string(hashedPassword)
    return nil
}
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
    
    -- 基本資訊
    manufacturer VARCHAR(255),
    model_number VARCHAR(100),
    upc VARCHAR(20),
    ean VARCHAR(20),
    
    -- 系統欄位
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    CONSTRAINT products_asin_length CHECK (LENGTH(asin) = 10)
);

-- 索引
CREATE UNIQUE INDEX idx_products_asin ON products(asin);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_title_gin ON products USING gin(to_tsvector('english', title));
CREATE INDEX idx_products_last_updated ON products(last_updated_at);
```

#### Gorm 模型定義

```go
// 產品模型
type Product struct {
    ID            string          `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
    ASIN          string          `gorm:"uniqueIndex;not null;size:10" json:"asin"`
    Title         *string         `gorm:"type:text" json:"title,omitempty"`
    Brand         *string         `gorm:"size:255" json:"brand,omitempty"`
    Category      *string         `gorm:"size:255" json:"category,omitempty"`
    Subcategory   *string         `gorm:"size:255" json:"subcategory,omitempty"`
    Description   *string         `gorm:"type:text" json:"description,omitempty"`
    BulletPoints  datatypes.JSON  `gorm:"type:jsonb" json:"bullet_points,omitempty"`
    Images        datatypes.JSON  `gorm:"type:jsonb" json:"images,omitempty"`
    Dimensions    datatypes.JSON  `gorm:"type:jsonb" json:"dimensions,omitempty"`
    Weight        *float64        `gorm:"type:decimal(10,2)" json:"weight,omitempty"`
    
    // 基本資訊
    Manufacturer  *string         `gorm:"size:255" json:"manufacturer,omitempty"`
    ModelNumber   *string         `gorm:"size:100" json:"model_number,omitempty"`
    UPC           *string         `gorm:"size:20" json:"upc,omitempty"`
    EAN           *string         `gorm:"size:20" json:"ean,omitempty"`
    
    // 系統欄位
    FirstSeenAt   time.Time       `gorm:"autoCreateTime" json:"first_seen_at"`
    LastUpdatedAt time.Time       `gorm:"autoUpdateTime" json:"last_updated_at"`
    DataSource    string          `gorm:"default:apify;size:50" json:"data_source"`
    
    // 關聯
    TrackedProducts []TrackedProduct `gorm:"foreignKey:ProductID" json:"tracked_products,omitempty"`
    ProductHistory  []ProductHistory  `gorm:"foreignKey:ProductID" json:"product_history,omitempty"`
}

// 表名
func (Product) TableName() string {
    return "products"
}

// 驗證方法
func (p *Product) Validate() error {
    if p.ASIN == "" {
        return errors.New("ASIN is required")
    }
    if len(p.ASIN) != 10 {
        return errors.New("ASIN must be exactly 10 characters")
    }
    return nil
}

// 更新產品資訊
func (p *Product) UpdateFromAPIData(data map[string]interface{}) error {
    if title, ok := data["title"].(string); ok {
        p.Title = &title
    }
    if brand, ok := data["brand"].(string); ok {
        p.Brand = &brand
    }
    if category, ok := data["category"].(string); ok {
        p.Category = &category
    }
    
    // 更新 JSON 欄位
    if bulletPoints, ok := data["bullet_points"].([]interface{}); ok {
        if jsonData, err := json.Marshal(bulletPoints); err == nil {
            p.BulletPoints = datatypes.JSON(jsonData)
        }
    }
    
    if images, ok := data["images"].([]interface{}); ok {
        if jsonData, err := json.Marshal(images); err == nil {
            p.Images = datatypes.JSON(jsonData)
        }
    }
    
    p.LastUpdatedAt = time.Now()
    return nil
}
```

#### tracked_products (用戶追蹤產品表)
```sql
CREATE TABLE tracked_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alias VARCHAR(255),
    
    -- 追蹤設定
    is_active BOOLEAN DEFAULT true,
    tracking_frequency VARCHAR(20) DEFAULT 'daily',
    price_change_threshold DECIMAL(5,2) DEFAULT 10.0,
    bsr_change_threshold DECIMAL(5,2) DEFAULT 30.0,
    
    -- 時間戳記
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_checked_at TIMESTAMP WITH TIME ZONE,
    next_check_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT tracked_products_user_product_unique UNIQUE (user_id, product_id),
    CONSTRAINT tracked_products_frequency_check CHECK (tracking_frequency IN ('hourly', 'daily', 'weekly')),
    CONSTRAINT tracked_products_price_threshold_check CHECK (price_change_threshold >= 0),
    CONSTRAINT tracked_products_bsr_threshold_check CHECK (bsr_change_threshold >= 0)
);

-- 索引
CREATE INDEX idx_tracked_products_user_id ON tracked_products(user_id);
CREATE INDEX idx_tracked_products_product_id ON tracked_products(product_id);
CREATE INDEX idx_tracked_products_next_check ON tracked_products(next_check_at) WHERE is_active = true;
CREATE INDEX idx_tracked_products_active ON tracked_products(is_active, user_id);
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
    is_on_sale BOOLEAN DEFAULT false,
    discount_percentage DECIMAL(5,2),
    
    -- 時間戳記
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    CONSTRAINT price_history_price_positive CHECK (price > 0),
    CONSTRAINT price_history_currency_length CHECK (LENGTH(currency) = 3)
) PARTITION BY RANGE (recorded_at);

-- 按月分區
CREATE TABLE product_price_history_y2024m01 PARTITION OF product_price_history
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE product_price_history_y2024m02 PARTITION OF product_price_history
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- 繼續建立其他月份的分區...

-- 索引
CREATE INDEX idx_price_history_product_recorded ON product_price_history(product_id, recorded_at DESC);
CREATE INDEX idx_price_history_recorded ON product_price_history(recorded_at);
```

#### product_ranking_history (排名歷史表)
```sql
CREATE TABLE product_ranking_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category VARCHAR(255) NOT NULL,
    bsr_rank INTEGER,
    bsr_category VARCHAR(255),
    
    -- 評分資訊
    rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    
    -- 時間戳記
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    CONSTRAINT ranking_history_bsr_positive CHECK (bsr_rank > 0),
    CONSTRAINT ranking_history_rating_range CHECK (rating >= 0 AND rating <= 5),
    CONSTRAINT ranking_history_review_count_positive CHECK (review_count >= 0)
) PARTITION BY RANGE (recorded_at);

-- 按月分區（同 price_history）
CREATE TABLE product_ranking_history_y2024m01 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- 索引
CREATE INDEX idx_ranking_history_product_recorded ON product_ranking_history(product_id, recorded_at DESC);
CREATE INDEX idx_ranking_history_category_bsr ON product_ranking_history(category, bsr_rank);
```

### 4. 競品分析相關表

#### competitor_analysis_groups (競品分析群組表)
实现 questions.md 选项2：竞品分析引擎的核心表。

**设计特点：**
- 分析组名称使用主产品名称
- 固定每日更新频率（不可用户配置）
- 支持多维度分析：价格、BSR、评分、产品特色
- 从已追踪产品中选择主产品和竞品

```sql
CREATE TABLE competitor_analysis_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL, -- 分析组名字就是主产品的名字
    description TEXT,
    main_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- 引用主产品

    -- 分析設定（固定daily，不可配置）
    analysis_metrics JSONB DEFAULT '["price", "bsr", "rating", "features"]',
    is_active BOOLEAN DEFAULT true,

    -- 時間戳記
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_analysis_at TIMESTAMP WITH TIME ZONE,
    next_analysis_at TIMESTAMP WITH TIME ZONE -- 自动调度用
);

-- 索引策略
CREATE INDEX idx_competitor_groups_user_id ON competitor_analysis_groups(user_id);
CREATE INDEX idx_competitor_groups_main_product ON competitor_analysis_groups(main_product_id);
CREATE INDEX idx_competitor_groups_active ON competitor_analysis_groups(is_active, user_id);
CREATE INDEX idx_competitor_groups_next_analysis ON competitor_analysis_groups(next_analysis_at) WHERE is_active = true;
```

#### competitor_products (競品產品表)
存储每个分析组中的竞品产品关联关系（3-5个竞品）。

**工作流程：**
1. 用户从已追踪产品中选择竞品
2. 创建分析组时同时创建竞品关联记录
3. 利用现有Apify爬虫数据进行比较分析

```sql
CREATE TABLE competitor_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- 引用已有产品
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 业务约束
    CONSTRAINT competitor_products_group_product_unique UNIQUE (analysis_group_id, product_id)
);

-- 索引策略
CREATE INDEX idx_competitor_products_group_id ON competitor_products(analysis_group_id);
CREATE INDEX idx_competitor_products_product_id ON competitor_products(product_id);
CREATE INDEX idx_competitor_products_added ON competitor_products(added_at DESC);
```

#### competitor_analysis_results (競品分析結果表)
存储LLM生成的竞争定位报告和分析结果。

**分析维度：**
- 主产品 vs 各竞品的价格差异
- BSR排名差距分析
- 评分优劣势对比
- 产品特色对比（从bullet points提取）

**数据结构：**
- `analysis_data`: 原始比较数据
- `insights`: LLM生成的洞察分析
- `recommendations`: 优化建议和策略

```sql
CREATE TABLE competitor_analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,

    -- 分析結果（允许NULL，在LLM处理完成前为空）
    analysis_data JSONB,          -- 原始比较数据：价格、BSR、评分等（LLM处理完成后填入）
    insights JSONB,               -- LLM生成的竞争洞察
    recommendations JSONB,        -- LLM生成的优化建议

    -- 系統欄位
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,

    CONSTRAINT analysis_results_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

-- 索引策略
CREATE INDEX idx_analysis_results_group_id ON competitor_analysis_results(analysis_group_id);
CREATE INDEX idx_analysis_results_status ON competitor_analysis_results(status);
CREATE INDEX idx_analysis_results_completed ON competitor_analysis_results(completed_at DESC);
CREATE INDEX idx_analysis_results_pending ON competitor_analysis_results(status, started_at) WHERE status = 'pending';
```

### 5. 優化建議相關表

#### optimization_analyses (優化分析表)
```sql
CREATE TABLE optimization_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- 分析設定
    analysis_type VARCHAR(50) DEFAULT 'comprehensive',
    focus_areas JSONB DEFAULT '["title", "pricing", "description", "images", "keywords"]',
    
    -- 狀態
    status VARCHAR(20) DEFAULT 'pending',
    overall_score INTEGER,
    
    -- 時間戳記
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT optimization_analyses_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    CONSTRAINT optimization_analyses_score_range CHECK (overall_score >= 0 AND overall_score <= 100)
);

-- 索引
CREATE INDEX idx_optimization_analyses_user_id ON optimization_analyses(user_id);
CREATE INDEX idx_optimization_analyses_product_id ON optimization_analyses(product_id);
CREATE INDEX idx_optimization_analyses_status ON optimization_analyses(status);
```

#### optimization_suggestions (優化建議表)
```sql
CREATE TABLE optimization_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID NOT NULL REFERENCES optimization_analyses(id) ON DELETE CASCADE,
    
    -- 建議內容
    category VARCHAR(50) NOT NULL,
    priority VARCHAR(10) NOT NULL,
    impact_score INTEGER NOT NULL,
    current_value TEXT,
    suggested_value TEXT,
    reasoning TEXT NOT NULL,
    estimated_impact JSONB,
    
    -- 實施追蹤
    is_implemented BOOLEAN DEFAULT false,
    implemented_at TIMESTAMP WITH TIME ZONE,
    implementation_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT suggestions_category_check CHECK (category IN ('title', 'pricing', 'description', 'images', 'keywords', 'features')),
    CONSTRAINT suggestions_priority_check CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT suggestions_impact_range CHECK (impact_score >= 0 AND impact_score <= 100)
);

-- 索引
CREATE INDEX idx_suggestions_analysis_id ON optimization_suggestions(analysis_id);
CREATE INDEX idx_suggestions_priority_impact ON optimization_suggestions(priority, impact_score DESC);
CREATE INDEX idx_suggestions_category ON optimization_suggestions(category);
```

### 6. 通知與警告（已移除表）
通知不再落庫；統一通過任務隊列與外部發送服務處理（郵件/推播/Webhook）。

### 7. 系統監控表

#### api_usage_logs (API 使用記錄表)
```sql
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- 請求資訊
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    
    -- 客戶端資訊
    user_agent TEXT,
    ip_address INET,
    
    -- 時間戳記
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- 按日分區
CREATE TABLE api_usage_logs_y2024m01d01 PARTITION OF api_usage_logs
    FOR VALUES FROM ('2024-01-01') TO ('2024-01-02');

-- 索引
CREATE INDEX idx_api_logs_user_created ON api_usage_logs(user_id, created_at DESC);
CREATE INDEX idx_api_logs_endpoint ON api_usage_logs(endpoint);
CREATE INDEX idx_api_logs_status ON api_usage_logs(status_code);
```

#### data_sync_jobs (資料同步工作表)
```sql
CREATE TABLE data_sync_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type VARCHAR(50) NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    
    -- 工作狀態
    status VARCHAR(20) DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    -- 工作資料
    job_data JSONB,
    result_data JSONB,
    error_message TEXT,
    
    -- 時間戳記
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT sync_jobs_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    CONSTRAINT sync_jobs_retry_positive CHECK (retry_count >= 0 AND max_retries >= 0)
);

-- 索引
CREATE INDEX idx_sync_jobs_status_priority ON data_sync_jobs(status, priority DESC, created_at);
CREATE INDEX idx_sync_jobs_product_id ON data_sync_jobs(product_id);
CREATE INDEX idx_sync_jobs_next_retry ON data_sync_jobs(next_retry_at) WHERE status = 'failed' AND retry_count < max_retries;
```

## 索引策略

### 1. 主鍵索引
所有表都使用 UUID 作為主鍵，自動建立唯一索引。

### 2. 外鍵索引
所有外鍵關係都建立相應索引以優化 JOIN 查詢。

### 3. 查詢優化索引

#### 複合索引
```sql
-- 用戶產品查詢優化
CREATE INDEX idx_tracked_products_user_active_updated 
ON tracked_products(user_id, is_active, updated_at DESC);

-- 時間序列查詢優化
CREATE INDEX idx_price_history_product_date_price 
ON product_price_history(product_id, recorded_at DESC, price);

-- 通知表已移除
```

#### 部分索引
```sql
-- 只索引活躍的追蹤產品
CREATE INDEX idx_tracked_products_active_next_check 
ON tracked_products(next_check_at) 
WHERE is_active = true;

-- 通知表已移除
```

#### 全文搜索索引
```sql
-- 產品標題搜索
CREATE INDEX idx_products_title_fulltext 
ON products USING gin(to_tsvector('english', title));

-- 產品描述搜索
CREATE INDEX idx_products_description_fulltext 
ON products USING gin(to_tsvector('english', description));
```

## 資料分區策略

### 1. 時間序列資料分區

#### 價格歷史分區（按月）
```sql
-- 自動建立分區函數
CREATE OR REPLACE FUNCTION create_monthly_partition(table_name text, start_date date)
RETURNS void AS $$
DECLARE
    partition_name text;
    end_date date;
BEGIN
    partition_name := table_name || '_y' || EXTRACT(year FROM start_date) || 'm' || LPAD(EXTRACT(month FROM start_date)::text, 2, '0');
    end_date := start_date + interval '1 month';
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;

-- 建立未來 12 個月的分區
DO $$
DECLARE
    i integer;
    start_date date;
BEGIN
    FOR i IN 0..11 LOOP
        start_date := date_trunc('month', CURRENT_DATE) + (i || ' months')::interval;
        PERFORM create_monthly_partition('product_price_history', start_date);
        PERFORM create_monthly_partition('product_ranking_history', start_date);
    END LOOP;
END $$;
```

### 2. 資料保留策略

#### 自動清理舊資料
```sql
-- 清理超過 2 年的歷史資料
CREATE OR REPLACE FUNCTION cleanup_old_partitions()
RETURNS void AS $$
DECLARE
    cutoff_date date := CURRENT_DATE - interval '2 years';
    partition_name text;
BEGIN
    -- 刪除舊的價格歷史分區
    FOR partition_name IN 
        SELECT schemaname||'.'||tablename 
        FROM pg_tables 
        WHERE tablename LIKE 'product_price_history_y%'
        AND tablename < 'product_price_history_y' || EXTRACT(year FROM cutoff_date) || 'm' || LPAD(EXTRACT(month FROM cutoff_date)::text, 2, '0')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## 資料一致性保證

### 1. 外鍵約束
所有關聯表都設定適當的外鍵約束並指定級聯刪除策略。

### 2. 檢查約束
重要欄位設定檢查約束確保資料有效性：
- 價格必須為正數
- 評分必須在 0-5 範圍內
- 狀態欄位限制為預定義值

### 3. 觸發器

#### 自動更新時間戳記
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 應用到所有需要的表
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### 資料變更通知觸發器（發送到 Redis 隊列）
```sql
-- 啟用 pg_notify 擴展
CREATE EXTENSION IF NOT EXISTS pg_notify;

-- 價格變更通知觸發器
CREATE OR REPLACE FUNCTION notify_price_change()
RETURNS TRIGGER AS $$
DECLARE
    price_change_percentage decimal;
    tracked_product_record record;
    notification_payload jsonb;
BEGIN
    -- 計算價格變動百分比
    IF OLD.price IS NOT NULL AND NEW.price != OLD.price THEN
        price_change_percentage := ABS((NEW.price - OLD.price) / OLD.price * 100);
        
        -- 檢查是否有用戶追蹤此產品並超過閾值
        FOR tracked_product_record IN 
            SELECT tp.*, u.id as user_id, u.email, u.plan_type
            FROM tracked_products tp 
            JOIN users u ON tp.user_id = u.id 
            WHERE tp.product_id = NEW.product_id 
            AND tp.is_active = true 
            AND price_change_percentage > tp.price_change_threshold
        LOOP
            -- 構建通知負載
            notification_payload := jsonb_build_object(
                'event_type', 'price_alert',
                'user_id', tracked_product_record.user_id,
                'user_email', tracked_product_record.email,
                'user_plan', tracked_product_record.plan_type,
                'product_id', NEW.product_id,
                'notification_data', jsonb_build_object(
                    'type', 'price_alert',
                    'title', 'Price Alert',
                    'message', 'Product price changed by ' || price_change_percentage::text || '%',
                    'severity', CASE WHEN price_change_percentage > 20 THEN 'critical' 
                                     WHEN price_change_percentage > 10 THEN 'warning' 
                                     ELSE 'info' END,
                    'product_id', NEW.product_id,
                    'data', jsonb_build_object(
                        'old_price', OLD.price,
                        'new_price', NEW.price,
                        'change_percentage', price_change_percentage,
                        'threshold', tracked_product_record.price_change_threshold
                    )
                ),
                'timestamp', NOW(),
                'priority', CASE WHEN price_change_percentage > 20 THEN 'high'
                                 WHEN price_change_percentage > 10 THEN 'medium'
                                 ELSE 'low' END
            );
            
            -- 發送到 Redis 隊列（通過 pg_notify）
            PERFORM pg_notify(
                'notification_queue',
                notification_payload::text
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- BSR 排名變更通知觸發器
CREATE OR REPLACE FUNCTION notify_bsr_change()
RETURNS TRIGGER AS $$
DECLARE
    bsr_change_percentage decimal;
    tracked_product_record record;
    notification_payload jsonb;
BEGIN
    -- 計算 BSR 變動百分比
    IF OLD.bsr_rank IS NOT NULL AND NEW.bsr_rank != OLD.bsr_rank THEN
        bsr_change_percentage := ABS((NEW.bsr_rank - OLD.bsr_rank) / OLD.bsr_rank::decimal * 100);
        
        -- 檢查是否有用戶追蹤此產品並超過閾值
        FOR tracked_product_record IN 
            SELECT tp.*, u.id as user_id, u.email, u.plan_type
            FROM tracked_products tp 
            JOIN users u ON tp.user_id = u.id 
            WHERE tp.product_id = NEW.product_id 
            AND tp.is_active = true 
            AND bsr_change_percentage > tp.bsr_change_threshold
        LOOP
            -- 構建通知負載
            notification_payload := jsonb_build_object(
                'event_type', 'bsr_alert',
                'user_id', tracked_product_record.user_id,
                'user_email', tracked_product_record.email,
                'user_plan', tracked_product_record.plan_type,
                'product_id', NEW.product_id,
                'notification_data', jsonb_build_object(
                    'type', 'bsr_change',
                    'title', 'BSR Ranking Alert',
                    'message', 'Product BSR ranking changed by ' || bsr_change_percentage::text || '%',
                    'severity', CASE WHEN bsr_change_percentage > 50 THEN 'critical' 
                                     WHEN bsr_change_percentage > 30 THEN 'warning' 
                                     ELSE 'info' END,
                    'product_id', NEW.product_id,
                    'data', jsonb_build_object(
                        'old_bsr', OLD.bsr_rank,
                        'new_bsr', NEW.bsr_rank,
                        'change_percentage', bsr_change_percentage,
                        'threshold', tracked_product_record.bsr_change_threshold
                    )
                ),
                'timestamp', NOW(),
                'priority', CASE WHEN bsr_change_percentage > 50 THEN 'high'
                                 WHEN bsr_change_percentage > 30 THEN 'medium'
                                 ELSE 'low' END
            );
            
            -- 發送到 Redis 隊列
            PERFORM pg_notify(
                'notification_queue',
                notification_payload::text
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建觸發器
CREATE TRIGGER price_change_notification
    AFTER UPDATE ON product_price_history
    FOR EACH ROW EXECUTE FUNCTION notify_price_change();

CREATE TRIGGER bsr_change_notification
    AFTER UPDATE ON product_ranking_history
    FOR EACH ROW EXECUTE FUNCTION notify_bsr_change();
```

#### Redis 隊列監聽器（Go 實現）
```go
package notification

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/go-redis/redis/v8"
    "github.com/jackc/pgx/v4/pgxpool"
    "github.com/zeromicro/go-zero/core/logx"
)

type NotificationQueueListener struct {
    dbPool      *pgxpool.Pool
    redisClient *redis.Client
    ctx         context.Context
    cancel      context.CancelFunc
}

type NotificationData struct {
    Type        string                 `json:"type"`
    ProductID   string                 `json:"product_id"`
    UserID      string                 `json:"user_id"`
    OldValue    interface{}            `json:"old_value,omitempty"`
    NewValue    interface{}            `json:"new_value,omitempty"`
    ChangeType  string                 `json:"change_type"`
    Timestamp   time.Time              `json:"timestamp"`
    Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

func NewNotificationQueueListener(dbURL, redisURL string) (*NotificationQueueListener, error) {
    // 初始化資料庫連接池
    dbPool, err := pgxpool.Connect(context.Background(), dbURL)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to database: %v", err)
    }

    // 初始化 Redis 連接
    redisClient := redis.NewClient(&redis.Options{
        Addr: redisURL,
    })

    // 測試 Redis 連接
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := redisClient.Ping(ctx).Err(); err != nil {
        return nil, fmt.Errorf("failed to connect to Redis: %v", err)
    }

    return &NotificationQueueListener{
        dbPool:      dbPool,
        redisClient: redisClient,
        ctx:         context.Background(),
    }, nil
}

func (nql *NotificationQueueListener) Start() error {
    logx.Info("Starting notification queue listener...")
    
    // 開始監聽 PostgreSQL 通知
    go nql.listenToNotifications()
    
    return nil
}

func (nql *NotificationQueueListener) listenToNotifications() {
    conn, err := nql.dbPool.Acquire(nql.ctx)
    if err != nil {
        logx.Errorf("Failed to acquire database connection: %v", err)
        return
    }
    defer conn.Release()

    // 監聽 notification_queue 頻道
    _, err = conn.Exec(nql.ctx, "LISTEN notification_queue")
    if err != nil {
        logx.Errorf("Failed to listen to notification_queue: %v", err)
        return
    }

    logx.Info("Listening for events on channel 'notification_queue'")

    for {
        select {
        case <-nql.ctx.Done():
            logx.Info("Notification listener stopped")
            return
        default:
            // 等待通知
            notification, err := conn.WaitForNotification(nql.ctx)
            if err != nil {
                if err == context.Canceled {
                    return
                }
                logx.Errorf("Error waiting for notification: %v", err)
                time.Sleep(1 * time.Second)
                continue
            }

            // 處理通知
            nql.handleNotification(notification.Payload)
        }
    }
}

func (nql *NotificationQueueListener) handleNotification(payload string) {
    // 解析通知負載
    var notificationData NotificationData
    if err := json.Unmarshal([]byte(payload), &notificationData); err != nil {
        logx.Errorf("Failed to parse notification payload: %v", err)
        return
    }

    // 設置時間戳
    notificationData.Timestamp = time.Now()

    // 添加到 Redis 隊列
    queueData, err := json.Marshal(notificationData)
    if err != nil {
        logx.Errorf("Failed to marshal notification data: %v", err)
        return
    }

    ctx, cancel := context.WithTimeout(nql.ctx, 5*time.Second)
    defer cancel()

    if err := nql.redisClient.LPush(ctx, "notification_queue", queueData).Err(); err != nil {
        logx.Errorf("Failed to push notification to Redis queue: %v", err)
        return
    }

    logx.Infof("Notification queued: %s", notificationData.Type)
}
            
            logger.info(f"處理事件: {notification_data['event_type']}")
            
        except Exception as e:
            logger.error(f"處理通知錯誤: {e}")
    
    async def send_to_redis_queue(self, notification_data: Dict[str, Any]):
        """發送通知到 Redis 隊列"""
        try:
            # 根據優先級選擇隊列（示例命名）
            priority = notification_data.get('priority', 'low')
            queue_name = f"events:{priority}"
            
            # 添加到 Redis 隊列
            await self.redis_client.lpush(queue_name, json.dumps(notification_data))
            
            # 設定過期時間（避免隊列積壓）
            await self.redis_client.expire(queue_name, 86400)  # 24小時
            
            logger.info(f"通知已發送到隊列: {queue_name}")
            
        except Exception as e:
            logger.error(f"發送到 Redis 隊列錯誤: {e}")

# 啟動監聽器
async def main():
    listener = NotificationQueueListener(
        redis_url="redis://redis:6379/2",
        database_url="postgresql://user:password@localhost/dbname"
    )
    await listener.start_listening()

if __name__ == "__main__":
    asyncio.run(main())
```

## Redis 快取策略

### 1. 快取資料類型與 TTL

#### 產品基本資訊快取
```redis
# Key Pattern: product:{asin}
# TTL: 24 hours
# Data: JSON string of product basic info
SET product:B08N5WRWNW '{"title":"Sony WH-1000XM4","price":299.99,...}' EX 86400
```

#### 產品歷史資料快取
```redis
# Key Pattern: product_history:{product_id}:{metric}:{period}
# TTL: 1 hour
# Data: JSON array of historical data points
SET product_history:uuid:price:30d '[{"date":"2024-01-01","value":299.99}...]' EX 3600
```

#### 用戶追蹤產品列表快取
```redis
# Key Pattern: user_tracked:{user_id}
# TTL: 30 minutes
# Data: JSON array of tracked product IDs
SET user_tracked:user-uuid '["prod-uuid-1","prod-uuid-2"]' EX 1800
```

#### API Rate Limiting
```redis
# Key Pattern: rate_limit:{user_id}:{window}
# TTL: Based on window size
# Data: Request count
INCR rate_limit:user-uuid:minute
EXPIRE rate_limit:user-uuid:minute 60
```

### 2. 快取失效策略

#### 寫入時失效
- 產品資料更新時清除相關快取
- 用戶設定變更時清除用戶相關快取

#### 定期更新
- 背景任務定期更新熱門產品快取
- 預熱下次查詢可能需要的資料

## 效能優化建議

### 1. 查詢優化

#### 分析慢查詢
```sql
-- 啟用慢查詢日誌
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET log_statement = 'all';

-- 查詢執行計劃
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM product_price_history 
WHERE product_id = 'uuid' 
AND recorded_at >= NOW() - INTERVAL '30 days';
```

#### 統計資訊更新
```sql
-- 自動更新統計資訊
ALTER SYSTEM SET autovacuum = on;
ALTER SYSTEM SET track_counts = on;

-- 手動更新重要表統計資訊
ANALYZE product_price_history;
ANALYZE tracked_products;
```

### 2. 連接池配置

建議使用 PgBouncer 進行連接池管理：

```ini
[databases]
amazon_monitor = host=localhost port=5432 dbname=amazon_monitor

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
reserve_pool_size = 5
```

### 3. 備份與恢復策略

#### 自動備份
```bash
# 每日完整備份
pg_dump -h localhost -U postgres -d amazon_monitor -f backup_$(date +%Y%m%d).sql

# 持續歸檔 WAL 日誌
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
```

#### Point-in-time 恢復
```bash
# 恢復到特定時間點
pg_basebackup -h localhost -D /backup/base -U postgres -v -P -W
# 配置 recovery.conf 並重啟
```

## 監控與維護

### 1. 資料庫監控指標

- 連接數使用率
- 慢查詢統計
- 磁碟空間使用
- 索引使用效率
- 快取命中率

### 2. 定期維護任務

```sql
-- 每週執行 VACUUM 和 REINDEX
VACUUM ANALYZE product_price_history;
REINDEX INDEX CONCURRENTLY idx_price_history_product_recorded;

-- 通知不落庫，無需清理通知記錄

-- 更新表統計資訊
ANALYZE;
```

## 安全性考量

### 1. 資料加密
- 啟用 PostgreSQL TLS 連接
- 敏感欄位使用應用層加密
- 定期輪換加密金鑰

### 2. 存取控制
```sql
-- 建立應用專用資料庫用戶
CREATE USER app_user WITH PASSWORD 'secure_password';

-- 授予最小必要權限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 禁止直接存取敏感表
REVOKE ALL ON users FROM app_user;
GRANT SELECT (id, email, plan_type) ON users TO app_user;
```

### 3. 審計日誌（使用 Supabase 內建功能）

#### Supabase 內建審計日誌配置
```sql
-- Supabase 自動提供審計日誌功能，無需額外配置
-- 所有資料表變更都會自動記錄在 auth.audit_log_entries 表中

-- 查看審計日誌的查詢範例
SELECT 
    id,
    instance_id,
    id as audit_id,
    payload->>'table_name' as table_name,
    payload->>'action' as action,
    payload->>'old_record' as old_record,
    payload->>'new_record' as new_record,
    created_at,
    payload->>'user_id' as user_id
FROM auth.audit_log_entries 
WHERE payload->>'table_name' IN ('products', 'tracked_products', 'users')
ORDER BY created_at DESC
LIMIT 100;

-- 創建審計日誌視圖以便查詢
CREATE OR REPLACE VIEW audit_log_view AS
SELECT 
    id,
    created_at,
    payload->>'table_name' as table_name,
    payload->>'action' as action,
    payload->>'old_record' as old_record,
    payload->>'new_record' as new_record,
    payload->>'user_id' as user_id,
    payload->>'ip_address' as ip_address,
    payload->>'user_agent' as user_agent
FROM auth.audit_log_entries
WHERE payload->>'table_name' IS NOT NULL;

-- 創建審計日誌查詢函數
CREATE OR REPLACE FUNCTION get_audit_log(
    table_name_filter TEXT DEFAULT NULL,
    action_filter TEXT DEFAULT NULL,
    user_id_filter TEXT DEFAULT NULL,
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL,
    limit_count INTEGER DEFAULT 100
)
RETURNS TABLE (
    audit_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    table_name TEXT,
    action TEXT,
    old_record JSONB,
    new_record JSONB,
    user_id TEXT,
    ip_address TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ale.id,
        ale.created_at,
        ale.payload->>'table_name'::TEXT,
        ale.payload->>'action'::TEXT,
        ale.payload->'old_record'::JSONB,
        ale.payload->'new_record'::JSONB,
        ale.payload->>'user_id'::TEXT,
        ale.payload->>'ip_address'::TEXT
    FROM auth.audit_log_entries ale
    WHERE 
        (table_name_filter IS NULL OR ale.payload->>'table_name' = table_name_filter)
        AND (action_filter IS NULL OR ale.payload->>'action' = action_filter)
        AND (user_id_filter IS NULL OR ale.payload->>'user_id' = user_id_filter)
        AND (start_date IS NULL OR ale.created_at >= start_date)
        AND (end_date IS NULL OR ale.created_at <= end_date)
    ORDER BY ale.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 使用範例
-- SELECT * FROM get_audit_log('products', 'UPDATE', NULL, '2024-01-01', '2024-01-31', 50);
```

#### Python 審計日誌查詢服務
```python
import asyncpg
from typing import Optional, List, Dict, Any
from datetime import datetime
import json

class AuditLogService:
    def __init__(self, database_url: str):
        self.database_url = database_url
    
    async def get_audit_logs(
        self,
        table_name: Optional[str] = None,
        action: Optional[str] = None,
        user_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """查詢審計日誌"""
        conn = await asyncpg.connect(self.database_url)
        
        try:
            query = """
            SELECT * FROM get_audit_log($1, $2, $3, $4, $5, $6)
            """
            
            rows = await conn.fetch(
                query, 
                table_name, 
                action, 
                user_id, 
                start_date, 
                end_date, 
                limit
            )
            
            return [dict(row) for row in rows]
            
        finally:
            await conn.close()
    
    async def get_user_activity(self, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
        """獲取用戶活動記錄"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        return await self.get_audit_logs(
            user_id=user_id,
            start_date=start_date,
            limit=1000
        )
    
    async def get_table_changes(
        self, 
        table_name: str, 
        days: int = 7
    ) -> List[Dict[str, Any]]:
        """獲取特定表的變更記錄"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        return await self.get_audit_logs(
            table_name=table_name,
            start_date=start_date,
            limit=500
        )
    
    async def get_security_events(self, days: int = 7) -> List[Dict[str, Any]]:
        """獲取安全相關事件"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        conn = await asyncpg.connect(self.database_url)
        
        try:
            query = """
            SELECT 
                id,
                created_at,
                payload->>'table_name' as table_name,
                payload->>'action' as action,
                payload->>'user_id' as user_id,
                payload->>'ip_address' as ip_address
            FROM auth.audit_log_entries 
            WHERE 
                created_at >= $1
                AND (
                    payload->>'table_name' = 'users'
                    OR payload->>'action' IN ('DELETE', 'DROP', 'ALTER')
                    OR payload->>'ip_address' IS NOT NULL
                )
            ORDER BY created_at DESC
            LIMIT 200
            """
            
            rows = await conn.fetch(query, start_date)
            return [dict(row) for row in rows]
            
        finally:
            await conn.close()

# 使用範例
async def main():
    audit_service = AuditLogService("postgresql://user:password@localhost/dbname")
    
    # 查詢產品表的變更記錄
    product_changes = await audit_service.get_table_changes("products", days=7)
    
    # 查詢特定用戶的活動
    user_activity = await audit_service.get_user_activity("user-uuid", days=30)
    
    # 查詢安全事件
    security_events = await audit_service.get_security_events(days=7)
    
    print(f"產品變更記錄: {len(product_changes)} 條")
    print(f"用戶活動記錄: {len(user_activity)} 條")
    print(f"安全事件記錄: {len(security_events)} 條")
```


### 補充：缺少的歷史表 (questions.md 要求)

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
```

## Questions.md 要求完整支援

✅ **追蹤項目**:
1. 價格變化 → product_price_history
2. BSR 趨勢 → product_ranking_history  
3. 評分與評論數變化 → product_review_history
4. Buy Box 價格 → product_buybox_history

✅ **異常變化通知**:
- 價格變動 > 10% → 支援檢測
- 小類別 BSR 變動 > 30% → 支援檢測
