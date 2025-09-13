#!/bin/bash

# Amazon Pilot Worker 启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 启动 Amazon Pilot Worker..."
echo "📁 项目根目录: $PROJECT_ROOT"

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查配置文件
CONFIG_FILE="cmd/worker/etc/worker.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "📋 配置文件: $CONFIG_FILE"

# 设置环境变量
export GOOS=linux
export GOARCH=amd64

# 启动Worker
echo "🔧 启动 Worker 服务..."
go run cmd/worker/main.go -f "$CONFIG_FILE"