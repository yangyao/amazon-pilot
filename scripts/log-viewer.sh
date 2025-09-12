#!/bin/bash

# 简单的日志查看脚本

LOG_DIR="/var/log/amazon-pilot"
CADDY_LOG_DIR="/var/log/caddy"

echo "=== Amazon Pilot 日志查看器 ==="
echo "1. 查看所有服务日志"
echo "2. 查看特定服务日志"
echo "3. 查看 Caddy 访问日志"
echo "4. 查看 Caddy 错误日志"
echo "5. 查看系统日志"
echo "6. 实时监控日志"
echo ""

read -p "请选择 (1-6): " choice

case $choice in
    1)
        echo "=== 所有服务日志 ==="
        docker-compose logs --tail=100
        ;;
    2)
        echo "可用的服务:"
        echo "1. auth-service"
        echo "2. product-service"
        echo "3. competitor-service"
        echo "4. optimization-service"
        echo "5. notification-service"
        echo "6. asynq-worker"
        echo "7. asynq-scheduler"
        echo "8. asynq-monitor"
        echo "9. frontend"
        echo "10. prometheus"
        echo "11. grafana"
        echo "12. redis"
        read -p "请选择服务 (1-12): " service_choice
        
        case $service_choice in
            1) docker-compose logs --tail=100 auth-service ;;
            2) docker-compose logs --tail=100 product-service ;;
            3) docker-compose logs --tail=100 competitor-service ;;
            4) docker-compose logs --tail=100 optimization-service ;;
            5) docker-compose logs --tail=100 notification-service ;;
            6) docker-compose logs --tail=100 asynq-worker ;;
            7) docker-compose logs --tail=100 asynq-scheduler ;;
            8) docker-compose logs --tail=100 asynq-monitor ;;
            9) docker-compose logs --tail=100 frontend ;;
            10) docker-compose logs --tail=100 prometheus ;;
            11) docker-compose logs --tail=100 grafana ;;
            12) docker-compose logs --tail=100 redis ;;
            *) echo "无效选择" ;;
        esac
        ;;
    3)
        echo "=== Caddy 访问日志 ==="
        tail -100 $CADDY_LOG_DIR/access.log
        ;;
    4)
        echo "=== Caddy 错误日志 ==="
        tail -100 $CADDY_LOG_DIR/error.log
        ;;
    5)
        echo "=== 系统日志 ==="
        journalctl -u docker --tail=50
        ;;
    6)
        echo "=== 实时监控日志 ==="
        echo "按 Ctrl+C 退出"
        docker-compose logs -f
        ;;
    *)
        echo "无效选择"
        ;;
esac
