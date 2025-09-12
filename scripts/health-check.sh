#!/bin/bash

# 健康检查脚本 - 支持滚动更新

SERVICE_NAME=$1
MAX_ATTEMPTS=30
ATTEMPT=1

echo "开始健康检查服务: $SERVICE_NAME"

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "尝试 $ATTEMPT/$MAX_ATTEMPTS: 检查 $SERVICE_NAME 健康状态..."
    
    # 检查容器是否运行
    if ! docker-compose ps $SERVICE_NAME | grep -q "Up"; then
        echo "容器未运行，等待启动..."
        sleep 5
        ATTEMPT=$((ATTEMPT + 1))
        continue
    fi
    
    # 获取服务端口
    case $SERVICE_NAME in
        auth-service)
            PORT=8001
            ;;
        product-service)
            PORT=8002
            ;;
        competitor-service)
            PORT=8003
            ;;
        optimization-service)
            PORT=8004
            ;;
        notification-service)
            PORT=8005
            ;;
        frontend)
            PORT=3000
            ;;
        asynq-monitor)
            PORT=5555
            ;;
        *)
            echo "未知服务: $SERVICE_NAME"
            exit 1
            ;;
    esac
    
    # 检查健康端点
    if curl -f -s http://localhost:$PORT/health > /dev/null 2>&1; then
        echo "✅ $SERVICE_NAME 健康检查通过"
        exit 0
    else
        echo "❌ $SERVICE_NAME 健康检查失败，等待重试..."
        sleep 5
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo "❌ $SERVICE_NAME 健康检查超时，部署可能失败"
exit 1
