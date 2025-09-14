-- Migration: 005_simplify_anomaly_detection.sql
-- Purpose: Simplify anomaly detection - remove unnecessary queue table
-- Date: 2025-09-13
-- Reason: Use Redis queue instead of database table, history tables already contain all data

-- ============================================
-- 1. Remove Unnecessary Queue Table
-- ============================================

-- Drop the queue table - we use Redis for queuing, not database
DROP TABLE IF EXISTS anomaly_detection_queue;

-- ============================================
-- 2. Keep Only Essential Tables
-- ============================================

-- Keep user_anomaly_settings (for personalization)
-- Keep anomaly_detection_history (for analytics)
-- Use existing history tables for data:
--   - product_price_history (contains all price data)
--   - product_ranking_history (contains all BSR data)
--   - product_review_history (contains all review data)
--   - product_buybox_history (contains all buybox data)

-- ============================================
-- 3. Simplified Anomaly Detection Logic
-- ============================================

-- Application-layer approach:
-- 1. Apify Worker saves data to history tables
-- 2. Worker sends Redis queue message: asynq.NewTask("anomaly_detection", payload)
-- 3. Anomaly Worker processes queue message
-- 4. Worker queries history tables to get previous data
-- 5. Worker calculates change percentage
-- 6. Worker checks user_anomaly_settings for threshold
-- 7. Worker sends notification if threshold exceeded
-- 8. Worker logs to anomaly_detection_history for analytics

-- No database triggers needed!
-- No additional queue tables needed!
-- Pure application-layer logic with Redis queue!

-- ============================================
-- 4. Update Schema Migrations
-- ============================================

INSERT INTO schema_migrations (version, applied_at)
VALUES ('005_simplify_anomaly_detection', NOW())
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration 005: Simplified anomaly detection architecture';
    RAISE NOTICE 'Removed unnecessary anomaly_detection_queue table';
    RAISE NOTICE 'Using Redis queue + history tables + user settings approach';
    RAISE NOTICE 'Clean design: Redis for queuing, PostgreSQL for data storage';
END $$;