#!/bin/bash

# Amazon Pilot Scheduler 启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "⏰ 启动 Amazon Pilot Scheduler..."
echo "📁 项目根目录: $PROJECT_ROOT"

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查配置文件
CONFIG_FILE="cmd/scheduler/etc/scheduler.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "📋 配置文件: $CONFIG_FILE"

# 启动Scheduler
echo "🔧 启动 Scheduler 服务..."
go run cmd/scheduler/main.go -f "$CONFIG_FILE"