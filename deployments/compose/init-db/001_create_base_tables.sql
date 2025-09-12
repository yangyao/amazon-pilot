-- Migration: 001_create_base_tables.sql
-- Description: Create core tables for Amazon seller product monitoring tool
-- Created: 2025-09-12

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_plan_type_check CHECK (plan_type IN ('basic', 'premium', 'enterprise'))
);

-- Indexes for users table
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan_type ON users(plan_type);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 2. User settings table
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_email BOOLEAN DEFAULT true,
    notification_push BOOLEAN DEFAULT false,
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    default_tracking_frequency VARCHAR(20) DEFAULT 'daily',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT user_settings_user_id_unique UNIQUE (user_id),
    CONSTRAINT user_settings_frequency_check CHECK (default_tracking_frequency IN ('hourly', 'daily', 'weekly'))
);

-- Indexes for user_settings table
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- 3. Products table
CREATE TABLE products (
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
    
    -- Basic information
    manufacturer VARCHAR(255),
    model_number VARCHAR(100),
    upc VARCHAR(20),
    ean VARCHAR(20),
    
    -- Timestamps
    first_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'apify',
    
    -- Constraints
    CONSTRAINT products_asin_length CHECK (LENGTH(asin) = 10)
);

-- Indexes for products table
CREATE INDEX idx_products_asin ON products(asin);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_first_seen_at ON products(first_seen_at);
CREATE INDEX idx_products_last_updated_at ON products(last_updated_at);

-- 4. Tracked products table (Many-to-Many relationship between users and products)
CREATE TABLE tracked_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alias VARCHAR(255), -- User-defined name for the product
    is_active BOOLEAN DEFAULT true,
    tracking_frequency VARCHAR(20) DEFAULT 'daily',
    price_change_threshold DECIMAL(5,2) DEFAULT 10.0, -- Percentage
    bsr_change_threshold DECIMAL(5,2) DEFAULT 30.0,   -- Percentage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_checked_at TIMESTAMP WITH TIME ZONE,
    next_check_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT tracked_products_user_product_unique UNIQUE (user_id, product_id),
    CONSTRAINT tracked_products_frequency_check CHECK (tracking_frequency IN ('hourly', 'daily', 'weekly')),
    CONSTRAINT tracked_products_price_threshold_check CHECK (price_change_threshold >= 0 AND price_change_threshold <= 100),
    CONSTRAINT tracked_products_bsr_threshold_check CHECK (bsr_change_threshold >= 0 AND bsr_change_threshold <= 100)
);

-- Indexes for tracked_products table
CREATE INDEX idx_tracked_products_user_id ON tracked_products(user_id);
CREATE INDEX idx_tracked_products_product_id ON tracked_products(product_id);
CREATE INDEX idx_tracked_products_next_check_at ON tracked_products(next_check_at);
CREATE INDEX idx_tracked_products_is_active ON tracked_products(is_active);

-- 5. Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(10) DEFAULT 'info',
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT notifications_severity_check CHECK (severity IN ('info', 'warning', 'error', 'success')),
    CONSTRAINT notifications_type_check CHECK (type IN ('price_change', 'bsr_change', 'competitor_update', 'optimization_ready', 'system'))
);

-- Indexes for notifications table
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at);

-- Enable Row Level Security (RLS) for user data protection
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracked_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user data access
CREATE POLICY "Users can only see their own data" ON users
    FOR ALL USING (auth.uid()::text = id::text);

CREATE POLICY "Users can only access their own settings" ON user_settings
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can only access their tracked products" ON tracked_products
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can only access their notifications" ON notifications
    FOR ALL USING (auth.uid()::text = user_id::text);

-- Products table is readable by all authenticated users but only admin can modify
CREATE POLICY "Authenticated users can read products" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Only service role can modify products" ON products
    FOR ALL USING (auth.role() = 'service_role');