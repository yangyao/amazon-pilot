#!/bin/bash

# Amazon Pilot 服务管理脚本

SERVICES=(
    "auth-service:认证服务"
    "product-service:产品服务"
    "competitor-service:竞品服务"
    "optimization-service:优化服务"
    "notification-service:通知服务"
    "frontend:前端服务"
    "asynq-worker:后台任务"
    "asynq-scheduler:任务调度"
    "asynq-monitor:任务监控"
    "prometheus:监控收集"
    "grafana:监控面板"
    "redis:缓存数据库"
)

show_menu() {
    echo "=== Amazon Pilot 服务管理器 ==="
    echo "1. 查看所有服务状态"
    echo "2. 启动所有服务"
    echo "3. 停止所有服务"
    echo "4. 重启所有服务"
    echo "5. 管理单个服务"
    echo "6. 查看服务日志"
    echo "7. 查看资源使用情况"
    echo "8. 清理系统"
    echo "9. 退出"
    echo ""
}

show_service_menu() {
    echo "=== 选择服务 ==="
    for i in "${!SERVICES[@]}"; do
        IFS=':' read -r service_name service_desc <<< "${SERVICES[$i]}"
        echo "$((i+1)). $service_desc ($service_name)"
    done
    echo "$((${#SERVICES[@]}+1)). 返回主菜单"
    echo ""
}

manage_single_service() {
    show_service_menu
    read -p "请选择服务 (1-$((${#SERVICES[@]}+1))): " choice
    
    if [ "$choice" -eq $((${#SERVICES[@]}+1)) ]; then
        return
    fi
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le ${#SERVICES[@]} ]; then
        IFS=':' read -r service_name service_desc <<< "${SERVICES[$((choice-1))]}"
        
        echo ""
        echo "=== 管理 $service_desc ==="
        echo "1. 启动服务"
        echo "2. 停止服务"
        echo "3. 重启服务"
        echo "4. 查看日志"
        echo "5. 查看状态"
        echo "6. 返回"
        echo ""
        
        read -p "请选择操作 (1-6): " action
        
        case $action in
            1)
                echo "启动 $service_desc..."
                docker-compose up -d $service_name
                ;;
            2)
                echo "停止 $service_desc..."
                docker-compose stop $service_name
                ;;
            3)
                echo "重启 $service_desc..."
                docker-compose restart $service_name
                ;;
            4)
                echo "查看 $service_desc 日志..."
                docker-compose logs -f $service_name
                ;;
            5)
                echo "$service_desc 状态:"
                docker-compose ps $service_name
                ;;
            6)
                return
                ;;
            *)
                echo "无效选择"
                ;;
        esac
    else
        echo "无效选择"
    fi
}

show_logs() {
    echo "=== 日志查看 ==="
    echo "1. 查看所有服务日志"
    echo "2. 查看错误日志"
    echo "3. 实时监控日志"
    echo "4. 查看特定服务日志"
    echo "5. 返回"
    echo ""
    
    read -p "请选择 (1-5): " choice
    
    case $choice in
        1)
            docker-compose logs --tail=100
            ;;
        2)
            docker-compose logs --tail=100 | grep -i error
            ;;
        3)
            echo "按 Ctrl+C 退出实时监控"
            docker-compose logs -f
            ;;
        4)
            manage_single_service
            ;;
        5)
            return
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

show_resources() {
    echo "=== 资源使用情况 ==="
    echo "Docker 容器资源使用:"
    docker stats --no-stream
    
    echo ""
    echo "磁盘使用情况:"
    df -h
    
    echo ""
    echo "内存使用情况:"
    free -h
    
    echo ""
    echo "Docker 系统信息:"
    docker system df
}

cleanup_system() {
    echo "=== 系统清理 ==="
    echo "1. 清理未使用的镜像"
    echo "2. 清理未使用的容器"
    echo "3. 清理未使用的网络"
    echo "4. 清理未使用的卷"
    echo "5. 全面清理"
    echo "6. 返回"
    echo ""
    
    read -p "请选择 (1-6): " choice
    
    case $choice in
        1)
            echo "清理未使用的镜像..."
            docker image prune -f
            ;;
        2)
            echo "清理未使用的容器..."
            docker container prune -f
            ;;
        3)
            echo "清理未使用的网络..."
            docker network prune -f
            ;;
        4)
            echo "清理未使用的卷..."
            docker volume prune -f
            ;;
        5)
            echo "全面清理..."
            docker system prune -af
            ;;
        6)
            return
            ;;
        *)
            echo "无效选择"
            ;;
    esac
}

# 主循环
while true; do
    show_menu
    read -p "请选择 (1-9): " choice
    
    case $choice in
        1)
            echo "=== 服务状态 ==="
            docker-compose ps
            echo ""
            ;;
        2)
            echo "启动所有服务..."
            docker-compose up -d
            echo "服务启动完成"
            echo ""
            ;;
        3)
            echo "停止所有服务..."
            docker-compose down
            echo "服务停止完成"
            echo ""
            ;;
        4)
            echo "重启所有服务..."
            docker-compose restart
            echo "服务重启完成"
            echo ""
            ;;
        5)
            manage_single_service
            ;;
        6)
            show_logs
            ;;
        7)
            show_resources
            ;;
        8)
            cleanup_system
            ;;
        9)
            echo "退出服务管理器"
            exit 0
            ;;
        *)
            echo "无效选择，请重新输入"
            echo ""
            ;;
    esac
done
