-- Amazon Pilot - Supabase Safe DDL
-- This file is optimized for execution in Supabase SQL Editor
-- Generated from production DDL

-- Note: Extensions are usually already available in Supabase
-- If they fail, you can ignore these errors
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Remove the problematic \restrict command and pg_dump metadata
-- The original DDL will work mostly as-is, but let's start with the clean version

-- Drop existing tables (if they exist)
DROP TABLE IF EXISTS public.tracked_products CASCADE;
DROP TABLE IF EXISTS public.product_review_history CASCADE;
DROP TABLE IF EXISTS public.product_ranking_history CASCADE;
DROP TABLE IF EXISTS public.product_price_history CASCADE;
DROP TABLE IF EXISTS public.product_buybox_history CASCADE;
DROP TABLE IF EXISTS public.product_anomaly_events CASCADE;
DROP TABLE IF EXISTS public.optimization_suggestions CASCADE;
DROP TABLE IF EXISTS public.optimization_analyses CASCADE;
DROP TABLE IF EXISTS public.competitor_analysis_results CASCADE;
DROP TABLE IF EXISTS public.competitor_products CASCADE;
DROP TABLE IF EXISTS public.competitor_analysis_groups CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;

-- Note: The rest of your DDL should work fine in Supabase
-- Just copy the content from init.sql starting from the CREATE TABLE statements
-- and skip the SET statements at the beginning

-- Instructions:
-- 1. Open Supabase SQL Editor
-- 2. Run this file first to clean up and prepare
-- 3. Then copy the CREATE TABLE statements from init.sql (starting around line 150)
-- 4. Skip all the SET statements and \restrict commands