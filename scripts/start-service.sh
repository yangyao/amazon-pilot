#!/bin/bash

# start-service.sh - 快速启动指定服务

if [[ $# -eq 0 ]]; then
    echo "用法: $0 <service-name>"
    echo "可用服务: auth, product, competitor, optimization, notification"
    echo ""
    echo "示例:"
    echo "  $0 auth        # 启动认证服务"
    echo "  $0 product     # 启动产品服务"
    exit 1
fi

SERVICE=$1

if [[ ! -d "cmd/$SERVICE" ]]; then
    echo "❌ 服务 $SERVICE 不存在"
    echo "可用服务目录:"
    ls -1 cmd/ | sed 's/^/  /'
    exit 1
fi

echo "🚀 启动服务: $SERVICE"
echo "📍 配置文件: cmd/$SERVICE/etc/$SERVICE-api.yaml"
echo "🌐 访问地址: http://localhost:8888"
echo ""

go run "cmd/$SERVICE/main.go" -f "cmd/$SERVICE/etc/$SERVICE-api.yaml"