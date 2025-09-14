-- Migration: Remove unnecessary tables and fields not required by questions.md
-- Purpose: Simplify schema to match exact requirements of questions.md option 1
-- Date: 2025-09-14

-- Remove user_settings table (not required by questions.md)
DROP TABLE IF EXISTS user_settings CASCADE;

-- Remove user_anomaly_settings table (not required by questions.md)
DROP TABLE IF EXISTS user_anomaly_settings CASCADE;

-- Add comments explaining the simplified approach
COMMENT ON TABLE users IS 'Basic user authentication only, no complex settings per questions.md requirements';
COMMENT ON TABLE tracked_products IS 'Product tracking with fixed daily frequency per questions.md requirements';

-- Verify core tables for questions.md option 1 requirements remain:
-- users, products, tracked_products, product_price_history, product_ranking_history, product_change_events