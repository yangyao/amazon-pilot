#!/bin/bash

# start-frontend.sh - 启动前端开发服务器

echo "🌐 启动前端开发服务器..."

# 检查是否在正确的目录
if [[ ! -f "frontend/package.json" ]]; then
    echo "❌ 找不到 frontend/package.json 文件"
    exit 1
fi

# 检查是否安装了依赖
if [[ ! -d "frontend/node_modules" ]]; then
    echo "📦 安装前端依赖..."
    (cd frontend && pnpm install)
fi

echo "🚀 启动 Next.js 开发服务器..."
echo "📍 前端地址: http://localhost:3000"
echo "🔗 后端API: http://localhost:8888"
echo ""

# 启动开发服务器
exec bash -c "cd frontend && pnpm dev"