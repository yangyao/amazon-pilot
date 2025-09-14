-- Migration: Add product_change_events table for anomaly detection
-- Purpose: Store product data change events (price/BSR changes) for notification system
-- Date: 2025-09-14

-- Create product_change_events table
CREATE TABLE IF NOT EXISTS product_change_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    asin VARCHAR(20) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- price_change, bsr_change, rating_change
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    change_percentage DECIMAL(10,2),
    threshold DECIMAL(10,2),
    severity VARCHAR(20) NOT NULL DEFAULT 'info', -- info, warning, critical
    metadata JSONB,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT product_change_events_event_type_check
        CHECK (event_type IN ('price_change', 'bsr_change', 'rating_change')),
    CONSTRAINT product_change_events_severity_check
        CHECK (severity IN ('info', 'warning', 'critical'))
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_product_change_events_product_id
    ON product_change_events(product_id);

CREATE INDEX IF NOT EXISTS idx_product_change_events_asin
    ON product_change_events(asin);

CREATE INDEX IF NOT EXISTS idx_product_change_events_created
    ON product_change_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_product_change_events_severity
    ON product_change_events(severity);

CREATE INDEX IF NOT EXISTS idx_product_change_events_event_type
    ON product_change_events(event_type);

-- Create composite index for user queries (via tracked_products)
CREATE INDEX IF NOT EXISTS idx_product_change_events_user_query
    ON product_change_events(event_type, severity, created_at DESC);

-- Add foreign key constraint
ALTER TABLE product_change_events
    ADD CONSTRAINT fk_product_change_events_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

-- Add comment
COMMENT ON TABLE product_change_events IS 'Stores product data change events for anomaly detection and notifications';
COMMENT ON COLUMN product_change_events.event_type IS 'Type of change: price_change, bsr_change, rating_change';
COMMENT ON COLUMN product_change_events.severity IS 'Severity level: info, warning, critical';
COMMENT ON COLUMN product_change_events.change_percentage IS 'Percentage change from old value to new value';
COMMENT ON COLUMN product_change_events.threshold IS 'User-defined threshold that triggered this event';