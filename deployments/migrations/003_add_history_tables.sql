-- Migration: 003_add_history_tables.sql
-- Purpose: Add missing history tables for reviews and buybox tracking
-- Date: 2025-09-13
-- Requirements: questions.md requires tracking of review changes and buybox changes

-- ============================================
-- 3. Review History Table (评论历史表)
-- ============================================
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

-- Indexes for review history
CREATE INDEX IF NOT EXISTS idx_review_history_product_recorded
ON product_review_history(product_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_history_recorded
ON product_review_history(recorded_at);

CREATE INDEX IF NOT EXISTS idx_review_history_rating
ON product_review_history(average_rating);

COMMENT ON TABLE product_review_history IS 'Track Amazon product review changes over time';

-- ============================================
-- 4. Buy Box History Table (Buy Box历史表)
-- ============================================
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

    CONSTRAINT buybox_price_positive CHECK (winner_price IS NULL OR winner_price >= 0),
    CONSTRAINT buybox_currency_valid CHECK (currency IN ('USD', 'EUR', 'GBP', 'CAD', 'JPY'))
);

-- Indexes for buybox history
CREATE INDEX IF NOT EXISTS idx_buybox_history_product_recorded
ON product_buybox_history(product_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_buybox_history_recorded
ON product_buybox_history(recorded_at);

CREATE INDEX IF NOT EXISTS idx_buybox_history_seller
ON product_buybox_history(winner_seller);

CREATE INDEX IF NOT EXISTS idx_buybox_history_price
ON product_buybox_history(winner_price);

COMMENT ON TABLE product_buybox_history IS 'Track Amazon product Buy Box winner changes over time';

-- ============================================
-- Update Complete Message
-- ============================================
INSERT INTO schema_migrations (version, applied_at)
VALUES ('003_add_history_tables', NOW())
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration 003: Successfully added product_review_history and product_buybox_history tables';
    RAISE NOTICE 'These tables support requirements from questions.md: tracking review changes and Buy Box changes';
END $$;