-- Migration: 003_create_analysis_tables.sql
-- Description: Create tables for competitor analysis and optimization features
-- Created: 2025-09-12

-- 1. Competitor analysis groups table
CREATE TABLE competitor_analysis_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    main_product_id UUID NOT NULL REFERENCES products(id),
    update_frequency VARCHAR(20) DEFAULT 'daily',
    analysis_metrics JSONB DEFAULT '["price", "bsr", "rating", "features"]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_analysis_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT competitor_groups_frequency_check CHECK (update_frequency IN ('hourly', 'daily', 'weekly'))
);

-- Indexes for competitor analysis groups
CREATE INDEX idx_competitor_groups_user_id ON competitor_analysis_groups(user_id);
CREATE INDEX idx_competitor_groups_main_product_id ON competitor_analysis_groups(main_product_id);
CREATE INDEX idx_competitor_groups_is_active ON competitor_analysis_groups(is_active);
CREATE INDEX idx_competitor_groups_last_analysis_at ON competitor_analysis_groups(last_analysis_at);

-- 2. Competitor products table (products in each analysis group)
CREATE TABLE competitor_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT competitor_products_group_product_unique UNIQUE (analysis_group_id, product_id)
);

-- Indexes for competitor products
CREATE INDEX idx_competitor_products_analysis_group_id ON competitor_products(analysis_group_id);
CREATE INDEX idx_competitor_products_product_id ON competitor_products(product_id);

-- 3. Competitor analysis results table
CREATE TABLE competitor_analysis_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    analysis_data JSONB NOT NULL,
    insights JSONB,
    recommendations JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    
    -- Constraints
    CONSTRAINT competitor_analysis_results_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

-- Indexes for competitor analysis results
CREATE INDEX idx_competitor_analysis_results_group_id ON competitor_analysis_results(analysis_group_id);
CREATE INDEX idx_competitor_analysis_results_status ON competitor_analysis_results(status);
CREATE INDEX idx_competitor_analysis_results_started_at ON competitor_analysis_results(started_at);

-- 4. Optimization analyses table
CREATE TABLE optimization_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    analysis_type VARCHAR(50) DEFAULT 'comprehensive',
    focus_areas JSONB DEFAULT '["title", "pricing", "description", "images", "keywords"]'::jsonb,
    status VARCHAR(20) DEFAULT 'pending',
    overall_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT optimization_analyses_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    CONSTRAINT optimization_analyses_score_check CHECK (overall_score >= 0 AND overall_score <= 100),
    CONSTRAINT optimization_analyses_type_check CHECK (analysis_type IN ('quick', 'comprehensive', 'keyword_focused', 'pricing_focused'))
);

-- Indexes for optimization analyses
CREATE INDEX idx_optimization_analyses_user_id ON optimization_analyses(user_id);
CREATE INDEX idx_optimization_analyses_product_id ON optimization_analyses(product_id);
CREATE INDEX idx_optimization_analyses_status ON optimization_analyses(status);
CREATE INDEX idx_optimization_analyses_created_at ON optimization_analyses(created_at);

-- 5. Optimization suggestions table
CREATE TABLE optimization_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID NOT NULL REFERENCES optimization_analyses(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    priority VARCHAR(10) NOT NULL,
    impact_score INTEGER NOT NULL,
    current_value TEXT,
    suggested_value TEXT,
    reasoning TEXT NOT NULL,
    estimated_impact JSONB,
    is_implemented BOOLEAN DEFAULT false,
    implemented_at TIMESTAMP WITH TIME ZONE,
    implementation_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT optimization_suggestions_priority_check CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT optimization_suggestions_impact_check CHECK (impact_score >= 0 AND impact_score <= 100),
    CONSTRAINT optimization_suggestions_category_check CHECK (category IN ('title', 'pricing', 'description', 'images', 'keywords', 'features', 'shipping'))
);

-- Indexes for optimization suggestions
CREATE INDEX idx_optimization_suggestions_analysis_id ON optimization_suggestions(analysis_id);
CREATE INDEX idx_optimization_suggestions_category ON optimization_suggestions(category);
CREATE INDEX idx_optimization_suggestions_priority ON optimization_suggestions(priority);
CREATE INDEX idx_optimization_suggestions_impact_score ON optimization_suggestions(impact_score);
CREATE INDEX idx_optimization_suggestions_is_implemented ON optimization_suggestions(is_implemented);

-- 6. Data sync jobs table (for background processing)
CREATE TABLE data_sync_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type VARCHAR(50) NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    job_data JSONB,
    result_data JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT data_sync_jobs_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    CONSTRAINT data_sync_jobs_priority_check CHECK (priority >= 0 AND priority <= 10),
    CONSTRAINT data_sync_jobs_retry_check CHECK (retry_count >= 0 AND retry_count <= max_retries),
    CONSTRAINT data_sync_jobs_type_check CHECK (job_type IN ('price_sync', 'ranking_sync', 'product_details_sync', 'competitor_analysis', 'optimization_analysis'))
);

-- Indexes for data sync jobs
CREATE INDEX idx_data_sync_jobs_status ON data_sync_jobs(status);
CREATE INDEX idx_data_sync_jobs_job_type ON data_sync_jobs(job_type);
CREATE INDEX idx_data_sync_jobs_priority ON data_sync_jobs(priority);
CREATE INDEX idx_data_sync_jobs_created_at ON data_sync_jobs(created_at);
CREATE INDEX idx_data_sync_jobs_next_retry_at ON data_sync_jobs(next_retry_at);
CREATE INDEX idx_data_sync_jobs_product_id ON data_sync_jobs(product_id);

-- Enable RLS for analysis tables
ALTER TABLE competitor_analysis_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitor_analysis_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE optimization_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE optimization_suggestions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for analysis tables
CREATE POLICY "Users can only access their own competitor groups" ON competitor_analysis_groups
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can only access competitor products from their groups" ON competitor_products
    FOR ALL USING (
        analysis_group_id IN (
            SELECT id FROM competitor_analysis_groups 
            WHERE user_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Users can only access their competitor analysis results" ON competitor_analysis_results
    FOR ALL USING (
        analysis_group_id IN (
            SELECT id FROM competitor_analysis_groups 
            WHERE user_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Users can only access their optimization analyses" ON optimization_analyses
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can only access their optimization suggestions" ON optimization_suggestions
    FOR ALL USING (
        analysis_id IN (
            SELECT id FROM optimization_analyses 
            WHERE user_id::text = auth.uid()::text
        )
    );

-- Add updated_at triggers for analysis tables
CREATE TRIGGER set_timestamp_competitor_groups BEFORE UPDATE ON competitor_analysis_groups 
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_optimization_analyses BEFORE UPDATE ON optimization_analyses 
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();