#!/bin/bash

# Amazon Pilot 服务器部署脚本
# 在服务器上执行，由GitHub CI调用

set -e

# 创建详细日志
LOGFILE="/tmp/amazon-pilot-deploy-$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=========================================="
echo "🚀 Amazon Pilot Server Deployment Script"
echo "🕐 Start time: $(date)"
echo "📋 Log file: $LOGFILE"
echo "=========================================="

# 检查环境变量
echo "🔍 Checking environment variables..."
echo "DATABASE_DSN: ${DATABASE_DSN:0:30}..."
echo "JWT_SECRET: ${JWT_SECRET:0:10}..."
echo "DEPLOY_DIR: ${DEPLOY_DIR}"

# 进入部署目录
echo "📂 Changing to deploy directory..."
cd "${DEPLOY_DIR:-/opt/amazon-pilot}"
echo "✅ Current directory: $(pwd)"

# 生成生产环境配置
echo "📝 Generating production environment file..."
cat > deployments/compose/.env.production << EOF
# Amazon Pilot 生产环境配置 - GitHub CI 自动生成
# 生成时间: $(date)

# 数据库配置
DATABASE_DSN=${DATABASE_DSN}
DATABASE_MAX_IDLE_CONNS=10
DATABASE_MAX_OPEN_CONNS=100
DATABASE_CONN_MAX_LIFETIME=3600

# Redis配置
REDIS_HOST=amazon-pilot-redis
REDIS_PORT=6379
REDIS_DB=0

# API密钥
APIFY_API_TOKEN=${APIFY_API_TOKEN}
OPENAI_API_KEY=${OPENAI_API_KEY}

# JWT配置
JWT_SECRET=${JWT_SECRET}
JWT_ACCESS_SECRET=${JWT_SECRET}
JWT_ACCESS_EXPIRE=86400

# Worker配置
WORKER_CONCURRENCY=10

# Scheduler配置
SCHEDULER_PRODUCT_UPDATE_INTERVAL=5m

# 监控配置
GRAFANA_PASSWORD=${GRAFANA_PASSWORD}

# 环境标识
ENVIRONMENT=production
EOF

chmod 600 deployments/compose/.env.production
echo "✅ Environment file created"

# 加载Docker镜像
echo "📦 Loading Docker images..."
IMAGE_COUNT=0
for image_file in $(find /tmp/amazon-pilot-deploy -name "*.tar.gz" 2>/dev/null); do
  if [ -f "$image_file" ]; then
    echo "📦 Loading $image_file..."
    if gunzip -c "$image_file" | docker load; then
      echo "✅ Successfully loaded $image_file"
      IMAGE_COUNT=$((IMAGE_COUNT + 1))
    else
      echo "❌ Failed to load $image_file"
    fi
  fi
done

echo "📊 Total images loaded: $IMAGE_COUNT"

# 重新部署服务（使用生产环境配置，不包含 Caddy）
echo "🔄 Redeploying services (Production mode - without Caddy)..."
docker-compose \
  -f deployments/compose/docker-compose.yml \
  -f deployments/compose/docker-compose.prod.yml \
  down || echo "No existing services"

echo "🚀 Starting services with new images..."
docker-compose \
  -f deployments/compose/docker-compose.yml \
  -f deployments/compose/docker-compose.prod.yml \
  --env-file deployments/compose/.env.production \
  up -d --force-recreate --remove-orphans

echo "⏳ Waiting for services to start..."
sleep 30

echo "📊 Service status:"
docker-compose \
  -f deployments/compose/docker-compose.yml \
  -f deployments/compose/docker-compose.prod.yml \
  ps

echo "🏥 Health check..."
if curl -f http://localhost:8080/health; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
  docker-compose \
    -f deployments/compose/docker-compose.yml \
    -f deployments/compose/docker-compose.prod.yml \
    logs --tail=10 amazon-pilot-gateway
fi

echo "🧹 Cleanup..."
rm -rf /tmp/amazon-pilot-deploy

# 保存日志
mkdir -p logs
cp "$LOGFILE" "logs/github-ci-$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "✅ Deployment completed successfully!"
echo "🕐 End time: $(date)"
echo "📋 Log saved to: logs/github-ci-$(date +%Y%m%d_%H%M%S).log"
echo ""
echo "📌 Production service ports:"
echo "   Frontend: :4000 (proxied by Caddy)"
echo "   Gateway:  :8080 (proxied by Caddy)"
echo ""
echo "🌐 Service available at: https://amazon-pilot.phpman.top"
echo "   (Requires Caddy configuration on host machine)"
echo "=========================================="