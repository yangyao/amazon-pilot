-- Migration: Rename product_change_events to product_anomaly_events
-- Purpose: Better reflect the table's purpose - storing anomaly detection events (price >10%, BSR >30%, etc.)
-- Date: 2025-09-14

-- Rename the table to better reflect its purpose
ALTER TABLE IF EXISTS product_change_events RENAME TO product_anomaly_events;

-- Rename indexes to match the new table name
ALTER INDEX IF EXISTS idx_product_change_events_product_id RENAME TO idx_product_anomaly_events_product_id;
ALTER INDEX IF EXISTS idx_product_change_events_asin RENAME TO idx_product_anomaly_events_asin;
ALTER INDEX IF EXISTS idx_product_change_events_created RENAME TO idx_product_anomaly_events_created;
ALTER INDEX IF EXISTS idx_product_change_events_severity RENAME TO idx_product_anomaly_events_severity;
ALTER INDEX IF EXISTS idx_product_change_events_event_type RENAME TO idx_product_anomaly_events_event_type;
ALTER INDEX IF EXISTS idx_product_change_events_user_query RENAME TO idx_product_anomaly_events_user_query;

-- Rename constraint to match new table name
ALTER TABLE product_anomaly_events RENAME CONSTRAINT product_change_events_event_type_check TO product_anomaly_events_event_type_check;
ALTER TABLE product_anomaly_events RENAME CONSTRAINT product_change_events_severity_check TO product_anomaly_events_severity_check;
ALTER TABLE product_anomaly_events RENAME CONSTRAINT fk_product_change_events_product TO fk_product_anomaly_events_product;

-- Update table and column comments to reflect the new purpose
COMMENT ON TABLE product_anomaly_events IS 'Stores product anomaly detection events (price changes >10%, BSR changes >30%, rating/review changes, etc.)';
COMMENT ON COLUMN product_anomaly_events.event_type IS 'Type of anomaly: price_change, bsr_change, rating_change, review_count_change, buybox_change';
COMMENT ON COLUMN product_anomaly_events.severity IS 'Severity level based on threshold breach: info, warning, critical';
COMMENT ON COLUMN product_anomaly_events.change_percentage IS 'Percentage change that triggered the anomaly alert';
COMMENT ON COLUMN product_anomaly_events.threshold IS 'User-defined threshold percentage that triggered this anomaly event';

-- Update the event_type constraint to include new event types
ALTER TABLE product_anomaly_events DROP CONSTRAINT IF EXISTS product_anomaly_events_event_type_check;
ALTER TABLE product_anomaly_events
    ADD CONSTRAINT product_anomaly_events_event_type_check
    CHECK (event_type IN ('price_change', 'bsr_change', 'rating_change', 'review_count_change', 'buybox_change'));