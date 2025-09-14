-- Migration: Remove tracking_frequency field from tracked_products
-- Purpose: questions.md specifies fixed daily update frequency, no user configuration needed
-- Date: 2025-09-14

-- Remove tracking_frequency column since it's fixed at daily
ALTER TABLE tracked_products
    DROP COLUMN IF EXISTS tracking_frequency;

-- Add comment about fixed frequency
COMMENT ON TABLE tracked_products IS 'Product tracking configuration. Update frequency is fixed at daily per questions.md requirements';

-- Update scheduler config to use fixed 24h interval (currently 1m for testing)