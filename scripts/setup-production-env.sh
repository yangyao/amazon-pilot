#!/bin/bash

# Amazon Pilot 生产环境配置生成脚本
# 在服务器上手动运行，生成 .env.production 文件

set -e

ENV_FILE="deployments/compose/.env.production"

echo "🔐 Amazon Pilot 生产环境配置生成"
echo "=================================="
echo ""
echo "此脚本将帮你创建生产环境配置文件"
echo "位置: $ENV_FILE"
echo ""

# 检查是否已存在配置文件
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  发现现有配置文件，是否备份并重新生成？(y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        mv "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ 已备份现有配置"
    else
        echo "❌ 取消操作"
        exit 0
    fi
fi

echo "📝 请输入以下配置信息:"
echo ""

# 收集配置信息
read -p "数据库密码 (postgres): " -s DATABASE_PASSWORD
echo ""
read -p "Redis密码: " -s REDIS_PASSWORD
echo ""
read -p "JWT密钥 (至少32字符): " -s JWT_SECRET
echo ""
read -p "Apify API Token: " -s APIFY_API_TOKEN
echo ""
read -p "OpenAI API Key: " -s OPENAI_API_KEY
echo ""
read -p "Grafana管理员密码: " -s GRAFANA_PASSWORD
echo ""

# 验证必需字段
if [ -z "$DATABASE_PASSWORD" ] || [ -z "$JWT_SECRET" ]; then
    echo "❌ 数据库密码和JWT密钥是必需的"
    exit 1
fi

if [ ${#JWT_SECRET} -lt 32 ]; then
    echo "❌ JWT密钥长度必须至少32字符"
    exit 1
fi

# 生成配置文件
echo "📄 生成配置文件..."

cat > "$ENV_FILE" << EOF
# Amazon Pilot 生产环境配置
# 生成时间: $(date)
# ⚠️ 此文件包含敏感信息，请勿提交到版本控制

# ===========================================
# 数据库配置
# ===========================================
DATABASE_DSN=postgresql://postgres:${DATABASE_PASSWORD}@amazon-pilot-postgres:5432/amazon_pilot
DATABASE_MAX_IDLE_CONNS=10
DATABASE_MAX_OPEN_CONNS=100
DATABASE_CONN_MAX_LIFETIME=3600

# ===========================================
# Redis配置
# ===========================================
REDIS_HOST=amazon-pilot-redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=${REDIS_PASSWORD}

# ===========================================
# API密钥
# ===========================================
APIFY_API_TOKEN=${APIFY_API_TOKEN}
OPENAI_API_KEY=${OPENAI_API_KEY}

# ===========================================
# JWT认证配置
# ===========================================
JWT_SECRET=${JWT_SECRET}
JWT_ACCESS_SECRET=${JWT_SECRET}
JWT_ACCESS_EXPIRE=86400

# ===========================================
# Worker配置
# ===========================================
WORKER_CONCURRENCY=10
WORKER_LOG_LEVEL=info

# ===========================================
# Scheduler配置
# ===========================================
SCHEDULER_PRODUCT_UPDATE_INTERVAL=5m

# ===========================================
# 监控配置
# ===========================================
GRAFANA_PASSWORD=${GRAFANA_PASSWORD}

# ===========================================
# 应用配置
# ===========================================
APP_ENV=production
LOG_LEVEL=info
ENVIRONMENT=production

# ===========================================
# 服务端口配置（Docker内部网络）
# ===========================================
# 端口配置在各服务的YAML文件中定义
# 这里只存储敏感信息
EOF

# 设置安全权限
chmod 600 "$ENV_FILE"
chown $(whoami):$(whoami) "$ENV_FILE"

echo ""
echo "✅ 生产环境配置文件生成完成!"
echo "📍 位置: $ENV_FILE"
echo "🔒 权限: 600 (仅当前用户可读写)"
echo ""
echo "🚀 下一步:"
echo "   docker-compose -f deployments/compose/docker-compose.yml --env-file $ENV_FILE up -d"
echo ""
echo "⚠️  安全提醒:"
echo "   1. 此文件包含敏感信息，请勿分享"
echo "   2. 定期更换密码和密钥"
echo "   3. 确保服务器安全配置"