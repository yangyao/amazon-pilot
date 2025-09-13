#!/bin/bash

# Amazon Pilot Demo 数据准备脚本
# 使用真实的Amazon产品ASIN进行演示

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🎯 准备 Amazon Pilot Demo 数据..."
echo "📁 项目根目录: $PROJECT_ROOT"

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 数据库连接配置
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-amazon_pilot}"

export PGPASSWORD="$DB_PASSWORD"

echo "📊 数据库配置: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# 真实的Amazon产品ASIN (无线蓝牙耳机类别)
DEMO_ASINS=(
    "B08N5WRWNW"  # Echo Buds (2nd Gen)
    "B0BFZB9Z2P"  # Apple AirPods Pro (2nd Gen)  
    "B0BDRR8Z6G"  # Sony WF-1000XM4
    "B08DVMPZP6"  # Samsung Galaxy Buds2
    "B09JB2RKPT"  # Beats Studio Buds
    "B08FBP64B1"  # Jabra Elite 85t
    "B087TLZQ3N"  # Anker Soundcore Liberty Air 2 Pro
    "B08T93ZD74"  # Sennheiser Momentum True Wireless 3
)

echo ""
echo "🎧 Demo产品类别: 无线蓝牙耳机"
echo "📦 产品数量: ${#DEMO_ASINS[@]}"
echo "🔗 产品ASIN: ${DEMO_ASINS[*]}"

# 创建Demo用户
echo ""
echo "👤 创建Demo用户..."

DEMO_USER_EMAIL="demo@amazon-pilot.com"
DEMO_USER_PASSWORD="demo123456"

# 检查用户是否已存在
USER_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM users WHERE email = '$DEMO_USER_EMAIL';
" 2>/dev/null | xargs)

if [ "$USER_EXISTS" = "0" ]; then
    echo "📝 创建新用户: $DEMO_USER_EMAIL"
    
    # 生成密码哈希 (使用Go程序)
    PASSWORD_HASH=$(go run -<<EOF
package main

import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)

func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("$DEMO_USER_PASSWORD"), bcrypt.DefaultCost)
    fmt.Print(string(hash))
}
EOF
)

    # 插入用户
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO users (email, password_hash, plan_type, is_active, email_verified)
        VALUES ('$DEMO_USER_EMAIL', '$PASSWORD_HASH', 'premium', true, true);
    "
    
    echo "✅ Demo用户创建成功"
else
    echo "👤 Demo用户已存在，跳过创建"
fi

# 获取用户ID
DEMO_USER_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT id FROM users WHERE email = '$DEMO_USER_EMAIL';
" | xargs)

echo "🆔 Demo用户ID: $DEMO_USER_ID"

# 插入Demo产品
echo ""
echo "📦 插入Demo产品..."

for asin in "${DEMO_ASINS[@]}"; do
    # 检查产品是否已存在
    PRODUCT_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT COUNT(*) FROM products WHERE asin = '$asin';
    " 2>/dev/null | xargs)
    
    if [ "$PRODUCT_EXISTS" = "0" ]; then
        echo "   📦 添加产品: $asin"
        
        # 插入产品 (将通过Apify API获取完整数据)
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
            INSERT INTO products (
                asin, title, current_price, currency, 
                is_tracked, user_id, created_at, updated_at
            ) VALUES (
                '$asin', 
                'Product $asin (will be updated by Apify)', 
                0.00, 
                'USD',
                true, 
                '$DEMO_USER_ID', 
                NOW(), 
                NOW()
            );
        " > /dev/null
        
        # 获取产品ID并添加到tracked_products
        PRODUCT_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT id FROM products WHERE asin = '$asin';
        " | xargs)
        
        # 添加到tracked_products表
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
            INSERT INTO tracked_products (
                user_id, product_id, tracking_frequency, 
                price_alert_threshold, is_active, created_at
            ) VALUES (
                '$DEMO_USER_ID', 
                '$PRODUCT_ID', 
                'daily', 
                10.0, 
                true, 
                NOW()
            );
        " > /dev/null
        
        echo "   ✅ 产品 $asin 添加成功"
    else
        echo "   ⏭️  产品 $asin 已存在，跳过"
    fi
done

# 创建Demo竞争对手分析组
echo ""
echo "🏆 创建竞争对手分析组..."

MAIN_PRODUCT_ASIN="B08N5WRWNW"  # Echo Buds作为主产品
MAIN_PRODUCT_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT id FROM products WHERE asin = '$MAIN_PRODUCT_ASIN';
" | xargs)

# 检查分析组是否已存在
ANALYSIS_GROUP_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM competitor_analysis_groups WHERE user_id = '$DEMO_USER_ID';
" 2>/dev/null | xargs)

if [ "$ANALYSIS_GROUP_EXISTS" = "0" ]; then
    echo "📊 创建竞争对手分析组..."
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO competitor_analysis_groups (
            user_id, name, description, main_product_id, 
            update_frequency, is_active, created_at, updated_at
        ) VALUES (
            '$DEMO_USER_ID',
            'Wireless Earbuds Competition Analysis',
            'Analysis of top wireless earbuds in the market including AirPods Pro, Sony, Samsung and others',
            '$MAIN_PRODUCT_ID',
            'daily',
            true,
            NOW(),
            NOW()
        );
    " > /dev/null
    
    echo "✅ 竞争对手分析组创建成功"
else
    echo "🏆 竞争对手分析组已存在，跳过创建"
fi

# 显示Demo数据统计
echo ""
echo "📊 Demo数据统计:"

echo "   👤 用户数量:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT COUNT(*) as users_count FROM users;
"

echo "   📦 产品数量:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT COUNT(*) as products_count FROM products;
"

echo "   🎯 追踪产品数量:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT COUNT(*) as tracked_products_count FROM tracked_products WHERE is_active = true;
"

echo "   🏆 分析组数量:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT COUNT(*) as analysis_groups_count FROM competitor_analysis_groups;
"

echo ""
echo "🎉 Demo数据准备完成！"
echo ""
echo "🔑 Demo登录信息:"
echo "   📧 邮箱: $DEMO_USER_EMAIL"  
echo "   🔒 密码: $DEMO_USER_PASSWORD"
echo ""
echo "🚀 下一步:"
echo "   1. 设置Apify API Token: export APIFY_API_TOKEN='your_token'"
echo "   2. 启动系统: ./scripts/start-full-system.sh"
echo "   3. 访问前端: http://localhost:3000"
echo "   4. 触发产品更新: 使用系统界面或调用API"
echo ""
echo "📊 系统会自动:"
echo "   • 使用Apify API获取真实产品数据"
echo "   • 检测价格变动 >10% 和 BSR变动 >30%"
echo "   • 发送实时异常通知"
echo "   • 生成AI优化建议"