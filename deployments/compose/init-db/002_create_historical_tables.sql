-- Migration: 002_create_historical_tables.sql
-- Description: Create time-partitioned tables for historical data tracking
-- Created: 2025-09-12

-- 1. Product price history table (partitioned by month)
CREATE TABLE product_price_history (
    id UUID DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    buy_box_price DECIMAL(10,2),
    is_on_sale BOOLEAN DEFAULT false,
    discount_percentage DECIMAL(5,2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Create initial partitions for price history
CREATE TABLE product_price_history_2025_01 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE product_price_history_2025_02 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE product_price_history_2025_03 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE product_price_history_2025_04 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE product_price_history_2025_05 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE product_price_history_2025_06 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE product_price_history_2025_07 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE product_price_history_2025_08 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE product_price_history_2025_09 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE product_price_history_2025_10 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE product_price_history_2025_11 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE product_price_history_2025_12 PARTITION OF product_price_history
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Indexes for price history
CREATE INDEX idx_product_price_history_product_id ON product_price_history(product_id);
CREATE INDEX idx_product_price_history_recorded_at ON product_price_history(recorded_at);
CREATE INDEX idx_product_price_history_price ON product_price_history(price);

-- 2. Product ranking history table (partitioned by month)
CREATE TABLE product_ranking_history (
    id UUID DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category VARCHAR(255) NOT NULL,
    bsr_rank INTEGER,
    bsr_category VARCHAR(255),
    rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Create initial partitions for ranking history
CREATE TABLE product_ranking_history_2025_01 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE product_ranking_history_2025_02 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE product_ranking_history_2025_03 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE product_ranking_history_2025_04 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE product_ranking_history_2025_05 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE product_ranking_history_2025_06 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE product_ranking_history_2025_07 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE product_ranking_history_2025_08 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE product_ranking_history_2025_09 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE product_ranking_history_2025_10 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE product_ranking_history_2025_11 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE product_ranking_history_2025_12 PARTITION OF product_ranking_history
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Indexes for ranking history
CREATE INDEX idx_product_ranking_history_product_id ON product_ranking_history(product_id);
CREATE INDEX idx_product_ranking_history_recorded_at ON product_ranking_history(recorded_at);
CREATE INDEX idx_product_ranking_history_bsr_rank ON product_ranking_history(bsr_rank);
CREATE INDEX idx_product_ranking_history_category ON product_ranking_history(category);

-- 3. Function to automatically create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_partitions()
RETURNS void AS $$
DECLARE
    start_date date;
    end_date date;
    partition_name text;
BEGIN
    -- Create partitions for the next 12 months
    FOR i IN 0..11 LOOP
        start_date := date_trunc('month', CURRENT_DATE + (i || ' months')::interval);
        end_date := start_date + interval '1 month';
        
        -- Price history partition
        partition_name := 'product_price_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_price_history 
                       FOR VALUES FROM (%L) TO (%L)', 
                       partition_name, start_date, end_date);
        
        -- Ranking history partition
        partition_name := 'product_ranking_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_ranking_history 
                       FOR VALUES FROM (%L) TO (%L)', 
                       partition_name, start_date, end_date);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. API usage logs table (partitioned by month)
CREATE TABLE api_usage_logs (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create initial API usage log partitions
CREATE TABLE api_usage_logs_2025_09 PARTITION OF api_usage_logs
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE api_usage_logs_2025_10 PARTITION OF api_usage_logs
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE api_usage_logs_2025_11 PARTITION OF api_usage_logs
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE api_usage_logs_2025_12 PARTITION OF api_usage_logs
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- Indexes for API usage logs
CREATE INDEX idx_api_usage_logs_user_id ON api_usage_logs(user_id);
CREATE INDEX idx_api_usage_logs_endpoint ON api_usage_logs(endpoint);
CREATE INDEX idx_api_usage_logs_created_at ON api_usage_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER set_timestamp_users BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_user_settings BEFORE UPDATE ON user_settings 
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_tracked_products BEFORE UPDATE ON tracked_products 
    FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();