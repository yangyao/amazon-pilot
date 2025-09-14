-- Migration: 004_remove_triggers_add_async_detection.sql
-- Purpose: Remove complex triggers, implement application-layer async anomaly detection
-- Date: 2025-09-13
-- Performance: Improved write performance by removing trigger overhead

-- ============================================
-- 1. Remove Complex Triggers (Performance Optimization)
-- ============================================

-- Drop existing complex triggers
DROP TRIGGER IF EXISTS price_change_hybrid ON product_price_history;
DROP TRIGGER IF EXISTS bsr_change_hybrid ON product_ranking_history;

-- Drop trigger functions
DROP FUNCTION IF EXISTS notify_price_change_hybrid();
DROP FUNCTION IF EXISTS notify_bsr_change_hybrid();

-- ============================================
-- 2. Simplified Change Events Table (Queue Support)
-- ============================================

-- Simplify change_events table for application-layer processing
DROP TABLE IF EXISTS change_events;

CREATE TABLE anomaly_detection_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    detection_type VARCHAR(50) NOT NULL, -- price_check, bsr_check, review_check, buybox_check
    trigger_data JSONB NOT NULL,         -- Store relevant data for detection
    priority INTEGER DEFAULT 5,          -- Queue priority (1-10)
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT detection_type_check CHECK (detection_type IN ('price_check', 'bsr_check', 'review_check', 'buybox_check')),
    CONSTRAINT status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed'))
);

-- Indexes for queue processing
CREATE INDEX idx_anomaly_queue_status_scheduled ON anomaly_detection_queue(status, scheduled_at);
CREATE INDEX idx_anomaly_queue_product ON anomaly_detection_queue(product_id, detection_type);
CREATE INDEX idx_anomaly_queue_priority ON anomaly_detection_queue(priority DESC, created_at);

COMMENT ON TABLE anomaly_detection_queue IS 'Queue table for async anomaly detection tasks';

-- ============================================
-- 3. User Notification Preferences (Personalization)
-- ============================================

CREATE TABLE user_anomaly_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    price_change_threshold DECIMAL(5,2) DEFAULT 10.0,    -- Default 10%
    bsr_change_threshold DECIMAL(5,2) DEFAULT 30.0,      -- Default 30%
    rating_change_threshold DECIMAL(3,2) DEFAULT 0.3,    -- Default 0.3 stars
    notification_enabled BOOLEAN DEFAULT true,
    notification_methods JSONB DEFAULT '["email"]'::jsonb, -- email, push, sms
    notification_frequency VARCHAR(20) DEFAULT 'immediate', -- immediate, hourly, daily
    quiet_hours_start TIME,                               -- Optional quiet hours
    quiet_hours_end TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT user_anomaly_settings_unique UNIQUE (user_id),
    CONSTRAINT thresholds_positive CHECK (
        price_change_threshold >= 0 AND
        bsr_change_threshold >= 0 AND
        rating_change_threshold >= 0
    )
);

CREATE INDEX idx_user_anomaly_settings_user ON user_anomaly_settings(user_id);

COMMENT ON TABLE user_anomaly_settings IS 'User personalized anomaly detection settings';

-- ============================================
-- 4. Anomaly History Log (For Analytics)
-- ============================================

CREATE TABLE anomaly_detection_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    anomaly_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,         -- info, warning, critical
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    change_percentage DECIMAL(10,2),
    threshold_used DECIMAL(5,2),           -- Threshold that was used for detection
    notification_sent BOOLEAN DEFAULT false,
    notification_methods JSONB,            -- Which methods were used
    metadata JSONB,                        -- Additional context
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT anomaly_type_check CHECK (anomaly_type IN ('price_increase', 'price_decrease', 'bsr_improve', 'bsr_worsen', 'rating_drop')),
    CONSTRAINT severity_check CHECK (severity IN ('info', 'warning', 'critical'))
);

-- Indexes for analytics
CREATE INDEX idx_anomaly_history_product_time ON anomaly_detection_history(product_id, detected_at DESC);
CREATE INDEX idx_anomaly_history_user_time ON anomaly_detection_history(user_id, detected_at DESC);
CREATE INDEX idx_anomaly_history_type_severity ON anomaly_detection_history(anomaly_type, severity);

COMMENT ON TABLE anomaly_detection_history IS 'Historical log of all detected anomalies for analytics';

-- ============================================
-- 5. Application-Layer Helper Functions
-- ============================================

-- Function to get latest price for comparison (used by application)
CREATE OR REPLACE FUNCTION get_latest_price(target_product_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    latest_price DECIMAL(10,2);
BEGIN
    SELECT price INTO latest_price
    FROM product_price_history
    WHERE product_id = target_product_id
    ORDER BY recorded_at DESC
    LIMIT 1;

    RETURN COALESCE(latest_price, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to get latest BSR for comparison
CREATE OR REPLACE FUNCTION get_latest_bsr(target_product_id UUID)
RETURNS INTEGER AS $$
DECLARE
    latest_bsr INTEGER;
BEGIN
    SELECT bsr_rank INTO latest_bsr
    FROM product_ranking_history
    WHERE product_id = target_product_id
    ORDER BY recorded_at DESC
    LIMIT 1;

    RETURN COALESCE(latest_bsr, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. Update Schema Migrations
-- ============================================

INSERT INTO schema_migrations (version, applied_at)
VALUES ('004_remove_triggers_add_async_detection', NOW())
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration 004: Removed complex triggers, added async anomaly detection architecture';
    RAISE NOTICE 'Performance improved: No more trigger overhead on data insertion';
    RAISE NOTICE 'New approach: Application-layer detection with Redis queue processing';
END $$;