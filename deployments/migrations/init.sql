--
-- PostgreSQL database dump
--

\restrict fXe6AUA8GahVTU2NOkh5ndR7Hu65uOXbaSwWsMV4YGsETmzf26GJcJkyA6Nn3Jx

-- Dumped from database version 15.11
-- Dumped by pg_dump version 15.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.tracked_products DROP CONSTRAINT IF EXISTS tracked_products_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.tracked_products DROP CONSTRAINT IF EXISTS tracked_products_product_id_fkey;
ALTER TABLE IF EXISTS public.product_review_history DROP CONSTRAINT IF EXISTS product_review_history_product_id_fkey;
ALTER TABLE IF EXISTS public.product_ranking_history DROP CONSTRAINT IF EXISTS product_ranking_history_product_id_fkey;
ALTER TABLE IF EXISTS public.product_price_history DROP CONSTRAINT IF EXISTS product_price_history_product_id_fkey;
ALTER TABLE IF EXISTS public.product_buybox_history DROP CONSTRAINT IF EXISTS product_buybox_history_product_id_fkey;
ALTER TABLE IF EXISTS ONLY public.product_anomaly_events DROP CONSTRAINT IF EXISTS product_anomaly_events_product_id_fkey;
ALTER TABLE IF EXISTS ONLY public.optimization_suggestions DROP CONSTRAINT IF EXISTS optimization_suggestions_analysis_id_fkey;
ALTER TABLE IF EXISTS ONLY public.optimization_analyses DROP CONSTRAINT IF EXISTS optimization_analyses_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.optimization_analyses DROP CONSTRAINT IF EXISTS optimization_analyses_product_id_fkey;
ALTER TABLE IF EXISTS ONLY public.competitor_products DROP CONSTRAINT IF EXISTS competitor_products_product_id_fkey;
ALTER TABLE IF EXISTS ONLY public.competitor_products DROP CONSTRAINT IF EXISTS competitor_products_analysis_group_id_fkey;
ALTER TABLE IF EXISTS ONLY public.competitor_analysis_results DROP CONSTRAINT IF EXISTS competitor_analysis_results_analysis_group_id_fkey;
ALTER TABLE IF EXISTS ONLY public.competitor_analysis_groups DROP CONSTRAINT IF EXISTS competitor_analysis_groups_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.competitor_analysis_groups DROP CONSTRAINT IF EXISTS competitor_analysis_groups_main_product_id_fkey;
DROP INDEX IF EXISTS public.idx_users_plan_type;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_tracked_products_user_id;
DROP INDEX IF EXISTS public.idx_tracked_products_product_id;
DROP INDEX IF EXISTS public.idx_tracked_products_next_check_at;
DROP INDEX IF EXISTS public.idx_tracked_products_is_active;
DROP INDEX IF EXISTS public.idx_review_history_recorded_at;
DROP INDEX IF EXISTS public.idx_review_history_rating;
DROP INDEX IF EXISTS public.idx_review_history_product_id;
DROP INDEX IF EXISTS public.idx_products_last_updated_at;
DROP INDEX IF EXISTS public.idx_products_first_seen_at;
DROP INDEX IF EXISTS public.idx_products_category;
DROP INDEX IF EXISTS public.idx_products_brand;
DROP INDEX IF EXISTS public.idx_products_asin;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_08_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_08_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_07_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_07_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_07_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_06_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_06_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_06_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_05_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_05_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_05_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_04_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_04_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_04_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_03_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_03_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_03_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_02_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_02_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_02_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_01_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_01_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2026_01_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_12_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_12_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_12_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_11_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_11_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_11_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_10_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_10_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_10_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_09_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_09_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_09_avg_rating;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_08_product_id;
DROP INDEX IF EXISTS public.idx_product_review_history_2025_08_avg_rating;
DROP INDEX IF EXISTS public.idx_product_ranking_history_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_08_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_08_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_08_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_07_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_07_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_07_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_07_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_06_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_06_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_06_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_06_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_05_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_05_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_05_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_05_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_04_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_04_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_04_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_04_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_03_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_03_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_03_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_03_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_02_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_02_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_02_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_02_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_01_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_01_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_01_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2026_01_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_12_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_12_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_12_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_12_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_11_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_11_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_11_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_11_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_10_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_10_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_10_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_10_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_09_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_09_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_09_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_09_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_08_product_id;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_08_category;
DROP INDEX IF EXISTS public.idx_product_ranking_history_2025_08_bsr_rank;
DROP INDEX IF EXISTS public.idx_product_price_history_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_08_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_08_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_07_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_07_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_07_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_06_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_06_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_06_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_05_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_05_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_05_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_04_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_04_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_04_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_03_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_03_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_03_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_02_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_02_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_02_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_01_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_01_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2026_01_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_12_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_12_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_12_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_11_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_11_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_11_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_10_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_10_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_10_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_09_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_09_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_09_price;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_08_product_id;
DROP INDEX IF EXISTS public.idx_product_price_history_2025_08_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_08_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_08_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_08_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_07_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_07_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_07_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_07_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_06_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_06_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_06_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_06_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_05_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_05_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_05_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_05_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_04_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_04_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_04_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_04_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_03_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_03_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_03_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_03_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_02_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_02_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_02_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_02_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_01_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_01_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_01_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2026_01_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_12_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_12_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_12_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_12_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_11_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_11_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_11_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_11_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_10_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_10_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_10_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_10_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_09_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_09_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_09_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_09_price;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_08_seller;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_08_recorded_at;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_08_product_id;
DROP INDEX IF EXISTS public.idx_product_buybox_history_2025_08_price;
DROP INDEX IF EXISTS public.idx_product_anomaly_events_severity;
DROP INDEX IF EXISTS public.idx_product_anomaly_events_product_id;
DROP INDEX IF EXISTS public.idx_product_anomaly_events_event_type;
DROP INDEX IF EXISTS public.idx_product_anomaly_events_created;
DROP INDEX IF EXISTS public.idx_product_anomaly_events_asin;
DROP INDEX IF EXISTS public.idx_optimization_suggestions_priority;
DROP INDEX IF EXISTS public.idx_optimization_suggestions_impact_score;
DROP INDEX IF EXISTS public.idx_optimization_suggestions_category;
DROP INDEX IF EXISTS public.idx_optimization_suggestions_analysis_id;
DROP INDEX IF EXISTS public.idx_optimization_analyses_user_id;
DROP INDEX IF EXISTS public.idx_optimization_analyses_status;
DROP INDEX IF EXISTS public.idx_optimization_analyses_started_at;
DROP INDEX IF EXISTS public.idx_optimization_analyses_product_id;
DROP INDEX IF EXISTS public.idx_competitor_products_product_id;
DROP INDEX IF EXISTS public.idx_competitor_products_analysis_group_id;
DROP INDEX IF EXISTS public.idx_competitor_groups_user_id;
DROP INDEX IF EXISTS public.idx_competitor_groups_main_product_id;
DROP INDEX IF EXISTS public.idx_competitor_groups_last_analysis_at;
DROP INDEX IF EXISTS public.idx_competitor_groups_is_active;
DROP INDEX IF EXISTS public.idx_competitor_analysis_results_status;
DROP INDEX IF EXISTS public.idx_competitor_analysis_results_started_at;
DROP INDEX IF EXISTS public.idx_competitor_analysis_results_group_id;
DROP INDEX IF EXISTS public.idx_buybox_history_seller;
DROP INDEX IF EXISTS public.idx_buybox_history_recorded_at;
DROP INDEX IF EXISTS public.idx_buybox_history_product_id;
DROP INDEX IF EXISTS public.idx_buybox_history_price;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.tracked_products DROP CONSTRAINT IF EXISTS tracked_products_user_product_unique;
ALTER TABLE IF EXISTS ONLY public.tracked_products DROP CONSTRAINT IF EXISTS tracked_products_pkey;
ALTER TABLE IF EXISTS ONLY public.products DROP CONSTRAINT IF EXISTS products_pkey;
ALTER TABLE IF EXISTS ONLY public.products DROP CONSTRAINT IF EXISTS products_asin_key;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_08 DROP CONSTRAINT IF EXISTS product_review_history_2026_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_07 DROP CONSTRAINT IF EXISTS product_review_history_2026_07_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_06 DROP CONSTRAINT IF EXISTS product_review_history_2026_06_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_05 DROP CONSTRAINT IF EXISTS product_review_history_2026_05_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_04 DROP CONSTRAINT IF EXISTS product_review_history_2026_04_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_03 DROP CONSTRAINT IF EXISTS product_review_history_2026_03_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_02 DROP CONSTRAINT IF EXISTS product_review_history_2026_02_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2026_01 DROP CONSTRAINT IF EXISTS product_review_history_2026_01_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2025_12 DROP CONSTRAINT IF EXISTS product_review_history_2025_12_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2025_11 DROP CONSTRAINT IF EXISTS product_review_history_2025_11_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2025_10 DROP CONSTRAINT IF EXISTS product_review_history_2025_10_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2025_09 DROP CONSTRAINT IF EXISTS product_review_history_2025_09_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history_2025_08 DROP CONSTRAINT IF EXISTS product_review_history_2025_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_review_history DROP CONSTRAINT IF EXISTS product_review_history_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_08 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_07 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_07_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_06 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_06_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_05 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_05_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_04 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_04_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_03 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_03_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_02 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_02_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2026_01 DROP CONSTRAINT IF EXISTS product_ranking_history_2026_01_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2025_12 DROP CONSTRAINT IF EXISTS product_ranking_history_2025_12_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2025_11 DROP CONSTRAINT IF EXISTS product_ranking_history_2025_11_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2025_10 DROP CONSTRAINT IF EXISTS product_ranking_history_2025_10_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2025_09 DROP CONSTRAINT IF EXISTS product_ranking_history_2025_09_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history_2025_08 DROP CONSTRAINT IF EXISTS product_ranking_history_2025_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_ranking_history DROP CONSTRAINT IF EXISTS product_ranking_history_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_08 DROP CONSTRAINT IF EXISTS product_price_history_2026_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_07 DROP CONSTRAINT IF EXISTS product_price_history_2026_07_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_06 DROP CONSTRAINT IF EXISTS product_price_history_2026_06_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_05 DROP CONSTRAINT IF EXISTS product_price_history_2026_05_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_04 DROP CONSTRAINT IF EXISTS product_price_history_2026_04_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_03 DROP CONSTRAINT IF EXISTS product_price_history_2026_03_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_02 DROP CONSTRAINT IF EXISTS product_price_history_2026_02_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2026_01 DROP CONSTRAINT IF EXISTS product_price_history_2026_01_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2025_12 DROP CONSTRAINT IF EXISTS product_price_history_2025_12_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2025_11 DROP CONSTRAINT IF EXISTS product_price_history_2025_11_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2025_10 DROP CONSTRAINT IF EXISTS product_price_history_2025_10_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2025_09 DROP CONSTRAINT IF EXISTS product_price_history_2025_09_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history_2025_08 DROP CONSTRAINT IF EXISTS product_price_history_2025_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_price_history DROP CONSTRAINT IF EXISTS product_price_history_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_08 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_07 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_07_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_06 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_06_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_05 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_05_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_04 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_04_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_03 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_03_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_02 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_02_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2026_01 DROP CONSTRAINT IF EXISTS product_buybox_history_2026_01_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2025_12 DROP CONSTRAINT IF EXISTS product_buybox_history_2025_12_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2025_11 DROP CONSTRAINT IF EXISTS product_buybox_history_2025_11_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2025_10 DROP CONSTRAINT IF EXISTS product_buybox_history_2025_10_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2025_09 DROP CONSTRAINT IF EXISTS product_buybox_history_2025_09_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history_2025_08 DROP CONSTRAINT IF EXISTS product_buybox_history_2025_08_pkey;
ALTER TABLE IF EXISTS ONLY public.product_buybox_history DROP CONSTRAINT IF EXISTS product_buybox_history_pkey;
ALTER TABLE IF EXISTS ONLY public.product_anomaly_events DROP CONSTRAINT IF EXISTS product_anomaly_events_pkey;
ALTER TABLE IF EXISTS ONLY public.optimization_suggestions DROP CONSTRAINT IF EXISTS optimization_suggestions_pkey;
ALTER TABLE IF EXISTS ONLY public.optimization_analyses DROP CONSTRAINT IF EXISTS optimization_analyses_pkey;
ALTER TABLE IF EXISTS ONLY public.competitor_products DROP CONSTRAINT IF EXISTS competitor_products_pkey;
ALTER TABLE IF EXISTS ONLY public.competitor_products DROP CONSTRAINT IF EXISTS competitor_products_group_product_unique;
ALTER TABLE IF EXISTS ONLY public.competitor_analysis_results DROP CONSTRAINT IF EXISTS competitor_analysis_results_pkey;
ALTER TABLE IF EXISTS ONLY public.competitor_analysis_groups DROP CONSTRAINT IF EXISTS competitor_analysis_groups_pkey;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.tracked_products;
DROP TABLE IF EXISTS public.products;
DROP TABLE IF EXISTS public.product_review_history_2026_08;
DROP TABLE IF EXISTS public.product_review_history_2026_07;
DROP TABLE IF EXISTS public.product_review_history_2026_06;
DROP TABLE IF EXISTS public.product_review_history_2026_05;
DROP TABLE IF EXISTS public.product_review_history_2026_04;
DROP TABLE IF EXISTS public.product_review_history_2026_03;
DROP TABLE IF EXISTS public.product_review_history_2026_02;
DROP TABLE IF EXISTS public.product_review_history_2026_01;
DROP TABLE IF EXISTS public.product_review_history_2025_12;
DROP TABLE IF EXISTS public.product_review_history_2025_11;
DROP TABLE IF EXISTS public.product_review_history_2025_10;
DROP TABLE IF EXISTS public.product_review_history_2025_09;
DROP TABLE IF EXISTS public.product_review_history_2025_08;
DROP TABLE IF EXISTS public.product_review_history;
DROP TABLE IF EXISTS public.product_ranking_history_2026_08;
DROP TABLE IF EXISTS public.product_ranking_history_2026_07;
DROP TABLE IF EXISTS public.product_ranking_history_2026_06;
DROP TABLE IF EXISTS public.product_ranking_history_2026_05;
DROP TABLE IF EXISTS public.product_ranking_history_2026_04;
DROP TABLE IF EXISTS public.product_ranking_history_2026_03;
DROP TABLE IF EXISTS public.product_ranking_history_2026_02;
DROP TABLE IF EXISTS public.product_ranking_history_2026_01;
DROP TABLE IF EXISTS public.product_ranking_history_2025_12;
DROP TABLE IF EXISTS public.product_ranking_history_2025_11;
DROP TABLE IF EXISTS public.product_ranking_history_2025_10;
DROP TABLE IF EXISTS public.product_ranking_history_2025_09;
DROP TABLE IF EXISTS public.product_ranking_history_2025_08;
DROP TABLE IF EXISTS public.product_ranking_history;
DROP TABLE IF EXISTS public.product_price_history_2026_08;
DROP TABLE IF EXISTS public.product_price_history_2026_07;
DROP TABLE IF EXISTS public.product_price_history_2026_06;
DROP TABLE IF EXISTS public.product_price_history_2026_05;
DROP TABLE IF EXISTS public.product_price_history_2026_04;
DROP TABLE IF EXISTS public.product_price_history_2026_03;
DROP TABLE IF EXISTS public.product_price_history_2026_02;
DROP TABLE IF EXISTS public.product_price_history_2026_01;
DROP TABLE IF EXISTS public.product_price_history_2025_12;
DROP TABLE IF EXISTS public.product_price_history_2025_11;
DROP TABLE IF EXISTS public.product_price_history_2025_10;
DROP TABLE IF EXISTS public.product_price_history_2025_09;
DROP TABLE IF EXISTS public.product_price_history_2025_08;
DROP TABLE IF EXISTS public.product_price_history;
DROP TABLE IF EXISTS public.product_buybox_history_2026_08;
DROP TABLE IF EXISTS public.product_buybox_history_2026_07;
DROP TABLE IF EXISTS public.product_buybox_history_2026_06;
DROP TABLE IF EXISTS public.product_buybox_history_2026_05;
DROP TABLE IF EXISTS public.product_buybox_history_2026_04;
DROP TABLE IF EXISTS public.product_buybox_history_2026_03;
DROP TABLE IF EXISTS public.product_buybox_history_2026_02;
DROP TABLE IF EXISTS public.product_buybox_history_2026_01;
DROP TABLE IF EXISTS public.product_buybox_history_2025_12;
DROP TABLE IF EXISTS public.product_buybox_history_2025_11;
DROP TABLE IF EXISTS public.product_buybox_history_2025_10;
DROP TABLE IF EXISTS public.product_buybox_history_2025_09;
DROP TABLE IF EXISTS public.product_buybox_history_2025_08;
DROP TABLE IF EXISTS public.product_buybox_history;
DROP TABLE IF EXISTS public.product_anomaly_events;
DROP TABLE IF EXISTS public.optimization_suggestions;
DROP TABLE IF EXISTS public.optimization_analyses;
DROP TABLE IF EXISTS public.competitor_products;
DROP TABLE IF EXISTS public.competitor_analysis_results;
DROP TABLE IF EXISTS public.competitor_analysis_groups;
DROP FUNCTION IF EXISTS public.create_monthly_partitions();
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pgcrypto;
--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: create_monthly_partitions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_monthly_partitions() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: competitor_analysis_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitor_analysis_groups (
                                                   id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                   user_id uuid NOT NULL,
                                                   name character varying(255) NOT NULL,
                                                   description text,
                                                   main_product_id uuid NOT NULL,
                                                   analysis_metrics jsonb DEFAULT '["price", "bsr", "rating", "features"]'::jsonb,
                                                   is_active boolean DEFAULT true,
                                                   created_at timestamp with time zone DEFAULT now(),
                                                   updated_at timestamp with time zone DEFAULT now(),
                                                   last_analysis_at timestamp with time zone,
                                                   next_analysis_at timestamp with time zone
);


--
-- Name: competitor_analysis_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitor_analysis_results (
                                                    id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                    analysis_group_id uuid NOT NULL,
                                                    analysis_data jsonb NOT NULL,
                                                    insights jsonb,
                                                    recommendations jsonb,
                                                    status character varying(20) DEFAULT 'pending'::character varying,
                                                    started_at timestamp with time zone DEFAULT now(),
                                                    completed_at timestamp with time zone,
                                                    error_message text
);


--
-- Name: competitor_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitor_products (
                                            id uuid DEFAULT gen_random_uuid() NOT NULL,
                                            analysis_group_id uuid NOT NULL,
                                            product_id uuid NOT NULL,
                                            added_at timestamp with time zone DEFAULT now()
);


--
-- Name: optimization_analyses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.optimization_analyses (
                                              id uuid DEFAULT gen_random_uuid() NOT NULL,
                                              user_id uuid NOT NULL,
                                              product_id uuid NOT NULL,
                                              analysis_type character varying(50) DEFAULT 'comprehensive'::character varying,
                                              focus_areas jsonb DEFAULT '["title", "pricing", "description", "images", "keywords"]'::jsonb,
                                              status character varying(20) DEFAULT 'pending'::character varying,
                                              overall_score integer,
                                              started_at timestamp with time zone DEFAULT now(),
                                              completed_at timestamp with time zone
);


--
-- Name: optimization_suggestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.optimization_suggestions (
                                                 id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                 analysis_id uuid NOT NULL,
                                                 category character varying(50) NOT NULL,
                                                 priority character varying(10) NOT NULL,
                                                 impact_score integer NOT NULL,
                                                 title character varying(255) NOT NULL,
                                                 description text NOT NULL,
                                                 action_items jsonb,
                                                 created_at timestamp with time zone DEFAULT now()
);


--
-- Name: product_anomaly_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_anomaly_events (
                                               id uuid DEFAULT gen_random_uuid() NOT NULL,
                                               product_id uuid NOT NULL,
                                               asin character varying(20) NOT NULL,
                                               event_type character varying(50) NOT NULL,
                                               old_value numeric(15,2),
                                               new_value numeric(15,2),
                                               change_percentage numeric(10,2),
                                               threshold numeric(10,2),
                                               severity character varying(20) DEFAULT 'info'::character varying NOT NULL,
                                               metadata jsonb,
                                               processed boolean DEFAULT false,
                                               processed_at timestamp with time zone,
                                               created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: product_buybox_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history (
                                               id uuid DEFAULT gen_random_uuid() NOT NULL,
                                               product_id uuid NOT NULL,
                                               winner_seller character varying(255),
                                               winner_price numeric(10,2),
                                               currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                               is_prime boolean DEFAULT false,
                                               is_fba boolean DEFAULT false,
                                               shipping_info text,
                                               availability_text character varying(255),
                                               recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                               data_source character varying(50) DEFAULT 'apify'::character varying,
                                               CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
)
    PARTITION BY RANGE (recorded_at);


--
-- Name: product_buybox_history_2025_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2025_08 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2025_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2025_09 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2025_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2025_10 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2025_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2025_11 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2025_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2025_12 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_01 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_02 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_03 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_04 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_05 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_06 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_07 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_buybox_history_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_buybox_history_2026_08 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       winner_seller character varying(255),
                                                       winner_price numeric(10,2),
                                                       currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                       is_prime boolean DEFAULT false,
                                                       is_fba boolean DEFAULT false,
                                                       shipping_info text,
                                                       availability_text character varying(255),
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT buybox_price_positive CHECK (((winner_price IS NULL) OR (winner_price >= (0)::numeric)))
);


--
-- Name: product_price_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history (
                                              id uuid DEFAULT gen_random_uuid() NOT NULL,
                                              product_id uuid NOT NULL,
                                              price numeric(10,2) NOT NULL,
                                              currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                              buy_box_price numeric(10,2),
                                              is_on_sale boolean DEFAULT false,
                                              discount_percentage numeric(5,2),
                                              recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                              data_source character varying(50) DEFAULT 'apify'::character varying
)
    PARTITION BY RANGE (recorded_at);


--
-- Name: product_price_history_2025_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2025_08 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2025_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2025_09 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2025_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2025_10 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2025_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2025_11 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2025_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2025_12 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_01 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_02 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_03 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_04 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_05 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_06 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_07 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_price_history_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_price_history_2026_08 (
                                                      id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                      product_id uuid NOT NULL,
                                                      price numeric(10,2) NOT NULL,
                                                      currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
                                                      buy_box_price numeric(10,2),
                                                      is_on_sale boolean DEFAULT false,
                                                      discount_percentage numeric(5,2),
                                                      recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                      data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history (
                                                id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                product_id uuid NOT NULL,
                                                category character varying(255) NOT NULL,
                                                bsr_rank integer,
                                                bsr_category character varying(255),
                                                rating numeric(3,2),
                                                review_count integer DEFAULT 0,
                                                recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                data_source character varying(50) DEFAULT 'apify'::character varying
)
    PARTITION BY RANGE (recorded_at);


--
-- Name: product_ranking_history_2025_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2025_08 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2025_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2025_09 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2025_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2025_10 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2025_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2025_11 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2025_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2025_12 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_01 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_02 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_03 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_04 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_05 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_06 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_07 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_ranking_history_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_ranking_history_2026_08 (
                                                        id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                        product_id uuid NOT NULL,
                                                        category character varying(255) NOT NULL,
                                                        bsr_rank integer,
                                                        bsr_category character varying(255),
                                                        rating numeric(3,2),
                                                        review_count integer DEFAULT 0,
                                                        recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                        data_source character varying(50) DEFAULT 'apify'::character varying
);


--
-- Name: product_review_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history (
                                               id uuid DEFAULT gen_random_uuid() NOT NULL,
                                               product_id uuid NOT NULL,
                                               review_count integer DEFAULT 0,
                                               average_rating numeric(3,2),
                                               five_star_count integer DEFAULT 0,
                                               four_star_count integer DEFAULT 0,
                                               three_star_count integer DEFAULT 0,
                                               two_star_count integer DEFAULT 0,
                                               one_star_count integer DEFAULT 0,
                                               recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                               data_source character varying(50) DEFAULT 'apify'::character varying,
                                               CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                               CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
)
    PARTITION BY RANGE (recorded_at);


--
-- Name: product_review_history_2025_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2025_08 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2025_09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2025_09 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2025_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2025_10 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2025_11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2025_11 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2025_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2025_12 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_01 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_02 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_03 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_04 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_05 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_06 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_07 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: product_review_history_2026_08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_review_history_2026_08 (
                                                       id uuid DEFAULT gen_random_uuid() NOT NULL,
                                                       product_id uuid NOT NULL,
                                                       review_count integer DEFAULT 0,
                                                       average_rating numeric(3,2),
                                                       five_star_count integer DEFAULT 0,
                                                       four_star_count integer DEFAULT 0,
                                                       three_star_count integer DEFAULT 0,
                                                       two_star_count integer DEFAULT 0,
                                                       one_star_count integer DEFAULT 0,
                                                       recorded_at timestamp with time zone DEFAULT now() NOT NULL,
                                                       data_source character varying(50) DEFAULT 'apify'::character varying,
                                                       CONSTRAINT review_history_counts_positive CHECK (((review_count >= 0) AND (five_star_count >= 0) AND (four_star_count >= 0) AND (three_star_count >= 0) AND (two_star_count >= 0) AND (one_star_count >= 0))),
                                                       CONSTRAINT review_history_rating_valid CHECK (((average_rating IS NULL) OR ((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))))
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
                                 id uuid DEFAULT gen_random_uuid() NOT NULL,
                                 asin character varying(10) NOT NULL,
                                 title text,
                                 brand character varying(255),
                                 category character varying(255),
                                 subcategory character varying(255),
                                 description text,
                                 bullet_points jsonb,
                                 images jsonb,
                                 dimensions jsonb,
                                 weight numeric(10,2),
                                 manufacturer character varying(255),
                                 model_number character varying(100),
                                 upc character varying(20),
                                 ean character varying(20),
                                 first_seen_at timestamp with time zone DEFAULT now(),
                                 last_updated_at timestamp with time zone DEFAULT now(),
                                 data_source character varying(50) DEFAULT 'apify'::character varying,
                                 CONSTRAINT products_asin_length CHECK ((length((asin)::text) = 10))
);


--
-- Name: tracked_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracked_products (
                                         id uuid DEFAULT gen_random_uuid() NOT NULL,
                                         user_id uuid NOT NULL,
                                         product_id uuid NOT NULL,
                                         alias character varying(255),
                                         is_active boolean DEFAULT true,
                                         tracking_frequency character varying(20) DEFAULT 'daily'::character varying,
                                         price_change_threshold numeric(5,2) DEFAULT 10.0,
                                         bsr_change_threshold numeric(5,2) DEFAULT 30.0,
                                         created_at timestamp with time zone DEFAULT now(),
                                         updated_at timestamp with time zone DEFAULT now(),
                                         last_checked_at timestamp with time zone,
                                         next_check_at timestamp with time zone,
                                         CONSTRAINT tracked_products_bsr_threshold_check CHECK (((bsr_change_threshold >= (0)::numeric) AND (bsr_change_threshold <= (100)::numeric))),
                                         CONSTRAINT tracked_products_frequency_check CHECK (((tracking_frequency)::text = ANY ((ARRAY['hourly'::character varying, 'daily'::character varying, 'weekly'::character varying])::text[]))),
    CONSTRAINT tracked_products_price_threshold_check CHECK (((price_change_threshold >= (0)::numeric) AND (price_change_threshold <= (100)::numeric)))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
                              id uuid DEFAULT gen_random_uuid() NOT NULL,
                              email character varying(255) NOT NULL,
                              password_hash character varying(255) NOT NULL,
                              company_name character varying(255),
                              plan_type character varying(50) DEFAULT 'basic'::character varying NOT NULL,
                              is_active boolean DEFAULT true,
                              email_verified boolean DEFAULT false,
                              created_at timestamp with time zone DEFAULT now(),
                              updated_at timestamp with time zone DEFAULT now(),
                              last_login_at timestamp with time zone
);


--
-- Name: product_buybox_history_2025_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2025_08 FOR VALUES FROM ('2025-08-01 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: product_buybox_history_2025_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2025_09 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-10-01 00:00:00+00');


--
-- Name: product_buybox_history_2025_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00+00') TO ('2025-11-01 00:00:00+00');


--
-- Name: product_buybox_history_2025_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00+00') TO ('2025-12-01 00:00:00+00');


--
-- Name: product_buybox_history_2025_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_02 FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_03 FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_04 FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_05 FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_06 FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');


--
-- Name: product_buybox_history_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history ATTACH PARTITION public.product_buybox_history_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');


--
-- Name: product_price_history_2025_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2025_08 FOR VALUES FROM ('2025-08-01 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: product_price_history_2025_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2025_09 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-10-01 00:00:00+00');


--
-- Name: product_price_history_2025_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00+00') TO ('2025-11-01 00:00:00+00');


--
-- Name: product_price_history_2025_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00+00') TO ('2025-12-01 00:00:00+00');


--
-- Name: product_price_history_2025_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');


--
-- Name: product_price_history_2026_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');


--
-- Name: product_price_history_2026_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_02 FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');


--
-- Name: product_price_history_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_03 FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');


--
-- Name: product_price_history_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_04 FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00');


--
-- Name: product_price_history_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_05 FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00');


--
-- Name: product_price_history_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_06 FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');


--
-- Name: product_price_history_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');


--
-- Name: product_price_history_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history ATTACH PARTITION public.product_price_history_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');


--
-- Name: product_ranking_history_2025_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2025_08 FOR VALUES FROM ('2025-08-01 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: product_ranking_history_2025_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2025_09 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-10-01 00:00:00+00');


--
-- Name: product_ranking_history_2025_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00+00') TO ('2025-11-01 00:00:00+00');


--
-- Name: product_ranking_history_2025_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00+00') TO ('2025-12-01 00:00:00+00');


--
-- Name: product_ranking_history_2025_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_02 FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_03 FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_04 FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_05 FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_06 FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');


--
-- Name: product_ranking_history_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history ATTACH PARTITION public.product_ranking_history_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');


--
-- Name: product_review_history_2025_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2025_08 FOR VALUES FROM ('2025-08-01 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: product_review_history_2025_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2025_09 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-10-01 00:00:00+00');


--
-- Name: product_review_history_2025_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00+00') TO ('2025-11-01 00:00:00+00');


--
-- Name: product_review_history_2025_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00+00') TO ('2025-12-01 00:00:00+00');


--
-- Name: product_review_history_2025_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');


--
-- Name: product_review_history_2026_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');


--
-- Name: product_review_history_2026_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_02 FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');


--
-- Name: product_review_history_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_03 FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');


--
-- Name: product_review_history_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_04 FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00');


--
-- Name: product_review_history_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_05 FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00');


--
-- Name: product_review_history_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_06 FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');


--
-- Name: product_review_history_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_07 FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00');


--
-- Name: product_review_history_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history ATTACH PARTITION public.product_review_history_2026_08 FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00');


--
-- Name: competitor_analysis_groups competitor_analysis_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_analysis_groups
    ADD CONSTRAINT competitor_analysis_groups_pkey PRIMARY KEY (id);


--
-- Name: competitor_analysis_results competitor_analysis_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_analysis_results
    ADD CONSTRAINT competitor_analysis_results_pkey PRIMARY KEY (id);


--
-- Name: competitor_products competitor_products_group_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_products
    ADD CONSTRAINT competitor_products_group_product_unique UNIQUE (analysis_group_id, product_id);


--
-- Name: competitor_products competitor_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_products
    ADD CONSTRAINT competitor_products_pkey PRIMARY KEY (id);


--
-- Name: optimization_analyses optimization_analyses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimization_analyses
    ADD CONSTRAINT optimization_analyses_pkey PRIMARY KEY (id);


--
-- Name: optimization_suggestions optimization_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimization_suggestions
    ADD CONSTRAINT optimization_suggestions_pkey PRIMARY KEY (id);


--
-- Name: product_anomaly_events product_anomaly_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_anomaly_events
    ADD CONSTRAINT product_anomaly_events_pkey PRIMARY KEY (id);


--
-- Name: product_buybox_history product_buybox_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history
    ADD CONSTRAINT product_buybox_history_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2025_08 product_buybox_history_2025_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2025_08
    ADD CONSTRAINT product_buybox_history_2025_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2025_09 product_buybox_history_2025_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2025_09
    ADD CONSTRAINT product_buybox_history_2025_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2025_10 product_buybox_history_2025_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2025_10
    ADD CONSTRAINT product_buybox_history_2025_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2025_11 product_buybox_history_2025_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2025_11
    ADD CONSTRAINT product_buybox_history_2025_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2025_12 product_buybox_history_2025_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2025_12
    ADD CONSTRAINT product_buybox_history_2025_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_01 product_buybox_history_2026_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_01
    ADD CONSTRAINT product_buybox_history_2026_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_02 product_buybox_history_2026_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_02
    ADD CONSTRAINT product_buybox_history_2026_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_03 product_buybox_history_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_03
    ADD CONSTRAINT product_buybox_history_2026_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_04 product_buybox_history_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_04
    ADD CONSTRAINT product_buybox_history_2026_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_05 product_buybox_history_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_05
    ADD CONSTRAINT product_buybox_history_2026_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_06 product_buybox_history_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_06
    ADD CONSTRAINT product_buybox_history_2026_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_07 product_buybox_history_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_07
    ADD CONSTRAINT product_buybox_history_2026_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_buybox_history_2026_08 product_buybox_history_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_buybox_history_2026_08
    ADD CONSTRAINT product_buybox_history_2026_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history product_price_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history
    ADD CONSTRAINT product_price_history_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2025_08 product_price_history_2025_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2025_08
    ADD CONSTRAINT product_price_history_2025_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2025_09 product_price_history_2025_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2025_09
    ADD CONSTRAINT product_price_history_2025_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2025_10 product_price_history_2025_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2025_10
    ADD CONSTRAINT product_price_history_2025_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2025_11 product_price_history_2025_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2025_11
    ADD CONSTRAINT product_price_history_2025_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2025_12 product_price_history_2025_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2025_12
    ADD CONSTRAINT product_price_history_2025_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_01 product_price_history_2026_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_01
    ADD CONSTRAINT product_price_history_2026_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_02 product_price_history_2026_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_02
    ADD CONSTRAINT product_price_history_2026_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_03 product_price_history_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_03
    ADD CONSTRAINT product_price_history_2026_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_04 product_price_history_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_04
    ADD CONSTRAINT product_price_history_2026_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_05 product_price_history_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_05
    ADD CONSTRAINT product_price_history_2026_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_06 product_price_history_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_06
    ADD CONSTRAINT product_price_history_2026_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_07 product_price_history_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_07
    ADD CONSTRAINT product_price_history_2026_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_price_history_2026_08 product_price_history_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_price_history_2026_08
    ADD CONSTRAINT product_price_history_2026_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history product_ranking_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history
    ADD CONSTRAINT product_ranking_history_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2025_08 product_ranking_history_2025_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2025_08
    ADD CONSTRAINT product_ranking_history_2025_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2025_09 product_ranking_history_2025_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2025_09
    ADD CONSTRAINT product_ranking_history_2025_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2025_10 product_ranking_history_2025_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2025_10
    ADD CONSTRAINT product_ranking_history_2025_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2025_11 product_ranking_history_2025_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2025_11
    ADD CONSTRAINT product_ranking_history_2025_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2025_12 product_ranking_history_2025_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2025_12
    ADD CONSTRAINT product_ranking_history_2025_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_01 product_ranking_history_2026_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_01
    ADD CONSTRAINT product_ranking_history_2026_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_02 product_ranking_history_2026_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_02
    ADD CONSTRAINT product_ranking_history_2026_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_03 product_ranking_history_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_03
    ADD CONSTRAINT product_ranking_history_2026_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_04 product_ranking_history_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_04
    ADD CONSTRAINT product_ranking_history_2026_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_05 product_ranking_history_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_05
    ADD CONSTRAINT product_ranking_history_2026_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_06 product_ranking_history_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_06
    ADD CONSTRAINT product_ranking_history_2026_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_07 product_ranking_history_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_07
    ADD CONSTRAINT product_ranking_history_2026_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_ranking_history_2026_08 product_ranking_history_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_ranking_history_2026_08
    ADD CONSTRAINT product_ranking_history_2026_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history product_review_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history
    ADD CONSTRAINT product_review_history_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2025_08 product_review_history_2025_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2025_08
    ADD CONSTRAINT product_review_history_2025_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2025_09 product_review_history_2025_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2025_09
    ADD CONSTRAINT product_review_history_2025_09_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2025_10 product_review_history_2025_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2025_10
    ADD CONSTRAINT product_review_history_2025_10_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2025_11 product_review_history_2025_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2025_11
    ADD CONSTRAINT product_review_history_2025_11_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2025_12 product_review_history_2025_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2025_12
    ADD CONSTRAINT product_review_history_2025_12_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_01 product_review_history_2026_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_01
    ADD CONSTRAINT product_review_history_2026_01_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_02 product_review_history_2026_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_02
    ADD CONSTRAINT product_review_history_2026_02_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_03 product_review_history_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_03
    ADD CONSTRAINT product_review_history_2026_03_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_04 product_review_history_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_04
    ADD CONSTRAINT product_review_history_2026_04_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_05 product_review_history_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_05
    ADD CONSTRAINT product_review_history_2026_05_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_06 product_review_history_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_06
    ADD CONSTRAINT product_review_history_2026_06_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_07 product_review_history_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_07
    ADD CONSTRAINT product_review_history_2026_07_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: product_review_history_2026_08 product_review_history_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_review_history_2026_08
    ADD CONSTRAINT product_review_history_2026_08_pkey PRIMARY KEY (id, recorded_at);


--
-- Name: products products_asin_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_asin_key UNIQUE (asin);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: tracked_products tracked_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracked_products
    ADD CONSTRAINT tracked_products_pkey PRIMARY KEY (id);


--
-- Name: tracked_products tracked_products_user_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracked_products
    ADD CONSTRAINT tracked_products_user_product_unique UNIQUE (user_id, product_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_buybox_history_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_buybox_history_price ON ONLY public.product_buybox_history USING btree (winner_price);


--
-- Name: idx_buybox_history_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_buybox_history_product_id ON ONLY public.product_buybox_history USING btree (product_id);


--
-- Name: idx_buybox_history_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_buybox_history_recorded_at ON ONLY public.product_buybox_history USING btree (recorded_at);


--
-- Name: idx_buybox_history_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_buybox_history_seller ON ONLY public.product_buybox_history USING btree (winner_seller);


--
-- Name: idx_competitor_analysis_results_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_analysis_results_group_id ON public.competitor_analysis_results USING btree (analysis_group_id);


--
-- Name: idx_competitor_analysis_results_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_analysis_results_started_at ON public.competitor_analysis_results USING btree (started_at);


--
-- Name: idx_competitor_analysis_results_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_analysis_results_status ON public.competitor_analysis_results USING btree (status);


--
-- Name: idx_competitor_groups_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_groups_is_active ON public.competitor_analysis_groups USING btree (is_active);


--
-- Name: idx_competitor_groups_last_analysis_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_groups_last_analysis_at ON public.competitor_analysis_groups USING btree (last_analysis_at);


--
-- Name: idx_competitor_groups_main_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_groups_main_product_id ON public.competitor_analysis_groups USING btree (main_product_id);


--
-- Name: idx_competitor_groups_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_groups_user_id ON public.competitor_analysis_groups USING btree (user_id);


--
-- Name: idx_competitor_products_analysis_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_products_analysis_group_id ON public.competitor_products USING btree (analysis_group_id);


--
-- Name: idx_competitor_products_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_products_product_id ON public.competitor_products USING btree (product_id);


--
-- Name: idx_optimization_analyses_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_analyses_product_id ON public.optimization_analyses USING btree (product_id);


--
-- Name: idx_optimization_analyses_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_analyses_started_at ON public.optimization_analyses USING btree (started_at);


--
-- Name: idx_optimization_analyses_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_analyses_status ON public.optimization_analyses USING btree (status);


--
-- Name: idx_optimization_analyses_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_analyses_user_id ON public.optimization_analyses USING btree (user_id);


--
-- Name: idx_optimization_suggestions_analysis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_suggestions_analysis_id ON public.optimization_suggestions USING btree (analysis_id);


--
-- Name: idx_optimization_suggestions_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_suggestions_category ON public.optimization_suggestions USING btree (category);


--
-- Name: idx_optimization_suggestions_impact_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_suggestions_impact_score ON public.optimization_suggestions USING btree (impact_score);


--
-- Name: idx_optimization_suggestions_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_optimization_suggestions_priority ON public.optimization_suggestions USING btree (priority);


--
-- Name: idx_product_anomaly_events_asin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_anomaly_events_asin ON public.product_anomaly_events USING btree (asin);


--
-- Name: idx_product_anomaly_events_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_anomaly_events_created ON public.product_anomaly_events USING btree (created_at DESC);


--
-- Name: idx_product_anomaly_events_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_anomaly_events_event_type ON public.product_anomaly_events USING btree (event_type);


--
-- Name: idx_product_anomaly_events_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_anomaly_events_product_id ON public.product_anomaly_events USING btree (product_id);


--
-- Name: idx_product_anomaly_events_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_anomaly_events_severity ON public.product_anomaly_events USING btree (severity);


--
-- Name: idx_product_buybox_history_2025_08_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_08_price ON public.product_buybox_history_2025_08 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2025_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_08_product_id ON public.product_buybox_history_2025_08 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2025_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_08_recorded_at ON public.product_buybox_history_2025_08 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2025_08_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_08_seller ON public.product_buybox_history_2025_08 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2025_09_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_09_price ON public.product_buybox_history_2025_09 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2025_09_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_09_product_id ON public.product_buybox_history_2025_09 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2025_09_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_09_recorded_at ON public.product_buybox_history_2025_09 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2025_09_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_09_seller ON public.product_buybox_history_2025_09 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2025_10_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_10_price ON public.product_buybox_history_2025_10 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2025_10_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_10_product_id ON public.product_buybox_history_2025_10 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2025_10_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_10_recorded_at ON public.product_buybox_history_2025_10 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2025_10_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_10_seller ON public.product_buybox_history_2025_10 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2025_11_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_11_price ON public.product_buybox_history_2025_11 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2025_11_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_11_product_id ON public.product_buybox_history_2025_11 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2025_11_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_11_recorded_at ON public.product_buybox_history_2025_11 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2025_11_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_11_seller ON public.product_buybox_history_2025_11 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2025_12_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_12_price ON public.product_buybox_history_2025_12 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2025_12_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_12_product_id ON public.product_buybox_history_2025_12 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2025_12_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_12_recorded_at ON public.product_buybox_history_2025_12 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2025_12_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2025_12_seller ON public.product_buybox_history_2025_12 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_01_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_01_price ON public.product_buybox_history_2026_01 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_01_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_01_product_id ON public.product_buybox_history_2026_01 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_01_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_01_recorded_at ON public.product_buybox_history_2026_01 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_01_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_01_seller ON public.product_buybox_history_2026_01 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_02_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_02_price ON public.product_buybox_history_2026_02 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_02_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_02_product_id ON public.product_buybox_history_2026_02 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_02_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_02_recorded_at ON public.product_buybox_history_2026_02 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_02_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_02_seller ON public.product_buybox_history_2026_02 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_03_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_03_price ON public.product_buybox_history_2026_03 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_03_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_03_product_id ON public.product_buybox_history_2026_03 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_03_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_03_recorded_at ON public.product_buybox_history_2026_03 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_03_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_03_seller ON public.product_buybox_history_2026_03 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_04_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_04_price ON public.product_buybox_history_2026_04 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_04_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_04_product_id ON public.product_buybox_history_2026_04 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_04_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_04_recorded_at ON public.product_buybox_history_2026_04 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_04_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_04_seller ON public.product_buybox_history_2026_04 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_05_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_05_price ON public.product_buybox_history_2026_05 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_05_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_05_product_id ON public.product_buybox_history_2026_05 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_05_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_05_recorded_at ON public.product_buybox_history_2026_05 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_05_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_05_seller ON public.product_buybox_history_2026_05 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_06_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_06_price ON public.product_buybox_history_2026_06 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_06_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_06_product_id ON public.product_buybox_history_2026_06 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_06_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_06_recorded_at ON public.product_buybox_history_2026_06 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_06_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_06_seller ON public.product_buybox_history_2026_06 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_07_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_07_price ON public.product_buybox_history_2026_07 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_07_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_07_product_id ON public.product_buybox_history_2026_07 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_07_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_07_recorded_at ON public.product_buybox_history_2026_07 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_07_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_07_seller ON public.product_buybox_history_2026_07 USING btree (winner_seller);


--
-- Name: idx_product_buybox_history_2026_08_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_08_price ON public.product_buybox_history_2026_08 USING btree (winner_price);


--
-- Name: idx_product_buybox_history_2026_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_08_product_id ON public.product_buybox_history_2026_08 USING btree (product_id);


--
-- Name: idx_product_buybox_history_2026_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_08_recorded_at ON public.product_buybox_history_2026_08 USING btree (recorded_at);


--
-- Name: idx_product_buybox_history_2026_08_seller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_buybox_history_2026_08_seller ON public.product_buybox_history_2026_08 USING btree (winner_seller);


--
-- Name: idx_product_price_history_2025_08_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_08_price ON public.product_price_history_2025_08 USING btree (price);


--
-- Name: idx_product_price_history_2025_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_08_product_id ON public.product_price_history_2025_08 USING btree (product_id);


--
-- Name: idx_product_price_history_2025_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_08_recorded_at ON public.product_price_history_2025_08 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2025_09_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_09_price ON public.product_price_history_2025_09 USING btree (price);


--
-- Name: idx_product_price_history_2025_09_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_09_product_id ON public.product_price_history_2025_09 USING btree (product_id);


--
-- Name: idx_product_price_history_2025_09_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_09_recorded_at ON public.product_price_history_2025_09 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2025_10_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_10_price ON public.product_price_history_2025_10 USING btree (price);


--
-- Name: idx_product_price_history_2025_10_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_10_product_id ON public.product_price_history_2025_10 USING btree (product_id);


--
-- Name: idx_product_price_history_2025_10_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_10_recorded_at ON public.product_price_history_2025_10 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2025_11_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_11_price ON public.product_price_history_2025_11 USING btree (price);


--
-- Name: idx_product_price_history_2025_11_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_11_product_id ON public.product_price_history_2025_11 USING btree (product_id);


--
-- Name: idx_product_price_history_2025_11_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_11_recorded_at ON public.product_price_history_2025_11 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2025_12_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_12_price ON public.product_price_history_2025_12 USING btree (price);


--
-- Name: idx_product_price_history_2025_12_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_12_product_id ON public.product_price_history_2025_12 USING btree (product_id);


--
-- Name: idx_product_price_history_2025_12_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2025_12_recorded_at ON public.product_price_history_2025_12 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_01_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_01_price ON public.product_price_history_2026_01 USING btree (price);


--
-- Name: idx_product_price_history_2026_01_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_01_product_id ON public.product_price_history_2026_01 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_01_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_01_recorded_at ON public.product_price_history_2026_01 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_02_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_02_price ON public.product_price_history_2026_02 USING btree (price);


--
-- Name: idx_product_price_history_2026_02_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_02_product_id ON public.product_price_history_2026_02 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_02_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_02_recorded_at ON public.product_price_history_2026_02 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_03_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_03_price ON public.product_price_history_2026_03 USING btree (price);


--
-- Name: idx_product_price_history_2026_03_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_03_product_id ON public.product_price_history_2026_03 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_03_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_03_recorded_at ON public.product_price_history_2026_03 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_04_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_04_price ON public.product_price_history_2026_04 USING btree (price);


--
-- Name: idx_product_price_history_2026_04_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_04_product_id ON public.product_price_history_2026_04 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_04_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_04_recorded_at ON public.product_price_history_2026_04 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_05_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_05_price ON public.product_price_history_2026_05 USING btree (price);


--
-- Name: idx_product_price_history_2026_05_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_05_product_id ON public.product_price_history_2026_05 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_05_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_05_recorded_at ON public.product_price_history_2026_05 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_06_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_06_price ON public.product_price_history_2026_06 USING btree (price);


--
-- Name: idx_product_price_history_2026_06_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_06_product_id ON public.product_price_history_2026_06 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_06_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_06_recorded_at ON public.product_price_history_2026_06 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_07_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_07_price ON public.product_price_history_2026_07 USING btree (price);


--
-- Name: idx_product_price_history_2026_07_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_07_product_id ON public.product_price_history_2026_07 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_07_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_07_recorded_at ON public.product_price_history_2026_07 USING btree (recorded_at);


--
-- Name: idx_product_price_history_2026_08_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_08_price ON public.product_price_history_2026_08 USING btree (price);


--
-- Name: idx_product_price_history_2026_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_08_product_id ON public.product_price_history_2026_08 USING btree (product_id);


--
-- Name: idx_product_price_history_2026_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_2026_08_recorded_at ON public.product_price_history_2026_08 USING btree (recorded_at);


--
-- Name: idx_product_price_history_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_price ON ONLY public.product_price_history USING btree (price);


--
-- Name: idx_product_price_history_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_product_id ON ONLY public.product_price_history USING btree (product_id);


--
-- Name: idx_product_price_history_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_price_history_recorded_at ON ONLY public.product_price_history USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2025_08_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_08_bsr_rank ON public.product_ranking_history_2025_08 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2025_08_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_08_category ON public.product_ranking_history_2025_08 USING btree (category);


--
-- Name: idx_product_ranking_history_2025_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_08_product_id ON public.product_ranking_history_2025_08 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2025_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_08_recorded_at ON public.product_ranking_history_2025_08 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2025_09_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_09_bsr_rank ON public.product_ranking_history_2025_09 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2025_09_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_09_category ON public.product_ranking_history_2025_09 USING btree (category);


--
-- Name: idx_product_ranking_history_2025_09_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_09_product_id ON public.product_ranking_history_2025_09 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2025_09_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_09_recorded_at ON public.product_ranking_history_2025_09 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2025_10_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_10_bsr_rank ON public.product_ranking_history_2025_10 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2025_10_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_10_category ON public.product_ranking_history_2025_10 USING btree (category);


--
-- Name: idx_product_ranking_history_2025_10_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_10_product_id ON public.product_ranking_history_2025_10 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2025_10_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_10_recorded_at ON public.product_ranking_history_2025_10 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2025_11_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_11_bsr_rank ON public.product_ranking_history_2025_11 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2025_11_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_11_category ON public.product_ranking_history_2025_11 USING btree (category);


--
-- Name: idx_product_ranking_history_2025_11_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_11_product_id ON public.product_ranking_history_2025_11 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2025_11_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_11_recorded_at ON public.product_ranking_history_2025_11 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2025_12_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_12_bsr_rank ON public.product_ranking_history_2025_12 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2025_12_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_12_category ON public.product_ranking_history_2025_12 USING btree (category);


--
-- Name: idx_product_ranking_history_2025_12_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_12_product_id ON public.product_ranking_history_2025_12 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2025_12_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2025_12_recorded_at ON public.product_ranking_history_2025_12 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_01_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_01_bsr_rank ON public.product_ranking_history_2026_01 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_01_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_01_category ON public.product_ranking_history_2026_01 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_01_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_01_product_id ON public.product_ranking_history_2026_01 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_01_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_01_recorded_at ON public.product_ranking_history_2026_01 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_02_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_02_bsr_rank ON public.product_ranking_history_2026_02 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_02_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_02_category ON public.product_ranking_history_2026_02 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_02_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_02_product_id ON public.product_ranking_history_2026_02 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_02_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_02_recorded_at ON public.product_ranking_history_2026_02 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_03_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_03_bsr_rank ON public.product_ranking_history_2026_03 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_03_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_03_category ON public.product_ranking_history_2026_03 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_03_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_03_product_id ON public.product_ranking_history_2026_03 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_03_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_03_recorded_at ON public.product_ranking_history_2026_03 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_04_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_04_bsr_rank ON public.product_ranking_history_2026_04 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_04_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_04_category ON public.product_ranking_history_2026_04 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_04_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_04_product_id ON public.product_ranking_history_2026_04 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_04_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_04_recorded_at ON public.product_ranking_history_2026_04 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_05_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_05_bsr_rank ON public.product_ranking_history_2026_05 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_05_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_05_category ON public.product_ranking_history_2026_05 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_05_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_05_product_id ON public.product_ranking_history_2026_05 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_05_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_05_recorded_at ON public.product_ranking_history_2026_05 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_06_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_06_bsr_rank ON public.product_ranking_history_2026_06 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_06_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_06_category ON public.product_ranking_history_2026_06 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_06_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_06_product_id ON public.product_ranking_history_2026_06 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_06_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_06_recorded_at ON public.product_ranking_history_2026_06 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_07_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_07_bsr_rank ON public.product_ranking_history_2026_07 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_07_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_07_category ON public.product_ranking_history_2026_07 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_07_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_07_product_id ON public.product_ranking_history_2026_07 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_07_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_07_recorded_at ON public.product_ranking_history_2026_07 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_2026_08_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_08_bsr_rank ON public.product_ranking_history_2026_08 USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_2026_08_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_08_category ON public.product_ranking_history_2026_08 USING btree (category);


--
-- Name: idx_product_ranking_history_2026_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_08_product_id ON public.product_ranking_history_2026_08 USING btree (product_id);


--
-- Name: idx_product_ranking_history_2026_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_2026_08_recorded_at ON public.product_ranking_history_2026_08 USING btree (recorded_at);


--
-- Name: idx_product_ranking_history_bsr_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_bsr_rank ON ONLY public.product_ranking_history USING btree (bsr_rank);


--
-- Name: idx_product_ranking_history_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_category ON ONLY public.product_ranking_history USING btree (category);


--
-- Name: idx_product_ranking_history_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_product_id ON ONLY public.product_ranking_history USING btree (product_id);


--
-- Name: idx_product_ranking_history_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_ranking_history_recorded_at ON ONLY public.product_ranking_history USING btree (recorded_at);


--
-- Name: idx_product_review_history_2025_08_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_08_avg_rating ON public.product_review_history_2025_08 USING btree (average_rating);


--
-- Name: idx_product_review_history_2025_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_08_product_id ON public.product_review_history_2025_08 USING btree (product_id);


--
-- Name: idx_product_review_history_2025_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_08_recorded_at ON public.product_review_history_2025_08 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2025_09_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_09_avg_rating ON public.product_review_history_2025_09 USING btree (average_rating);


--
-- Name: idx_product_review_history_2025_09_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_09_product_id ON public.product_review_history_2025_09 USING btree (product_id);


--
-- Name: idx_product_review_history_2025_09_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_09_recorded_at ON public.product_review_history_2025_09 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2025_10_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_10_avg_rating ON public.product_review_history_2025_10 USING btree (average_rating);


--
-- Name: idx_product_review_history_2025_10_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_10_product_id ON public.product_review_history_2025_10 USING btree (product_id);


--
-- Name: idx_product_review_history_2025_10_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_10_recorded_at ON public.product_review_history_2025_10 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2025_11_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_11_avg_rating ON public.product_review_history_2025_11 USING btree (average_rating);


--
-- Name: idx_product_review_history_2025_11_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_11_product_id ON public.product_review_history_2025_11 USING btree (product_id);


--
-- Name: idx_product_review_history_2025_11_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_11_recorded_at ON public.product_review_history_2025_11 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2025_12_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_12_avg_rating ON public.product_review_history_2025_12 USING btree (average_rating);


--
-- Name: idx_product_review_history_2025_12_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_12_product_id ON public.product_review_history_2025_12 USING btree (product_id);


--
-- Name: idx_product_review_history_2025_12_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2025_12_recorded_at ON public.product_review_history_2025_12 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_01_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_01_avg_rating ON public.product_review_history_2026_01 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_01_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_01_product_id ON public.product_review_history_2026_01 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_01_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_01_recorded_at ON public.product_review_history_2026_01 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_02_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_02_avg_rating ON public.product_review_history_2026_02 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_02_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_02_product_id ON public.product_review_history_2026_02 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_02_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_02_recorded_at ON public.product_review_history_2026_02 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_03_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_03_avg_rating ON public.product_review_history_2026_03 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_03_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_03_product_id ON public.product_review_history_2026_03 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_03_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_03_recorded_at ON public.product_review_history_2026_03 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_04_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_04_avg_rating ON public.product_review_history_2026_04 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_04_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_04_product_id ON public.product_review_history_2026_04 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_04_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_04_recorded_at ON public.product_review_history_2026_04 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_05_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_05_avg_rating ON public.product_review_history_2026_05 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_05_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_05_product_id ON public.product_review_history_2026_05 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_05_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_05_recorded_at ON public.product_review_history_2026_05 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_06_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_06_avg_rating ON public.product_review_history_2026_06 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_06_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_06_product_id ON public.product_review_history_2026_06 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_06_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_06_recorded_at ON public.product_review_history_2026_06 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_07_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_07_avg_rating ON public.product_review_history_2026_07 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_07_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_07_product_id ON public.product_review_history_2026_07 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_07_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_07_recorded_at ON public.product_review_history_2026_07 USING btree (recorded_at);


--
-- Name: idx_product_review_history_2026_08_avg_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_08_avg_rating ON public.product_review_history_2026_08 USING btree (average_rating);


--
-- Name: idx_product_review_history_2026_08_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_08_product_id ON public.product_review_history_2026_08 USING btree (product_id);


--
-- Name: idx_product_review_history_2026_08_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_review_history_2026_08_recorded_at ON public.product_review_history_2026_08 USING btree (recorded_at);


--
-- Name: idx_products_asin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_asin ON public.products USING btree (asin);


--
-- Name: idx_products_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_brand ON public.products USING btree (brand);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_category ON public.products USING btree (category);


--
-- Name: idx_products_first_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_first_seen_at ON public.products USING btree (first_seen_at);


--
-- Name: idx_products_last_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_last_updated_at ON public.products USING btree (last_updated_at);


--
-- Name: idx_review_history_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_history_product_id ON ONLY public.product_review_history USING btree (product_id);


--
-- Name: idx_review_history_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_history_rating ON ONLY public.product_review_history USING btree (average_rating);


--
-- Name: idx_review_history_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_history_recorded_at ON ONLY public.product_review_history USING btree (recorded_at);


--
-- Name: idx_tracked_products_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tracked_products_is_active ON public.tracked_products USING btree (is_active);


--
-- Name: idx_tracked_products_next_check_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tracked_products_next_check_at ON public.tracked_products USING btree (next_check_at);


--
-- Name: idx_tracked_products_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tracked_products_product_id ON public.tracked_products USING btree (product_id);


--
-- Name: idx_tracked_products_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tracked_products_user_id ON public.tracked_products USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_plan_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_plan_type ON public.users USING btree (plan_type);


--
-- Name: product_buybox_history_2025_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_08_product_id_idx ON public.product_buybox_history_2025_08 USING btree (product_id);


--
-- Name: product_buybox_history_2025_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_08_recorded_at_idx ON public.product_buybox_history_2025_08 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_08_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_08_winner_price_idx ON public.product_buybox_history_2025_08 USING btree (winner_price);


--
-- Name: product_buybox_history_2025_08_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_08_winner_seller_idx ON public.product_buybox_history_2025_08 USING btree (winner_seller);


--
-- Name: product_buybox_history_2025_09_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_09_product_id_idx ON public.product_buybox_history_2025_09 USING btree (product_id);


--
-- Name: product_buybox_history_2025_09_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_09_recorded_at_idx ON public.product_buybox_history_2025_09 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_09_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_09_winner_price_idx ON public.product_buybox_history_2025_09 USING btree (winner_price);


--
-- Name: product_buybox_history_2025_09_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_09_winner_seller_idx ON public.product_buybox_history_2025_09 USING btree (winner_seller);


--
-- Name: product_buybox_history_2025_10_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_10_product_id_idx ON public.product_buybox_history_2025_10 USING btree (product_id);


--
-- Name: product_buybox_history_2025_10_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_10_recorded_at_idx ON public.product_buybox_history_2025_10 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_10_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_10_winner_price_idx ON public.product_buybox_history_2025_10 USING btree (winner_price);


--
-- Name: product_buybox_history_2025_10_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_10_winner_seller_idx ON public.product_buybox_history_2025_10 USING btree (winner_seller);


--
-- Name: product_buybox_history_2025_11_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_11_product_id_idx ON public.product_buybox_history_2025_11 USING btree (product_id);


--
-- Name: product_buybox_history_2025_11_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_11_recorded_at_idx ON public.product_buybox_history_2025_11 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_11_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_11_winner_price_idx ON public.product_buybox_history_2025_11 USING btree (winner_price);


--
-- Name: product_buybox_history_2025_11_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_11_winner_seller_idx ON public.product_buybox_history_2025_11 USING btree (winner_seller);


--
-- Name: product_buybox_history_2025_12_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_12_product_id_idx ON public.product_buybox_history_2025_12 USING btree (product_id);


--
-- Name: product_buybox_history_2025_12_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_12_recorded_at_idx ON public.product_buybox_history_2025_12 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_12_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_12_winner_price_idx ON public.product_buybox_history_2025_12 USING btree (winner_price);


--
-- Name: product_buybox_history_2025_12_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2025_12_winner_seller_idx ON public.product_buybox_history_2025_12 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_01_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_01_product_id_idx ON public.product_buybox_history_2026_01 USING btree (product_id);


--
-- Name: product_buybox_history_2026_01_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_01_recorded_at_idx ON public.product_buybox_history_2026_01 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_01_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_01_winner_price_idx ON public.product_buybox_history_2026_01 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_01_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_01_winner_seller_idx ON public.product_buybox_history_2026_01 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_02_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_02_product_id_idx ON public.product_buybox_history_2026_02 USING btree (product_id);


--
-- Name: product_buybox_history_2026_02_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_02_recorded_at_idx ON public.product_buybox_history_2026_02 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_02_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_02_winner_price_idx ON public.product_buybox_history_2026_02 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_02_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_02_winner_seller_idx ON public.product_buybox_history_2026_02 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_03_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_03_product_id_idx ON public.product_buybox_history_2026_03 USING btree (product_id);


--
-- Name: product_buybox_history_2026_03_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_03_recorded_at_idx ON public.product_buybox_history_2026_03 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_03_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_03_winner_price_idx ON public.product_buybox_history_2026_03 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_03_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_03_winner_seller_idx ON public.product_buybox_history_2026_03 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_04_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_04_product_id_idx ON public.product_buybox_history_2026_04 USING btree (product_id);


--
-- Name: product_buybox_history_2026_04_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_04_recorded_at_idx ON public.product_buybox_history_2026_04 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_04_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_04_winner_price_idx ON public.product_buybox_history_2026_04 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_04_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_04_winner_seller_idx ON public.product_buybox_history_2026_04 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_05_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_05_product_id_idx ON public.product_buybox_history_2026_05 USING btree (product_id);


--
-- Name: product_buybox_history_2026_05_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_05_recorded_at_idx ON public.product_buybox_history_2026_05 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_05_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_05_winner_price_idx ON public.product_buybox_history_2026_05 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_05_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_05_winner_seller_idx ON public.product_buybox_history_2026_05 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_06_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_06_product_id_idx ON public.product_buybox_history_2026_06 USING btree (product_id);


--
-- Name: product_buybox_history_2026_06_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_06_recorded_at_idx ON public.product_buybox_history_2026_06 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_06_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_06_winner_price_idx ON public.product_buybox_history_2026_06 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_06_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_06_winner_seller_idx ON public.product_buybox_history_2026_06 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_07_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_07_product_id_idx ON public.product_buybox_history_2026_07 USING btree (product_id);


--
-- Name: product_buybox_history_2026_07_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_07_recorded_at_idx ON public.product_buybox_history_2026_07 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_07_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_07_winner_price_idx ON public.product_buybox_history_2026_07 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_07_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_07_winner_seller_idx ON public.product_buybox_history_2026_07 USING btree (winner_seller);


--
-- Name: product_buybox_history_2026_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_08_product_id_idx ON public.product_buybox_history_2026_08 USING btree (product_id);


--
-- Name: product_buybox_history_2026_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_08_recorded_at_idx ON public.product_buybox_history_2026_08 USING btree (recorded_at);


--
-- Name: product_buybox_history_2026_08_winner_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_08_winner_price_idx ON public.product_buybox_history_2026_08 USING btree (winner_price);


--
-- Name: product_buybox_history_2026_08_winner_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_buybox_history_2026_08_winner_seller_idx ON public.product_buybox_history_2026_08 USING btree (winner_seller);


--
-- Name: product_price_history_2025_08_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_08_price_idx ON public.product_price_history_2025_08 USING btree (price);


--
-- Name: product_price_history_2025_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_08_product_id_idx ON public.product_price_history_2025_08 USING btree (product_id);


--
-- Name: product_price_history_2025_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_08_recorded_at_idx ON public.product_price_history_2025_08 USING btree (recorded_at);


--
-- Name: product_price_history_2025_09_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_09_price_idx ON public.product_price_history_2025_09 USING btree (price);


--
-- Name: product_price_history_2025_09_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_09_product_id_idx ON public.product_price_history_2025_09 USING btree (product_id);


--
-- Name: product_price_history_2025_09_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_09_recorded_at_idx ON public.product_price_history_2025_09 USING btree (recorded_at);


--
-- Name: product_price_history_2025_10_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_10_price_idx ON public.product_price_history_2025_10 USING btree (price);


--
-- Name: product_price_history_2025_10_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_10_product_id_idx ON public.product_price_history_2025_10 USING btree (product_id);


--
-- Name: product_price_history_2025_10_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_10_recorded_at_idx ON public.product_price_history_2025_10 USING btree (recorded_at);


--
-- Name: product_price_history_2025_11_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_11_price_idx ON public.product_price_history_2025_11 USING btree (price);


--
-- Name: product_price_history_2025_11_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_11_product_id_idx ON public.product_price_history_2025_11 USING btree (product_id);


--
-- Name: product_price_history_2025_11_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_11_recorded_at_idx ON public.product_price_history_2025_11 USING btree (recorded_at);


--
-- Name: product_price_history_2025_12_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_12_price_idx ON public.product_price_history_2025_12 USING btree (price);


--
-- Name: product_price_history_2025_12_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_12_product_id_idx ON public.product_price_history_2025_12 USING btree (product_id);


--
-- Name: product_price_history_2025_12_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2025_12_recorded_at_idx ON public.product_price_history_2025_12 USING btree (recorded_at);


--
-- Name: product_price_history_2026_01_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_01_price_idx ON public.product_price_history_2026_01 USING btree (price);


--
-- Name: product_price_history_2026_01_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_01_product_id_idx ON public.product_price_history_2026_01 USING btree (product_id);


--
-- Name: product_price_history_2026_01_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_01_recorded_at_idx ON public.product_price_history_2026_01 USING btree (recorded_at);


--
-- Name: product_price_history_2026_02_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_02_price_idx ON public.product_price_history_2026_02 USING btree (price);


--
-- Name: product_price_history_2026_02_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_02_product_id_idx ON public.product_price_history_2026_02 USING btree (product_id);


--
-- Name: product_price_history_2026_02_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_02_recorded_at_idx ON public.product_price_history_2026_02 USING btree (recorded_at);


--
-- Name: product_price_history_2026_03_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_03_price_idx ON public.product_price_history_2026_03 USING btree (price);


--
-- Name: product_price_history_2026_03_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_03_product_id_idx ON public.product_price_history_2026_03 USING btree (product_id);


--
-- Name: product_price_history_2026_03_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_03_recorded_at_idx ON public.product_price_history_2026_03 USING btree (recorded_at);


--
-- Name: product_price_history_2026_04_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_04_price_idx ON public.product_price_history_2026_04 USING btree (price);


--
-- Name: product_price_history_2026_04_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_04_product_id_idx ON public.product_price_history_2026_04 USING btree (product_id);


--
-- Name: product_price_history_2026_04_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_04_recorded_at_idx ON public.product_price_history_2026_04 USING btree (recorded_at);


--
-- Name: product_price_history_2026_05_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_05_price_idx ON public.product_price_history_2026_05 USING btree (price);


--
-- Name: product_price_history_2026_05_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_05_product_id_idx ON public.product_price_history_2026_05 USING btree (product_id);


--
-- Name: product_price_history_2026_05_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_05_recorded_at_idx ON public.product_price_history_2026_05 USING btree (recorded_at);


--
-- Name: product_price_history_2026_06_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_06_price_idx ON public.product_price_history_2026_06 USING btree (price);


--
-- Name: product_price_history_2026_06_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_06_product_id_idx ON public.product_price_history_2026_06 USING btree (product_id);


--
-- Name: product_price_history_2026_06_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_06_recorded_at_idx ON public.product_price_history_2026_06 USING btree (recorded_at);


--
-- Name: product_price_history_2026_07_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_07_price_idx ON public.product_price_history_2026_07 USING btree (price);


--
-- Name: product_price_history_2026_07_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_07_product_id_idx ON public.product_price_history_2026_07 USING btree (product_id);


--
-- Name: product_price_history_2026_07_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_07_recorded_at_idx ON public.product_price_history_2026_07 USING btree (recorded_at);


--
-- Name: product_price_history_2026_08_price_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_08_price_idx ON public.product_price_history_2026_08 USING btree (price);


--
-- Name: product_price_history_2026_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_08_product_id_idx ON public.product_price_history_2026_08 USING btree (product_id);


--
-- Name: product_price_history_2026_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_price_history_2026_08_recorded_at_idx ON public.product_price_history_2026_08 USING btree (recorded_at);


--
-- Name: product_ranking_history_2025_08_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_08_bsr_rank_idx ON public.product_ranking_history_2025_08 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2025_08_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_08_category_idx ON public.product_ranking_history_2025_08 USING btree (category);


--
-- Name: product_ranking_history_2025_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_08_product_id_idx ON public.product_ranking_history_2025_08 USING btree (product_id);


--
-- Name: product_ranking_history_2025_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_08_recorded_at_idx ON public.product_ranking_history_2025_08 USING btree (recorded_at);


--
-- Name: product_ranking_history_2025_09_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_09_bsr_rank_idx ON public.product_ranking_history_2025_09 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2025_09_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_09_category_idx ON public.product_ranking_history_2025_09 USING btree (category);


--
-- Name: product_ranking_history_2025_09_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_09_product_id_idx ON public.product_ranking_history_2025_09 USING btree (product_id);


--
-- Name: product_ranking_history_2025_09_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_09_recorded_at_idx ON public.product_ranking_history_2025_09 USING btree (recorded_at);


--
-- Name: product_ranking_history_2025_10_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_10_bsr_rank_idx ON public.product_ranking_history_2025_10 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2025_10_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_10_category_idx ON public.product_ranking_history_2025_10 USING btree (category);


--
-- Name: product_ranking_history_2025_10_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_10_product_id_idx ON public.product_ranking_history_2025_10 USING btree (product_id);


--
-- Name: product_ranking_history_2025_10_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_10_recorded_at_idx ON public.product_ranking_history_2025_10 USING btree (recorded_at);


--
-- Name: product_ranking_history_2025_11_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_11_bsr_rank_idx ON public.product_ranking_history_2025_11 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2025_11_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_11_category_idx ON public.product_ranking_history_2025_11 USING btree (category);


--
-- Name: product_ranking_history_2025_11_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_11_product_id_idx ON public.product_ranking_history_2025_11 USING btree (product_id);


--
-- Name: product_ranking_history_2025_11_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_11_recorded_at_idx ON public.product_ranking_history_2025_11 USING btree (recorded_at);


--
-- Name: product_ranking_history_2025_12_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_12_bsr_rank_idx ON public.product_ranking_history_2025_12 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2025_12_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_12_category_idx ON public.product_ranking_history_2025_12 USING btree (category);


--
-- Name: product_ranking_history_2025_12_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_12_product_id_idx ON public.product_ranking_history_2025_12 USING btree (product_id);


--
-- Name: product_ranking_history_2025_12_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2025_12_recorded_at_idx ON public.product_ranking_history_2025_12 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_01_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_01_bsr_rank_idx ON public.product_ranking_history_2026_01 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_01_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_01_category_idx ON public.product_ranking_history_2026_01 USING btree (category);


--
-- Name: product_ranking_history_2026_01_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_01_product_id_idx ON public.product_ranking_history_2026_01 USING btree (product_id);


--
-- Name: product_ranking_history_2026_01_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_01_recorded_at_idx ON public.product_ranking_history_2026_01 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_02_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_02_bsr_rank_idx ON public.product_ranking_history_2026_02 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_02_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_02_category_idx ON public.product_ranking_history_2026_02 USING btree (category);


--
-- Name: product_ranking_history_2026_02_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_02_product_id_idx ON public.product_ranking_history_2026_02 USING btree (product_id);


--
-- Name: product_ranking_history_2026_02_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_02_recorded_at_idx ON public.product_ranking_history_2026_02 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_03_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_03_bsr_rank_idx ON public.product_ranking_history_2026_03 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_03_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_03_category_idx ON public.product_ranking_history_2026_03 USING btree (category);


--
-- Name: product_ranking_history_2026_03_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_03_product_id_idx ON public.product_ranking_history_2026_03 USING btree (product_id);


--
-- Name: product_ranking_history_2026_03_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_03_recorded_at_idx ON public.product_ranking_history_2026_03 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_04_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_04_bsr_rank_idx ON public.product_ranking_history_2026_04 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_04_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_04_category_idx ON public.product_ranking_history_2026_04 USING btree (category);


--
-- Name: product_ranking_history_2026_04_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_04_product_id_idx ON public.product_ranking_history_2026_04 USING btree (product_id);


--
-- Name: product_ranking_history_2026_04_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_04_recorded_at_idx ON public.product_ranking_history_2026_04 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_05_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_05_bsr_rank_idx ON public.product_ranking_history_2026_05 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_05_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_05_category_idx ON public.product_ranking_history_2026_05 USING btree (category);


--
-- Name: product_ranking_history_2026_05_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_05_product_id_idx ON public.product_ranking_history_2026_05 USING btree (product_id);


--
-- Name: product_ranking_history_2026_05_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_05_recorded_at_idx ON public.product_ranking_history_2026_05 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_06_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_06_bsr_rank_idx ON public.product_ranking_history_2026_06 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_06_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_06_category_idx ON public.product_ranking_history_2026_06 USING btree (category);


--
-- Name: product_ranking_history_2026_06_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_06_product_id_idx ON public.product_ranking_history_2026_06 USING btree (product_id);


--
-- Name: product_ranking_history_2026_06_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_06_recorded_at_idx ON public.product_ranking_history_2026_06 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_07_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_07_bsr_rank_idx ON public.product_ranking_history_2026_07 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_07_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_07_category_idx ON public.product_ranking_history_2026_07 USING btree (category);


--
-- Name: product_ranking_history_2026_07_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_07_product_id_idx ON public.product_ranking_history_2026_07 USING btree (product_id);


--
-- Name: product_ranking_history_2026_07_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_07_recorded_at_idx ON public.product_ranking_history_2026_07 USING btree (recorded_at);


--
-- Name: product_ranking_history_2026_08_bsr_rank_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_08_bsr_rank_idx ON public.product_ranking_history_2026_08 USING btree (bsr_rank);


--
-- Name: product_ranking_history_2026_08_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_08_category_idx ON public.product_ranking_history_2026_08 USING btree (category);


--
-- Name: product_ranking_history_2026_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_08_product_id_idx ON public.product_ranking_history_2026_08 USING btree (product_id);


--
-- Name: product_ranking_history_2026_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_ranking_history_2026_08_recorded_at_idx ON public.product_ranking_history_2026_08 USING btree (recorded_at);


--
-- Name: product_review_history_2025_08_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_08_average_rating_idx ON public.product_review_history_2025_08 USING btree (average_rating);


--
-- Name: product_review_history_2025_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_08_product_id_idx ON public.product_review_history_2025_08 USING btree (product_id);


--
-- Name: product_review_history_2025_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_08_recorded_at_idx ON public.product_review_history_2025_08 USING btree (recorded_at);


--
-- Name: product_review_history_2025_09_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_09_average_rating_idx ON public.product_review_history_2025_09 USING btree (average_rating);


--
-- Name: product_review_history_2025_09_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_09_product_id_idx ON public.product_review_history_2025_09 USING btree (product_id);


--
-- Name: product_review_history_2025_09_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_09_recorded_at_idx ON public.product_review_history_2025_09 USING btree (recorded_at);


--
-- Name: product_review_history_2025_10_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_10_average_rating_idx ON public.product_review_history_2025_10 USING btree (average_rating);


--
-- Name: product_review_history_2025_10_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_10_product_id_idx ON public.product_review_history_2025_10 USING btree (product_id);


--
-- Name: product_review_history_2025_10_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_10_recorded_at_idx ON public.product_review_history_2025_10 USING btree (recorded_at);


--
-- Name: product_review_history_2025_11_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_11_average_rating_idx ON public.product_review_history_2025_11 USING btree (average_rating);


--
-- Name: product_review_history_2025_11_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_11_product_id_idx ON public.product_review_history_2025_11 USING btree (product_id);


--
-- Name: product_review_history_2025_11_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_11_recorded_at_idx ON public.product_review_history_2025_11 USING btree (recorded_at);


--
-- Name: product_review_history_2025_12_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_12_average_rating_idx ON public.product_review_history_2025_12 USING btree (average_rating);


--
-- Name: product_review_history_2025_12_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_12_product_id_idx ON public.product_review_history_2025_12 USING btree (product_id);


--
-- Name: product_review_history_2025_12_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2025_12_recorded_at_idx ON public.product_review_history_2025_12 USING btree (recorded_at);


--
-- Name: product_review_history_2026_01_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_01_average_rating_idx ON public.product_review_history_2026_01 USING btree (average_rating);


--
-- Name: product_review_history_2026_01_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_01_product_id_idx ON public.product_review_history_2026_01 USING btree (product_id);


--
-- Name: product_review_history_2026_01_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_01_recorded_at_idx ON public.product_review_history_2026_01 USING btree (recorded_at);


--
-- Name: product_review_history_2026_02_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_02_average_rating_idx ON public.product_review_history_2026_02 USING btree (average_rating);


--
-- Name: product_review_history_2026_02_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_02_product_id_idx ON public.product_review_history_2026_02 USING btree (product_id);


--
-- Name: product_review_history_2026_02_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_02_recorded_at_idx ON public.product_review_history_2026_02 USING btree (recorded_at);


--
-- Name: product_review_history_2026_03_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_03_average_rating_idx ON public.product_review_history_2026_03 USING btree (average_rating);


--
-- Name: product_review_history_2026_03_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_03_product_id_idx ON public.product_review_history_2026_03 USING btree (product_id);


--
-- Name: product_review_history_2026_03_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_03_recorded_at_idx ON public.product_review_history_2026_03 USING btree (recorded_at);


--
-- Name: product_review_history_2026_04_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_04_average_rating_idx ON public.product_review_history_2026_04 USING btree (average_rating);


--
-- Name: product_review_history_2026_04_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_04_product_id_idx ON public.product_review_history_2026_04 USING btree (product_id);


--
-- Name: product_review_history_2026_04_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_04_recorded_at_idx ON public.product_review_history_2026_04 USING btree (recorded_at);


--
-- Name: product_review_history_2026_05_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_05_average_rating_idx ON public.product_review_history_2026_05 USING btree (average_rating);


--
-- Name: product_review_history_2026_05_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_05_product_id_idx ON public.product_review_history_2026_05 USING btree (product_id);


--
-- Name: product_review_history_2026_05_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_05_recorded_at_idx ON public.product_review_history_2026_05 USING btree (recorded_at);


--
-- Name: product_review_history_2026_06_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_06_average_rating_idx ON public.product_review_history_2026_06 USING btree (average_rating);


--
-- Name: product_review_history_2026_06_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_06_product_id_idx ON public.product_review_history_2026_06 USING btree (product_id);


--
-- Name: product_review_history_2026_06_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_06_recorded_at_idx ON public.product_review_history_2026_06 USING btree (recorded_at);


--
-- Name: product_review_history_2026_07_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_07_average_rating_idx ON public.product_review_history_2026_07 USING btree (average_rating);


--
-- Name: product_review_history_2026_07_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_07_product_id_idx ON public.product_review_history_2026_07 USING btree (product_id);


--
-- Name: product_review_history_2026_07_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_07_recorded_at_idx ON public.product_review_history_2026_07 USING btree (recorded_at);


--
-- Name: product_review_history_2026_08_average_rating_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_08_average_rating_idx ON public.product_review_history_2026_08 USING btree (average_rating);


--
-- Name: product_review_history_2026_08_product_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_08_product_id_idx ON public.product_review_history_2026_08 USING btree (product_id);


--
-- Name: product_review_history_2026_08_recorded_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_review_history_2026_08_recorded_at_idx ON public.product_review_history_2026_08 USING btree (recorded_at);


--
-- Name: product_buybox_history_2025_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2025_08_pkey;


--
-- Name: product_buybox_history_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2025_08_product_id_idx;


--
-- Name: product_buybox_history_2025_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2025_08_recorded_at_idx;


--
-- Name: product_buybox_history_2025_08_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2025_08_winner_price_idx;


--
-- Name: product_buybox_history_2025_08_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2025_08_winner_seller_idx;


--
-- Name: product_buybox_history_2025_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2025_09_pkey;


--
-- Name: product_buybox_history_2025_09_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2025_09_product_id_idx;


--
-- Name: product_buybox_history_2025_09_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2025_09_recorded_at_idx;


--
-- Name: product_buybox_history_2025_09_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2025_09_winner_price_idx;


--
-- Name: product_buybox_history_2025_09_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2025_09_winner_seller_idx;


--
-- Name: product_buybox_history_2025_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2025_10_pkey;


--
-- Name: product_buybox_history_2025_10_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2025_10_product_id_idx;


--
-- Name: product_buybox_history_2025_10_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2025_10_recorded_at_idx;


--
-- Name: product_buybox_history_2025_10_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2025_10_winner_price_idx;


--
-- Name: product_buybox_history_2025_10_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2025_10_winner_seller_idx;


--
-- Name: product_buybox_history_2025_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2025_11_pkey;


--
-- Name: product_buybox_history_2025_11_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2025_11_product_id_idx;


--
-- Name: product_buybox_history_2025_11_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2025_11_recorded_at_idx;


--
-- Name: product_buybox_history_2025_11_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2025_11_winner_price_idx;


--
-- Name: product_buybox_history_2025_11_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2025_11_winner_seller_idx;


--
-- Name: product_buybox_history_2025_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2025_12_pkey;


--
-- Name: product_buybox_history_2025_12_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2025_12_product_id_idx;


--
-- Name: product_buybox_history_2025_12_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2025_12_recorded_at_idx;


--
-- Name: product_buybox_history_2025_12_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2025_12_winner_price_idx;


--
-- Name: product_buybox_history_2025_12_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2025_12_winner_seller_idx;


--
-- Name: product_buybox_history_2026_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_01_pkey;


--
-- Name: product_buybox_history_2026_01_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_01_product_id_idx;


--
-- Name: product_buybox_history_2026_01_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_01_recorded_at_idx;


--
-- Name: product_buybox_history_2026_01_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_01_winner_price_idx;


--
-- Name: product_buybox_history_2026_01_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_01_winner_seller_idx;


--
-- Name: product_buybox_history_2026_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_02_pkey;


--
-- Name: product_buybox_history_2026_02_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_02_product_id_idx;


--
-- Name: product_buybox_history_2026_02_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_02_recorded_at_idx;


--
-- Name: product_buybox_history_2026_02_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_02_winner_price_idx;


--
-- Name: product_buybox_history_2026_02_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_02_winner_seller_idx;


--
-- Name: product_buybox_history_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_03_pkey;


--
-- Name: product_buybox_history_2026_03_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_03_product_id_idx;


--
-- Name: product_buybox_history_2026_03_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_03_recorded_at_idx;


--
-- Name: product_buybox_history_2026_03_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_03_winner_price_idx;


--
-- Name: product_buybox_history_2026_03_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_03_winner_seller_idx;


--
-- Name: product_buybox_history_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_04_pkey;


--
-- Name: product_buybox_history_2026_04_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_04_product_id_idx;


--
-- Name: product_buybox_history_2026_04_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_04_recorded_at_idx;


--
-- Name: product_buybox_history_2026_04_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_04_winner_price_idx;


--
-- Name: product_buybox_history_2026_04_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_04_winner_seller_idx;


--
-- Name: product_buybox_history_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_05_pkey;


--
-- Name: product_buybox_history_2026_05_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_05_product_id_idx;


--
-- Name: product_buybox_history_2026_05_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_05_recorded_at_idx;


--
-- Name: product_buybox_history_2026_05_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_05_winner_price_idx;


--
-- Name: product_buybox_history_2026_05_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_05_winner_seller_idx;


--
-- Name: product_buybox_history_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_06_pkey;


--
-- Name: product_buybox_history_2026_06_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_06_product_id_idx;


--
-- Name: product_buybox_history_2026_06_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_06_recorded_at_idx;


--
-- Name: product_buybox_history_2026_06_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_06_winner_price_idx;


--
-- Name: product_buybox_history_2026_06_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_06_winner_seller_idx;


--
-- Name: product_buybox_history_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_07_pkey;


--
-- Name: product_buybox_history_2026_07_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_07_product_id_idx;


--
-- Name: product_buybox_history_2026_07_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_07_recorded_at_idx;


--
-- Name: product_buybox_history_2026_07_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_07_winner_price_idx;


--
-- Name: product_buybox_history_2026_07_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_07_winner_seller_idx;


--
-- Name: product_buybox_history_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_buybox_history_pkey ATTACH PARTITION public.product_buybox_history_2026_08_pkey;


--
-- Name: product_buybox_history_2026_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_product_id ATTACH PARTITION public.product_buybox_history_2026_08_product_id_idx;


--
-- Name: product_buybox_history_2026_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_recorded_at ATTACH PARTITION public.product_buybox_history_2026_08_recorded_at_idx;


--
-- Name: product_buybox_history_2026_08_winner_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_price ATTACH PARTITION public.product_buybox_history_2026_08_winner_price_idx;


--
-- Name: product_buybox_history_2026_08_winner_seller_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_buybox_history_seller ATTACH PARTITION public.product_buybox_history_2026_08_winner_seller_idx;


--
-- Name: product_price_history_2025_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2025_08_pkey;


--
-- Name: product_price_history_2025_08_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2025_08_price_idx;


--
-- Name: product_price_history_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2025_08_product_id_idx;


--
-- Name: product_price_history_2025_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2025_08_recorded_at_idx;


--
-- Name: product_price_history_2025_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2025_09_pkey;


--
-- Name: product_price_history_2025_09_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2025_09_price_idx;


--
-- Name: product_price_history_2025_09_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2025_09_product_id_idx;


--
-- Name: product_price_history_2025_09_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2025_09_recorded_at_idx;


--
-- Name: product_price_history_2025_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2025_10_pkey;


--
-- Name: product_price_history_2025_10_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2025_10_price_idx;


--
-- Name: product_price_history_2025_10_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2025_10_product_id_idx;


--
-- Name: product_price_history_2025_10_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2025_10_recorded_at_idx;


--
-- Name: product_price_history_2025_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2025_11_pkey;


--
-- Name: product_price_history_2025_11_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2025_11_price_idx;


--
-- Name: product_price_history_2025_11_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2025_11_product_id_idx;


--
-- Name: product_price_history_2025_11_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2025_11_recorded_at_idx;


--
-- Name: product_price_history_2025_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2025_12_pkey;


--
-- Name: product_price_history_2025_12_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2025_12_price_idx;


--
-- Name: product_price_history_2025_12_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2025_12_product_id_idx;


--
-- Name: product_price_history_2025_12_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2025_12_recorded_at_idx;


--
-- Name: product_price_history_2026_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_01_pkey;


--
-- Name: product_price_history_2026_01_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_01_price_idx;


--
-- Name: product_price_history_2026_01_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_01_product_id_idx;


--
-- Name: product_price_history_2026_01_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_01_recorded_at_idx;


--
-- Name: product_price_history_2026_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_02_pkey;


--
-- Name: product_price_history_2026_02_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_02_price_idx;


--
-- Name: product_price_history_2026_02_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_02_product_id_idx;


--
-- Name: product_price_history_2026_02_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_02_recorded_at_idx;


--
-- Name: product_price_history_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_03_pkey;


--
-- Name: product_price_history_2026_03_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_03_price_idx;


--
-- Name: product_price_history_2026_03_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_03_product_id_idx;


--
-- Name: product_price_history_2026_03_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_03_recorded_at_idx;


--
-- Name: product_price_history_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_04_pkey;


--
-- Name: product_price_history_2026_04_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_04_price_idx;


--
-- Name: product_price_history_2026_04_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_04_product_id_idx;


--
-- Name: product_price_history_2026_04_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_04_recorded_at_idx;


--
-- Name: product_price_history_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_05_pkey;


--
-- Name: product_price_history_2026_05_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_05_price_idx;


--
-- Name: product_price_history_2026_05_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_05_product_id_idx;


--
-- Name: product_price_history_2026_05_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_05_recorded_at_idx;


--
-- Name: product_price_history_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_06_pkey;


--
-- Name: product_price_history_2026_06_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_06_price_idx;


--
-- Name: product_price_history_2026_06_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_06_product_id_idx;


--
-- Name: product_price_history_2026_06_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_06_recorded_at_idx;


--
-- Name: product_price_history_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_07_pkey;


--
-- Name: product_price_history_2026_07_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_07_price_idx;


--
-- Name: product_price_history_2026_07_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_07_product_id_idx;


--
-- Name: product_price_history_2026_07_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_07_recorded_at_idx;


--
-- Name: product_price_history_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_price_history_pkey ATTACH PARTITION public.product_price_history_2026_08_pkey;


--
-- Name: product_price_history_2026_08_price_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_price ATTACH PARTITION public.product_price_history_2026_08_price_idx;


--
-- Name: product_price_history_2026_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_product_id ATTACH PARTITION public.product_price_history_2026_08_product_id_idx;


--
-- Name: product_price_history_2026_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_price_history_recorded_at ATTACH PARTITION public.product_price_history_2026_08_recorded_at_idx;


--
-- Name: product_ranking_history_2025_08_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2025_08_bsr_rank_idx;


--
-- Name: product_ranking_history_2025_08_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2025_08_category_idx;


--
-- Name: product_ranking_history_2025_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2025_08_pkey;


--
-- Name: product_ranking_history_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2025_08_product_id_idx;


--
-- Name: product_ranking_history_2025_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2025_08_recorded_at_idx;


--
-- Name: product_ranking_history_2025_09_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2025_09_bsr_rank_idx;


--
-- Name: product_ranking_history_2025_09_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2025_09_category_idx;


--
-- Name: product_ranking_history_2025_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2025_09_pkey;


--
-- Name: product_ranking_history_2025_09_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2025_09_product_id_idx;


--
-- Name: product_ranking_history_2025_09_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2025_09_recorded_at_idx;


--
-- Name: product_ranking_history_2025_10_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2025_10_bsr_rank_idx;


--
-- Name: product_ranking_history_2025_10_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2025_10_category_idx;


--
-- Name: product_ranking_history_2025_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2025_10_pkey;


--
-- Name: product_ranking_history_2025_10_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2025_10_product_id_idx;


--
-- Name: product_ranking_history_2025_10_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2025_10_recorded_at_idx;


--
-- Name: product_ranking_history_2025_11_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2025_11_bsr_rank_idx;


--
-- Name: product_ranking_history_2025_11_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2025_11_category_idx;


--
-- Name: product_ranking_history_2025_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2025_11_pkey;


--
-- Name: product_ranking_history_2025_11_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2025_11_product_id_idx;


--
-- Name: product_ranking_history_2025_11_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2025_11_recorded_at_idx;


--
-- Name: product_ranking_history_2025_12_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2025_12_bsr_rank_idx;


--
-- Name: product_ranking_history_2025_12_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2025_12_category_idx;


--
-- Name: product_ranking_history_2025_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2025_12_pkey;


--
-- Name: product_ranking_history_2025_12_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2025_12_product_id_idx;


--
-- Name: product_ranking_history_2025_12_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2025_12_recorded_at_idx;


--
-- Name: product_ranking_history_2026_01_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_01_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_01_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_01_category_idx;


--
-- Name: product_ranking_history_2026_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_01_pkey;


--
-- Name: product_ranking_history_2026_01_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_01_product_id_idx;


--
-- Name: product_ranking_history_2026_01_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_01_recorded_at_idx;


--
-- Name: product_ranking_history_2026_02_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_02_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_02_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_02_category_idx;


--
-- Name: product_ranking_history_2026_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_02_pkey;


--
-- Name: product_ranking_history_2026_02_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_02_product_id_idx;


--
-- Name: product_ranking_history_2026_02_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_02_recorded_at_idx;


--
-- Name: product_ranking_history_2026_03_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_03_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_03_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_03_category_idx;


--
-- Name: product_ranking_history_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_03_pkey;


--
-- Name: product_ranking_history_2026_03_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_03_product_id_idx;


--
-- Name: product_ranking_history_2026_03_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_03_recorded_at_idx;


--
-- Name: product_ranking_history_2026_04_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_04_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_04_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_04_category_idx;


--
-- Name: product_ranking_history_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_04_pkey;


--
-- Name: product_ranking_history_2026_04_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_04_product_id_idx;


--
-- Name: product_ranking_history_2026_04_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_04_recorded_at_idx;


--
-- Name: product_ranking_history_2026_05_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_05_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_05_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_05_category_idx;


--
-- Name: product_ranking_history_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_05_pkey;


--
-- Name: product_ranking_history_2026_05_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_05_product_id_idx;


--
-- Name: product_ranking_history_2026_05_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_05_recorded_at_idx;


--
-- Name: product_ranking_history_2026_06_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_06_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_06_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_06_category_idx;


--
-- Name: product_ranking_history_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_06_pkey;


--
-- Name: product_ranking_history_2026_06_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_06_product_id_idx;


--
-- Name: product_ranking_history_2026_06_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_06_recorded_at_idx;


--
-- Name: product_ranking_history_2026_07_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_07_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_07_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_07_category_idx;


--
-- Name: product_ranking_history_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_07_pkey;


--
-- Name: product_ranking_history_2026_07_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_07_product_id_idx;


--
-- Name: product_ranking_history_2026_07_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_07_recorded_at_idx;


--
-- Name: product_ranking_history_2026_08_bsr_rank_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_bsr_rank ATTACH PARTITION public.product_ranking_history_2026_08_bsr_rank_idx;


--
-- Name: product_ranking_history_2026_08_category_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_category ATTACH PARTITION public.product_ranking_history_2026_08_category_idx;


--
-- Name: product_ranking_history_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_ranking_history_pkey ATTACH PARTITION public.product_ranking_history_2026_08_pkey;


--
-- Name: product_ranking_history_2026_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_product_id ATTACH PARTITION public.product_ranking_history_2026_08_product_id_idx;


--
-- Name: product_ranking_history_2026_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_product_ranking_history_recorded_at ATTACH PARTITION public.product_ranking_history_2026_08_recorded_at_idx;


--
-- Name: product_review_history_2025_08_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2025_08_average_rating_idx;


--
-- Name: product_review_history_2025_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2025_08_pkey;


--
-- Name: product_review_history_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2025_08_product_id_idx;


--
-- Name: product_review_history_2025_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2025_08_recorded_at_idx;


--
-- Name: product_review_history_2025_09_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2025_09_average_rating_idx;


--
-- Name: product_review_history_2025_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2025_09_pkey;


--
-- Name: product_review_history_2025_09_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2025_09_product_id_idx;


--
-- Name: product_review_history_2025_09_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2025_09_recorded_at_idx;


--
-- Name: product_review_history_2025_10_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2025_10_average_rating_idx;


--
-- Name: product_review_history_2025_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2025_10_pkey;


--
-- Name: product_review_history_2025_10_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2025_10_product_id_idx;


--
-- Name: product_review_history_2025_10_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2025_10_recorded_at_idx;


--
-- Name: product_review_history_2025_11_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2025_11_average_rating_idx;


--
-- Name: product_review_history_2025_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2025_11_pkey;


--
-- Name: product_review_history_2025_11_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2025_11_product_id_idx;


--
-- Name: product_review_history_2025_11_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2025_11_recorded_at_idx;


--
-- Name: product_review_history_2025_12_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2025_12_average_rating_idx;


--
-- Name: product_review_history_2025_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2025_12_pkey;


--
-- Name: product_review_history_2025_12_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2025_12_product_id_idx;


--
-- Name: product_review_history_2025_12_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2025_12_recorded_at_idx;


--
-- Name: product_review_history_2026_01_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_01_average_rating_idx;


--
-- Name: product_review_history_2026_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_01_pkey;


--
-- Name: product_review_history_2026_01_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_01_product_id_idx;


--
-- Name: product_review_history_2026_01_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_01_recorded_at_idx;


--
-- Name: product_review_history_2026_02_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_02_average_rating_idx;


--
-- Name: product_review_history_2026_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_02_pkey;


--
-- Name: product_review_history_2026_02_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_02_product_id_idx;


--
-- Name: product_review_history_2026_02_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_02_recorded_at_idx;


--
-- Name: product_review_history_2026_03_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_03_average_rating_idx;


--
-- Name: product_review_history_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_03_pkey;


--
-- Name: product_review_history_2026_03_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_03_product_id_idx;


--
-- Name: product_review_history_2026_03_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_03_recorded_at_idx;


--
-- Name: product_review_history_2026_04_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_04_average_rating_idx;


--
-- Name: product_review_history_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_04_pkey;


--
-- Name: product_review_history_2026_04_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_04_product_id_idx;


--
-- Name: product_review_history_2026_04_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_04_recorded_at_idx;


--
-- Name: product_review_history_2026_05_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_05_average_rating_idx;


--
-- Name: product_review_history_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_05_pkey;


--
-- Name: product_review_history_2026_05_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_05_product_id_idx;


--
-- Name: product_review_history_2026_05_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_05_recorded_at_idx;


--
-- Name: product_review_history_2026_06_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_06_average_rating_idx;


--
-- Name: product_review_history_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_06_pkey;


--
-- Name: product_review_history_2026_06_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_06_product_id_idx;


--
-- Name: product_review_history_2026_06_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_06_recorded_at_idx;


--
-- Name: product_review_history_2026_07_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_07_average_rating_idx;


--
-- Name: product_review_history_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_07_pkey;


--
-- Name: product_review_history_2026_07_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_07_product_id_idx;


--
-- Name: product_review_history_2026_07_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_07_recorded_at_idx;


--
-- Name: product_review_history_2026_08_average_rating_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_rating ATTACH PARTITION public.product_review_history_2026_08_average_rating_idx;


--
-- Name: product_review_history_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.product_review_history_pkey ATTACH PARTITION public.product_review_history_2026_08_pkey;


--
-- Name: product_review_history_2026_08_product_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_product_id ATTACH PARTITION public.product_review_history_2026_08_product_id_idx;


--
-- Name: product_review_history_2026_08_recorded_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_review_history_recorded_at ATTACH PARTITION public.product_review_history_2026_08_recorded_at_idx;


--
-- Name: competitor_analysis_groups competitor_analysis_groups_main_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_analysis_groups
    ADD CONSTRAINT competitor_analysis_groups_main_product_id_fkey FOREIGN KEY (main_product_id) REFERENCES public.products(id);


--
-- Name: competitor_analysis_groups competitor_analysis_groups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_analysis_groups
    ADD CONSTRAINT competitor_analysis_groups_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: competitor_analysis_results competitor_analysis_results_analysis_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_analysis_results
    ADD CONSTRAINT competitor_analysis_results_analysis_group_id_fkey FOREIGN KEY (analysis_group_id) REFERENCES public.competitor_analysis_groups(id) ON DELETE CASCADE;


--
-- Name: competitor_products competitor_products_analysis_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_products
    ADD CONSTRAINT competitor_products_analysis_group_id_fkey FOREIGN KEY (analysis_group_id) REFERENCES public.competitor_analysis_groups(id) ON DELETE CASCADE;


--
-- Name: competitor_products competitor_products_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_products
    ADD CONSTRAINT competitor_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: optimization_analyses optimization_analyses_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimization_analyses
    ADD CONSTRAINT optimization_analyses_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: optimization_analyses optimization_analyses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimization_analyses
    ADD CONSTRAINT optimization_analyses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: optimization_suggestions optimization_suggestions_analysis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.optimization_suggestions
    ADD CONSTRAINT optimization_suggestions_analysis_id_fkey FOREIGN KEY (analysis_id) REFERENCES public.optimization_analyses(id) ON DELETE CASCADE;


--
-- Name: product_anomaly_events product_anomaly_events_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_anomaly_events
    ADD CONSTRAINT product_anomaly_events_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_buybox_history product_buybox_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.product_buybox_history
    ADD CONSTRAINT product_buybox_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_price_history product_price_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.product_price_history
    ADD CONSTRAINT product_price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_ranking_history product_ranking_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.product_ranking_history
    ADD CONSTRAINT product_ranking_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_review_history product_review_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.product_review_history
    ADD CONSTRAINT product_review_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: tracked_products tracked_products_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracked_products
    ADD CONSTRAINT tracked_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: tracked_products tracked_products_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracked_products
    ADD CONSTRAINT tracked_products_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict fXe6AUA8GahVTU2NOkh5ndR7Hu65uOXbaSwWsMV4YGsETmzf26GJcJkyA6Nn3Jx

