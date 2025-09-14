#!/bin/bash

# Amazon Pilot - Docker 镜像构建脚本

set -e

echo "🚀 开始构建 Amazon Pilot Docker 镜像..."

# 确保在项目根目录
if [ ! -f "go.mod" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 构建所有服务镜像
echo "📦 构建后端服务镜像..."

echo "  - 构建 Auth 服务..."
docker build -f docker/Dockerfile.auth -t amazon-pilot-auth:latest .

echo "  - 构建 Product 服务..."
docker build -f docker/Dockerfile.product -t amazon-pilot-product:latest .

echo "  - 构建 Competitor 服务..."
docker build -f docker/Dockerfile.competitor -t amazon-pilot-competitor:latest .

echo "  - 构建 Optimization 服务..."
docker build -f docker/Dockerfile.optimization -t amazon-pilot-optimization:latest .

echo "  - 构建 Gateway 服务..."
docker build -f docker/Dockerfile.gateway -t amazon-pilot-gateway:latest .

echo "📦 构建后台服务镜像..."

echo "  - 构建 Worker 服务..."
docker build -f docker/Dockerfile.worker -t amazon-pilot-worker:latest .

echo "  - 构建 Scheduler 服务..."
docker build -f docker/Dockerfile.scheduler -t amazon-pilot-scheduler:latest .

echo "  - 构建 Dashboard 服务..."
docker build -f docker/Dockerfile.dashboard -t amazon-pilot-dashboard:latest .

echo "📦 构建前端镜像..."

echo "  - 构建 Frontend 服务..."
docker build -f docker/Dockerfile.frontend -t amazon-pilot-frontend:latest .

echo "✅ 所有镜像构建完成！"

# 显示构建的镜像
echo "📋 构建的镜像列表："
docker images | grep "amazon-pilot"

echo ""
echo "🎉 现在可以使用 docker-compose 启动服务了："
echo "   cd deployments/compose"
echo "   docker-compose --env-file .env up -d"