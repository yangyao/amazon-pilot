-- Amazon Pilot - Final Init SQL (single file)
-- Schema consolidated from current Go (GORM) models
-- Note: user_settings removed by design

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;       -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- compatibility

-- ==========================
-- Users
-- ==========================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  company_name VARCHAR(255),
  plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_plan_type ON users(plan_type);

-- ==========================
-- Products
-- ==========================
CREATE TABLE IF NOT EXISTS products (
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

  first_seen_at TIMESTAMPTZ DEFAULT NOW(),
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  data_source VARCHAR(50) DEFAULT 'apify',

  CONSTRAINT products_asin_length CHECK (length(asin) = 10)
);

CREATE INDEX IF NOT EXISTS idx_products_asin ON products(asin);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_first_seen_at ON products(first_seen_at);
CREATE INDEX IF NOT EXISTS idx_products_last_updated_at ON products(last_updated_at);

-- ==========================
-- Tracked Products
-- ==========================
CREATE TABLE IF NOT EXISTS tracked_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  alias VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  tracking_frequency VARCHAR(20) DEFAULT 'daily',
  price_change_threshold DECIMAL(5,2) DEFAULT 10.0,
  bsr_change_threshold DECIMAL(5,2) DEFAULT 30.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_checked_at TIMESTAMPTZ,
  next_check_at TIMESTAMPTZ,

  CONSTRAINT tracked_products_user_product_unique UNIQUE (user_id, product_id),
  CONSTRAINT tracked_products_frequency_check CHECK (tracking_frequency IN ('hourly','daily','weekly')),
  CONSTRAINT tracked_products_price_threshold_check CHECK (price_change_threshold >= 0 AND price_change_threshold <= 100),
  CONSTRAINT tracked_products_bsr_threshold_check CHECK (bsr_change_threshold >= 0 AND bsr_change_threshold <= 100)
);

CREATE INDEX IF NOT EXISTS idx_tracked_products_user_id ON tracked_products(user_id);
CREATE INDEX IF NOT EXISTS idx_tracked_products_product_id ON tracked_products(product_id);
CREATE INDEX IF NOT EXISTS idx_tracked_products_next_check_at ON tracked_products(next_check_at);
CREATE INDEX IF NOT EXISTS idx_tracked_products_is_active ON tracked_products(is_active);

-- Partitioned by month on recorded_at
CREATE TABLE IF NOT EXISTS product_price_history (
  id UUID DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  price DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  buy_box_price DECIMAL(10,2),
  is_on_sale BOOLEAN DEFAULT FALSE,
  discount_percentage DECIMAL(5,2),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  data_source VARCHAR(50) DEFAULT 'apify',
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE INDEX IF NOT EXISTS idx_product_price_history_product_id ON product_price_history(product_id);
CREATE INDEX IF NOT EXISTS idx_product_price_history_recorded_at ON product_price_history(recorded_at);
CREATE INDEX IF NOT EXISTS idx_product_price_history_price ON product_price_history(price);

-- Partitioned by month on recorded_at
CREATE TABLE IF NOT EXISTS product_ranking_history (
  id UUID DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  category VARCHAR(255) NOT NULL,
  bsr_rank INTEGER,
  bsr_category VARCHAR(255),
  rating DECIMAL(3,2),
  review_count INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  data_source VARCHAR(50) DEFAULT 'apify',
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE INDEX IF NOT EXISTS idx_product_ranking_history_product_id ON product_ranking_history(product_id);
CREATE INDEX IF NOT EXISTS idx_product_ranking_history_recorded_at ON product_ranking_history(recorded_at);
CREATE INDEX IF NOT EXISTS idx_product_ranking_history_bsr_rank ON product_ranking_history(bsr_rank);
CREATE INDEX IF NOT EXISTS idx_product_ranking_history_category ON product_ranking_history(category);

-- ==========================
-- Helpers: create next 12 months partitions
-- ==========================
CREATE OR REPLACE FUNCTION create_monthly_partitions()
RETURNS void AS $$
DECLARE
    start_date date;
    end_date date;
    pname text;
BEGIN
    FOR i IN -1..11 LOOP  -- include previous month for late-arriving data
        start_date := date_trunc('month', CURRENT_DATE + (i || ' months')::interval);
        end_date := (start_date + interval '1 month');

        -- Price history partition
        pname := 'product_price_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_price_history FOR VALUES FROM (%L) TO (%L)',
                       pname, start_date, end_date);
        -- Indexes for price history partition
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (product_id)', 'idx_'||pname||'_product_id', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (recorded_at)', 'idx_'||pname||'_recorded_at', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (price)', 'idx_'||pname||'_price', pname);

        -- Ranking history partition
        pname := 'product_ranking_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_ranking_history FOR VALUES FROM (%L) TO (%L)',
                       pname, start_date, end_date);
        -- Indexes for ranking history partition
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (product_id)', 'idx_'||pname||'_product_id', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (recorded_at)', 'idx_'||pname||'_recorded_at', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (bsr_rank)', 'idx_'||pname||'_bsr_rank', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (category)', 'idx_'||pname||'_category', pname);

        -- Review history partition
        pname := 'product_review_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_review_history FOR VALUES FROM (%L) TO (%L)',
                       pname, start_date, end_date);
        -- Indexes for review history partition
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (product_id)', 'idx_'||pname||'_product_id', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (recorded_at)', 'idx_'||pname||'_recorded_at', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (average_rating)', 'idx_'||pname||'_avg_rating', pname);

        -- Buybox history partition
        pname := 'product_buybox_history_' || to_char(start_date, 'YYYY_MM');
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF product_buybox_history FOR VALUES FROM (%L) TO (%L)',
                       pname, start_date, end_date);
        -- Indexes for buybox history partition
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (product_id)', 'idx_'||pname||'_product_id', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (recorded_at)', 'idx_'||pname||'_recorded_at', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (winner_seller)', 'idx_'||pname||'_seller', pname);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (winner_price)', 'idx_'||pname||'_price', pname);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- Review History
-- ==========================
CREATE TABLE IF NOT EXISTS product_review_history (
  id UUID DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  review_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2),
  five_star_count INTEGER DEFAULT 0,
  four_star_count INTEGER DEFAULT 0,
  three_star_count INTEGER DEFAULT 0,
  two_star_count INTEGER DEFAULT 0,
  one_star_count INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  data_source VARCHAR(50) DEFAULT 'apify',
  CONSTRAINT review_history_rating_valid CHECK (average_rating IS NULL OR (average_rating >= 0 AND average_rating <= 5)),
  CONSTRAINT review_history_counts_positive CHECK (
    review_count >= 0 AND five_star_count >= 0 AND four_star_count >= 0 AND
    three_star_count >= 0 AND two_star_count >= 0 AND one_star_count >= 0),
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE INDEX IF NOT EXISTS idx_review_history_product_id ON product_review_history(product_id);
CREATE INDEX IF NOT EXISTS idx_review_history_recorded_at ON product_review_history(recorded_at);
CREATE INDEX IF NOT EXISTS idx_review_history_rating ON product_review_history(average_rating);

-- ==========================
-- Buy Box History
-- ==========================
CREATE TABLE IF NOT EXISTS product_buybox_history (
  id UUID DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  winner_seller VARCHAR(255),
  winner_price DECIMAL(10,2),
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  is_prime BOOLEAN DEFAULT FALSE,
  is_fba BOOLEAN DEFAULT FALSE,
  shipping_info TEXT,
  availability_text VARCHAR(255),
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  data_source VARCHAR(50) DEFAULT 'apify',
  CONSTRAINT buybox_price_positive CHECK (winner_price IS NULL OR winner_price >= 0),
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE INDEX IF NOT EXISTS idx_buybox_history_product_id ON product_buybox_history(product_id);
CREATE INDEX IF NOT EXISTS idx_buybox_history_recorded_at ON product_buybox_history(recorded_at);
CREATE INDEX IF NOT EXISTS idx_buybox_history_seller ON product_buybox_history(winner_seller);
CREATE INDEX IF NOT EXISTS idx_buybox_history_price ON product_buybox_history(winner_price);

-- ==========================
-- Competitor Analysis
-- ==========================
CREATE TABLE IF NOT EXISTS competitor_analysis_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  main_product_id UUID NOT NULL REFERENCES products(id),
  analysis_metrics JSONB DEFAULT '["price", "bsr", "rating", "features"]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_analysis_at TIMESTAMPTZ,
  next_analysis_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_competitor_groups_user_id ON competitor_analysis_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_competitor_groups_main_product_id ON competitor_analysis_groups(main_product_id);
CREATE INDEX IF NOT EXISTS idx_competitor_groups_is_active ON competitor_analysis_groups(is_active);
CREATE INDEX IF NOT EXISTS idx_competitor_groups_last_analysis_at ON competitor_analysis_groups(last_analysis_at);

CREATE TABLE IF NOT EXISTS competitor_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT competitor_products_group_product_unique UNIQUE (analysis_group_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_competitor_products_analysis_group_id ON competitor_products(analysis_group_id);
CREATE INDEX IF NOT EXISTS idx_competitor_products_product_id ON competitor_products(product_id);

CREATE TABLE IF NOT EXISTS competitor_analysis_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
  analysis_data JSONB NOT NULL,
  insights JSONB,
  recommendations JSONB,
  status VARCHAR(20) DEFAULT 'pending',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_competitor_analysis_results_group_id ON competitor_analysis_results(analysis_group_id);
CREATE INDEX IF NOT EXISTS idx_competitor_analysis_results_status ON competitor_analysis_results(status);
CREATE INDEX IF NOT EXISTS idx_competitor_analysis_results_started_at ON competitor_analysis_results(started_at);

-- ==========================
-- Optimization
-- ==========================
CREATE TABLE IF NOT EXISTS optimization_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  analysis_type VARCHAR(50) DEFAULT 'comprehensive',
  focus_areas JSONB DEFAULT '["title", "pricing", "description", "images", "keywords"]'::jsonb,
  status VARCHAR(20) DEFAULT 'pending',
  overall_score INTEGER,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_optimization_analyses_user_id ON optimization_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_optimization_analyses_product_id ON optimization_analyses(product_id);
CREATE INDEX IF NOT EXISTS idx_optimization_analyses_status ON optimization_analyses(status);
CREATE INDEX IF NOT EXISTS idx_optimization_analyses_started_at ON optimization_analyses(started_at);

CREATE TABLE IF NOT EXISTS optimization_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES optimization_analyses(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL,
  priority VARCHAR(10) NOT NULL,
  impact_score INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  action_items JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_optimization_suggestions_analysis_id ON optimization_suggestions(analysis_id);
CREATE INDEX IF NOT EXISTS idx_optimization_suggestions_category ON optimization_suggestions(category);
CREATE INDEX IF NOT EXISTS idx_optimization_suggestions_priority ON optimization_suggestions(priority);
CREATE INDEX IF NOT EXISTS idx_optimization_suggestions_impact_score ON optimization_suggestions(impact_score);

CREATE TABLE IF NOT EXISTS product_anomaly_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  asin VARCHAR(20) NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  old_value DECIMAL(15,2),
  new_value DECIMAL(15,2),
  change_percentage DECIMAL(10,2),
  threshold DECIMAL(10,2),
  severity VARCHAR(20) NOT NULL DEFAULT 'info',
  metadata JSONB,
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_anomaly_events_product_id ON product_anomaly_events(product_id);
CREATE INDEX IF NOT EXISTS idx_product_anomaly_events_asin ON product_anomaly_events(asin);
CREATE INDEX IF NOT EXISTS idx_product_anomaly_events_created ON product_anomaly_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_anomaly_events_severity ON product_anomaly_events(severity);
CREATE INDEX IF NOT EXISTS idx_product_anomaly_events_event_type ON product_anomaly_events(event_type);

-- ==========================
-- Seed demo data (users only)
-- ==========================
INSERT INTO users (email, password_hash, company_name, plan_type)
VALUES
  ('demo@amazonpilot.com', '$2a$10$8k.4K5dMFQI5oZ.8yZBvr.AZz.7Lm2U4F8D9vY7KjH4P9oM1N2Q8S', 'Demo Company', 'basic'),
  ('admin@amazonpilot.com', '$2a$10$8k.4K5dMFQI5oZ.8yZBvr.AZz.7Lm2U4F8D9vY7KjH4P9oM1N2Q8S', 'Amazon Pilot', 'premium')
ON CONFLICT (email) DO NOTHING;


-- ==========================
-- Create initial partitions AFTER all tables are created
-- ==========================
SELECT create_monthly_partitions();
