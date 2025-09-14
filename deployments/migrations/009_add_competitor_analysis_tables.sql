-- Migration: Add competitor analysis tables
-- Purpose: Implement competitor analysis engine per questions.md Option 2
-- Date: 2025-09-14

-- Create competitor_analysis_groups table
CREATE TABLE IF NOT EXISTS competitor_analysis_groups (
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
    next_analysis_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for competitor_analysis_groups
CREATE INDEX IF NOT EXISTS idx_competitor_groups_user_id ON competitor_analysis_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_competitor_groups_main_product ON competitor_analysis_groups(main_product_id);
CREATE INDEX IF NOT EXISTS idx_competitor_groups_active ON competitor_analysis_groups(is_active, user_id);

-- Create competitor_products table
CREATE TABLE IF NOT EXISTS competitor_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT competitor_products_group_product_unique UNIQUE (analysis_group_id, product_id)
);

-- Create indexes for competitor_products
CREATE INDEX IF NOT EXISTS idx_competitor_products_group_id ON competitor_products(analysis_group_id);
CREATE INDEX IF NOT EXISTS idx_competitor_products_product_id ON competitor_products(product_id);

-- Create competitor_analysis_results table
CREATE TABLE IF NOT EXISTS competitor_analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,

    -- 分析結果
    analysis_data JSONB NOT NULL,
    insights JSONB,
    recommendations JSONB,

    -- 系統欄位
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,

    CONSTRAINT analysis_results_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

-- Create indexes for competitor_analysis_results
CREATE INDEX IF NOT EXISTS idx_analysis_results_group_id ON competitor_analysis_results(analysis_group_id);
CREATE INDEX IF NOT EXISTS idx_analysis_results_status ON competitor_analysis_results(status);
CREATE INDEX IF NOT EXISTS idx_analysis_results_completed ON competitor_analysis_results(completed_at DESC);

-- Add table comments
COMMENT ON TABLE competitor_analysis_groups IS 'Competitor analysis groups - main product vs 3-5 competitors';
COMMENT ON TABLE competitor_products IS 'Competitor products in each analysis group';
COMMENT ON TABLE competitor_analysis_results IS 'LLM-generated competitor analysis reports';

-- Add column comments
COMMENT ON COLUMN competitor_analysis_groups.name IS 'Analysis group name (same as main product name)';
COMMENT ON COLUMN competitor_analysis_groups.main_product_id IS 'Main product being analyzed';
COMMENT ON COLUMN competitor_analysis_groups.analysis_metrics IS 'Analysis dimensions: price, bsr, rating, features';
COMMENT ON COLUMN competitor_analysis_results.analysis_data IS 'Raw comparison data between main product and competitors';
COMMENT ON COLUMN competitor_analysis_results.insights IS 'LLM-generated insights and observations';
COMMENT ON COLUMN competitor_analysis_results.recommendations IS 'LLM-generated optimization recommendations';