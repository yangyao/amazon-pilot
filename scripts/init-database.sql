-- Amazon Pilot 数据库初始化脚本
-- 基于 GORM 模型和现有迁移文件创建

-- ============================================
-- 1. 创建基础表 (基于 GORM 模型)
-- ============================================

-- 用户表
CREATE TABLE IF NOT EXISTS users (
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

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_plan ON users(plan_type);

-- 用户设置表
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_email BOOLEAN DEFAULT true,
    notification_push BOOLEAN DEFAULT false,
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    default_tracking_frequency VARCHAR(20) DEFAULT 'daily',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_settings_user ON user_settings(user_id);

-- 产品表
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asin VARCHAR(10) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    url TEXT,
    image_url TEXT,
    brand VARCHAR(255),
    category VARCHAR(255),
    current_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    is_available BOOLEAN DEFAULT true,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_asin ON products(asin);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- 追踪产品表
CREATE TABLE IF NOT EXISTS tracked_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    tracking_frequency VARCHAR(20) DEFAULT 'daily',
    alert_price_drop BOOLEAN DEFAULT true,
    alert_availability BOOLEAN DEFAULT true,
    alert_reviews BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_tracked_products_user ON tracked_products(user_id);
CREATE INDEX IF NOT EXISTS idx_tracked_products_product ON tracked_products(product_id);
CREATE INDEX IF NOT EXISTS idx_tracked_products_active ON tracked_products(is_active);

-- 产品价格历史表
CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    is_available BOOLEAN DEFAULT true,
    seller_name VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify'
);

CREATE INDEX IF NOT EXISTS idx_price_history_product_recorded ON product_price_history(product_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_price ON product_price_history(price);

-- ============================================
-- 2. 竞品分析表
-- ============================================

-- 分析组表
CREATE TABLE IF NOT EXISTS analysis_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analysis_groups_user ON analysis_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_analysis_groups_status ON analysis_groups(status);

-- 分析组产品关联表
CREATE TABLE IF NOT EXISTS analysis_group_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES analysis_groups(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    is_main_product BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(analysis_group_id, product_id)
);

-- 分析数据表
CREATE TABLE IF NOT EXISTS analysis_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES analysis_groups(id) ON DELETE CASCADE,
    data_type VARCHAR(50) NOT NULL,
    data_content JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analysis_data_group ON analysis_data(analysis_group_id);
CREATE INDEX IF NOT EXISTS idx_analysis_data_type ON analysis_data(data_type);

-- ============================================
-- 3. 历史追踪表 (从迁移文件)
-- ============================================

-- 评论历史表
CREATE TABLE IF NOT EXISTS product_review_history (
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

CREATE INDEX IF NOT EXISTS idx_review_history_product_recorded ON product_review_history(product_id, recorded_at DESC);

-- Buy Box历史表
CREATE TABLE IF NOT EXISTS product_buybox_history (
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

    CONSTRAINT buybox_price_positive CHECK (winner_price IS NULL OR winner_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_buybox_history_product_recorded ON product_buybox_history(product_id, recorded_at DESC);

-- ============================================
-- 4. 异常检测表
-- ============================================

-- 产品异常事件表
CREATE TABLE IF NOT EXISTS product_anomaly_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'medium',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT severity_valid CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);

CREATE INDEX IF NOT EXISTS idx_anomaly_events_product ON product_anomaly_events(product_id);
CREATE INDEX IF NOT EXISTS idx_anomaly_events_type ON product_anomaly_events(event_type);
CREATE INDEX IF NOT EXISTS idx_anomaly_events_severity ON product_anomaly_events(severity);
CREATE INDEX IF NOT EXISTS idx_anomaly_events_detected ON product_anomaly_events(detected_at DESC);

-- ============================================
-- 5. 通知系统表
-- ============================================

-- 通知表
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- ============================================
-- 6. 系统表
-- ============================================

-- 迁移跟踪表
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7. 初始数据
-- ============================================

-- 插入示例用户 (测试用)
INSERT INTO users (email, password_hash, company_name, plan_type)
VALUES
    ('demo@amazonpilot.com', '$2a$10$8k.4K5dMFQI5oZ.8yZBvr.AZz.7Lm2U4F8D9vY7KjH4P9oM1N2Q8S', 'Demo Company', 'basic'),
    ('admin@amazonpilot.com', '$2a$10$8k.4K5dMFQI5oZ.8yZBvr.AZz.7Lm2U4F8D9vY7KjH4P9oM1N2Q8S', 'Amazon Pilot', 'premium')
ON CONFLICT (email) DO NOTHING;

-- 为示例用户创建设置
INSERT INTO user_settings (user_id, notification_email, timezone, currency)
SELECT id, true, 'America/New_York', 'USD'
FROM users
WHERE email IN ('demo@amazonpilot.com', 'admin@amazonpilot.com')
ON CONFLICT (user_id) DO NOTHING;

-- 记录初始化完成
INSERT INTO schema_migrations (version)
VALUES
    ('001_initial_schema'),
    ('002_add_tracking_tables'),
    ('003_add_history_tables'),
    ('004_add_anomaly_detection'),
    ('005_add_competitor_analysis')
ON CONFLICT (version) DO NOTHING;

-- ============================================
-- 成功提示
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Amazon Pilot 数据库初始化完成!';
    RAISE NOTICE '📊 已创建所有必要的表和索引';
    RAISE NOTICE '👤 已添加示例用户数据 (demo@amazonpilot.com / admin@amazonpilot.com)';
    RAISE NOTICE '🔑 默认密码: amazon123 (请及时修改)';
END $$;