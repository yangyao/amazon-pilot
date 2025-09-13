#!/bin/bash

# Amazon Pilot Demo - 使用模拟数据演示完整流程
# 在没有Apify API Token时使用此脚本进行Demo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🎬 Amazon Pilot 完整流程演示 (模拟数据)"
echo "============================================="

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 1. 检查环境
echo ""
echo "🔍 环境检查..."
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm 未安装"  
    exit 1
fi

echo "✅ 环境检查通过"

# 2. 设置数据库
echo ""
echo "🗄️  数据库设置..."
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_USER="postgres"
export DB_PASSWORD="amazon123"
export DB_NAME="amazon_pilot"
export PGPASSWORD="$DB_PASSWORD"

echo "📊 数据库: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# 检查数据库连接
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 数据库连接失败"
    echo "💡 请确保PostgreSQL运行并创建数据库: $DB_NAME"
    exit 1
fi

echo "✅ 数据库连接成功"

# 3. 运行数据库迁移
echo ""
echo "📋 执行数据库迁移..."

# 创建基本表结构
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- 确保必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- 创建产品表
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asin VARCHAR(10) UNIQUE NOT NULL,
    title TEXT,
    brand VARCHAR(255),
    current_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    rating DECIMAL(3,2),
    review_count INTEGER,
    current_bsr INTEGER,
    is_tracked BOOLEAN DEFAULT false,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建价格历史表
CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'api'
);

-- 创建BSR历史表
CREATE TABLE IF NOT EXISTS product_bsr_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    bsr INTEGER NOT NULL,
    category VARCHAR(255),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'api'
);

-- 创建追踪产品表
CREATE TABLE IF NOT EXISTS tracked_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tracking_frequency VARCHAR(20) DEFAULT 'daily',
    price_alert_threshold DECIMAL(5,2) DEFAULT 10.0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- 创建通知表
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'info',
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);
EOF

echo "✅ 基本表结构创建完成"

# 4. 创建Demo用户和产品
echo ""
echo "🎯 创建Demo数据..."

# 创建Demo用户
DEMO_EMAIL="demo@amazon-pilot.com"
DEMO_PASSWORD="demo123456"

# 生成密码哈希
PASSWORD_HASH=$(go run -<<EOF
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("$DEMO_PASSWORD"), bcrypt.DefaultCost)
    fmt.Print(string(hash))
}
EOF
)

# 插入Demo用户
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
INSERT INTO users (email, password_hash, plan_type, is_active, email_verified)
VALUES ('$DEMO_EMAIL', '$PASSWORD_HASH', 'premium', true, true)
ON CONFLICT (email) DO NOTHING;
"

# 获取用户ID
DEMO_USER_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT id FROM users WHERE email = '$DEMO_EMAIL';
" | xargs)

echo "👤 Demo用户: $DEMO_EMAIL"
echo "🆔 用户ID: $DEMO_USER_ID"

# 创建模拟产品数据
DEMO_PRODUCTS=(
    "B08N5WRWNW:Echo Buds (2nd Gen):89.99"
    "B0BFZB9Z2P:Apple AirPods Pro (2nd Gen):249.99"
    "B0BDRR8Z6G:Sony WF-1000XM4:199.99"
    "B08DVMPZP6:Samsung Galaxy Buds2:119.99"
    "B09JB2RKPT:Beats Studio Buds:149.99"
)

echo ""
echo "📦 创建模拟产品数据..."

for product_data in "${DEMO_PRODUCTS[@]}"; do
    IFS=':' read -r asin title price <<< "$product_data"
    
    echo "   📦 添加产品: $asin - $title"
    
    # 插入产品
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO products (
            asin, title, current_price, currency, rating, review_count, 
            current_bsr, is_tracked, user_id, created_at, updated_at
        ) VALUES (
            '$asin', '$title', $price, 'USD', 
            4.0 + (RANDOM() * 1.0), (1000 + (RANDOM() * 5000))::INTEGER,
            (1000 + (RANDOM() * 10000))::INTEGER, true, '$DEMO_USER_ID', NOW(), NOW()
        ) ON CONFLICT (asin) DO UPDATE SET
            title = EXCLUDED.title,
            current_price = EXCLUDED.current_price,
            updated_at = NOW();
    " > /dev/null
    
    # 获取产品ID并添加到tracked_products
    PRODUCT_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT id FROM products WHERE asin = '$asin';
    " | xargs)
    
    # 添加追踪关系
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO tracked_products (
            user_id, product_id, tracking_frequency, 
            price_alert_threshold, is_active, created_at
        ) VALUES (
            '$DEMO_USER_ID', '$PRODUCT_ID', 'daily', 10.0, true, NOW()
        ) ON CONFLICT (user_id, product_id) DO NOTHING;
    " > /dev/null
    
    # 创建历史价格数据 (模拟变化以触发异常检测)
    OLD_PRICE=$(echo "$price * 0.85" | bc -l | cut -d. -f1-2)
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO product_price_history (product_id, price, currency, recorded_at, data_source)
        VALUES ('$PRODUCT_ID', $OLD_PRICE, 'USD', NOW() - INTERVAL '1 day', 'demo_old');
        
        INSERT INTO product_price_history (product_id, price, currency, recorded_at, data_source)  
        VALUES ('$PRODUCT_ID', $price, 'USD', NOW(), 'demo_current');
    " > /dev/null
done

echo "✅ Demo产品数据创建完成"

# 5. 创建一些模拟通知
echo ""
echo "🔔 创建模拟异常检测通知..."

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
INSERT INTO notifications (user_id, type, title, message, severity, is_read, created_at)
SELECT 
    '$DEMO_USER_ID',
    'price_alert',
    'Price Alert: ' || asin,
    'Product price increased by 17.6% (from $' || ROUND((current_price * 0.85)::numeric, 2) || ' to $' || current_price || ')',
    'warning',
    false,
    NOW() - (RANDOM() * INTERVAL '2 hours')
FROM products 
WHERE user_id = '$DEMO_USER_ID' 
LIMIT 3;
"

echo "✅ 模拟通知创建完成"

# 6. 显示Demo数据统计
echo ""
echo "📊 Demo数据统计:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 
    'Products', COUNT(*) FROM products  
UNION ALL
SELECT 
    'Tracked Products', COUNT(*) FROM tracked_products WHERE is_active = true
UNION ALL
SELECT 
    'Price History', COUNT(*) FROM product_price_history
UNION ALL  
SELECT 
    'Notifications', COUNT(*) FROM notifications;
"

echo ""
echo "🎉 Demo数据准备完成！"
echo ""
echo "🎬 Demo演示信息:"
echo "   📧 登录邮箱: $DEMO_EMAIL"
echo "   🔒 登录密码: $DEMO_PASSWORD"
echo "   📦 Demo产品: ${#DEMO_PRODUCTS[@]}个无线蓝牙耳机"
echo "   🔔 模拟通知: 3个价格变动警报"
echo ""
echo "🚀 下一步:"
echo "   1. 启动系统: ./scripts/start-full-system.sh"
echo "   2. 访问前端: http://localhost:3000"  
echo "   3. 使用上述账户登录"
echo "   4. 观察模拟的异常检测通知"
echo ""
echo "💡 要使用真实Apify数据:"
echo "   1. 访问 https://console.apify.com/"
echo "   2. 使用 questions.md 中的账户信息登录"
echo "   3. 获取API Token并设置: export APIFY_API_TOKEN='your_token'"
echo "   4. 运行: go run scripts/test-apify-demo.go"