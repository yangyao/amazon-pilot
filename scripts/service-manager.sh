#!/bin/bash

# Amazon Pilot 统一服务管理脚本
# 支持启动、停止、重启、状态查看

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 服务配置 (service_name:port:description)
SERVICES=(
    "auth:8001:认证服务"
    "product:8002:产品服务"
    "competitor:8003:竞品服务"
    "optimization:8004:优化服务"
    "gateway:8080:API网关"
    "frontend:4000:前端应用"
    "worker:0:异步任务处理服务"
    "scheduler:0:定时调度服务"
)

# 显示帮助信息
show_help() {
    echo "Amazon Pilot 服务管理器"
    echo ""
    echo "用法:"
    echo "    $0 [命令] [服务名]"
    echo ""
    echo "命令:"
    echo "    start [service]     启动服务 (不指定服务名则启动所有)"
    echo "    stop [service]      停止服务 (不指定服务名则停止所有)"
    echo "    restart [service]   重启服务 (不指定服务名则重启所有)"
    echo "    status [service]    查看服务状态"
    echo "    list               列出所有可用服务"
    echo "    monitor            启动监控栈 (Prometheus + Loki + Grafana)"
    echo "    stop-monitor       停止监控栈"
    echo "    help               显示此帮助信息"
    echo ""
    echo "服务名:"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name port desc <<< "$service"
        echo "    $name        $desc (端口 $port)"
    done
    echo ""
    echo "示例:"
    echo "    $0 start                    # 启动所有服务"
    echo "    $0 start auth              # 只启动认证服务"
    echo "    $0 stop                    # 停止所有服务"
    echo "    $0 restart product         # 重启产品服务"
    echo "    $0 status                  # 查看所有服务状态"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1
}

# 停止端口上的服务
stop_port() {
    local port=$1
    local service_name=$2
    
    if check_port $port; then
        echo "   停止 $service_name (端口 $port): "
        lsof -Pi :$port -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
        sleep 1
        if check_port $port; then
            echo "❌ 停止失败"
            return 1
        else
            echo "✅ 已停止"
            return 0
        fi
    else
        echo "   $service_name (端口 $port): ⚪ 未运行"
        return 0
    fi
}

# 启动单个服务
start_service() {
    local service_name=$1
    
    case $service_name in
        "gateway")
            echo "   启动 API网关..."
            go run cmd/gateway/main.go 2>&1 | tee logs/gateway.log &
            ;;
        "frontend")
            echo "   启动前端应用..."
            (builtin cd frontend && pnpm dev 2>&1 | tee ../logs/frontend.log) &
            ;;
        "worker")
            echo "   启动异步任务处理服务..."
            # 先关闭可能存在的旧Worker进程
            pkill -f "go run cmd/worker/main.go" 2>/dev/null || true
            pkill -f "cmd/worker/main.go" 2>/dev/null || true
            pkill -f "worker/main.go" 2>/dev/null || true
            sleep 2
            go run cmd/worker/main.go 2>&1 | tee logs/worker.log &
            ;;
        "scheduler")
            echo "   启动定时调度服务..."
            # 先关闭可能存在的旧Scheduler进程
            pkill -f "go run cmd/scheduler/main.go" 2>/dev/null || true
            pkill -f "cmd/scheduler/main.go" 2>/dev/null || true
            pkill -f "scheduler/main.go" 2>/dev/null || true
            sleep 2
            go run cmd/scheduler/main.go 2>&1 | tee logs/scheduler.log &
            ;;
        *)
            echo "   启动 $service_name 服务..."
            ./scripts/start-service.sh $service_name 2>&1 | tee logs/$service_name.log &
            ;;
    esac
    
    # 等待服务启动
    sleep 3
}

# 检查服务健康状态
check_health() {
    local service_name=$1
    local port=$2
    
    case $service_name in
        "gateway")
            url="http://localhost:$port/health"
            ;;
        "frontend")
            url="http://localhost:$port"
            ;;
        *)
            url="http://localhost:8080/api/$service_name/health"
            ;;
    esac
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo "✅ 健康"
    else
        echo "❌ 异常"
    fi
}

# 显示服务状态
show_status() {
    local target_service=$1
    
    echo "🏥 服务状态检查..."
    echo ""
    
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name port desc <<< "$service"
        
        # 如果指定了服务名，只检查该服务
        if [[ -n "$target_service" && "$name" != "$target_service" ]]; then
            continue
        fi
        
        echo -n "   $desc (端口 $port): "
        if check_port $port; then
            echo -n "🟢 运行中 - "
            check_health $name $port
        else
            echo "⚪ 未运行"
        fi
    done
    echo ""
}

# 启动所有或指定服务
start_services() {
    local target_service=$1
    
    if [[ -n "$target_service" ]]; then
        echo "🚀 启动服务: $target_service"
        
        # 查找服务配置
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r name port desc <<< "$service"
            if [[ "$name" == "$target_service" ]]; then
                start_service $name
                echo "✅ $desc 启动完成"
                return 0
            fi
        done
        
        echo "❌ 未找到服务: $target_service"
        return 1
    else
        echo "🚀 启动所有服务..."
        
        # 按顺序启动服务
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r name port desc <<< "$service"
            if [[ "$name" != "frontend" ]]; then  # 前端最后启动
                echo "   启动 $desc..."
                start_service $name
            fi
        done
        
        # 启动前端
        echo "   启动前端应用..."
        start_service "frontend"
        
        echo ""
        echo "✅ 所有服务启动完成"
        show_status
    fi
}

# 停止所有或指定服务
stop_services() {
    local target_service=$1
    
    if [[ -n "$target_service" ]]; then
        echo "🛑 停止服务: $target_service"
        
        # 特殊处理无端口的服务
        if [[ "$target_service" == "worker" ]]; then
            echo "   停止异步任务处理服务..."
            pkill -f "worker/main.go" 2>/dev/null || true
            pkill -f "go run cmd/worker" 2>/dev/null || true
            echo "✅ Worker服务已停止"
            return 0
        elif [[ "$target_service" == "scheduler" ]]; then
            echo "   停止定时调度服务..."
            pkill -f "scheduler/main.go" 2>/dev/null || true
            pkill -f "go run cmd/scheduler" 2>/dev/null || true
            echo "✅ Scheduler服务已停止"
            return 0
        fi

        # 查找服务配置
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r name port desc <<< "$service"
            if [[ "$name" == "$target_service" ]]; then
                stop_port $port "$desc"
                return $?
            fi
        done
        
        echo "❌ 未找到服务: $target_service"
        return 1
    else
        echo "🛑 停止所有服务..."
        
        for service in "${SERVICES[@]}"; do
            IFS=':' read -r name port desc <<< "$service"
            stop_port $port "$desc"
        done
        
        # 清理相关进程
        echo ""
        echo "🧹 清理相关进程..."
        pkill -f "worker/main.go" 2>/dev/null || true
        pkill -f "scheduler/main.go" 2>/dev/null || true
        pkill -f "go run cmd/worker" 2>/dev/null || true
        pkill -f "go run cmd/scheduler" 2>/dev/null || true
        
        echo "✅ 所有服务已停止"
    fi
}

# 重启服务
restart_services() {
    local target_service=$1
    
    echo "🔄 重启服务..."
    stop_services $target_service
    sleep 2
    start_services $target_service
}

# 启动监控栈
start_monitoring() {
    echo "📊 启动监控栈 (Prometheus + Loki + Grafana)..."
    
    # 检查 docker compose 文件是否存在
    compose_file="deployments/compose/docker-compose.dev.yml"
    if [[ ! -f "$compose_file" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $compose_file"
        return 1
    fi
    
    # 启动监控服务
    echo "   启动 Prometheus..."
    docker-compose -f "$compose_file" up -d prometheus
    
    echo "   启动 Loki..."
    docker-compose -f "$compose_file" up -d loki
    
    echo "   启动 Promtail..."
    docker-compose -f "$compose_file" up -d promtail
    
    echo "   启动 Grafana..."
    docker-compose -f "$compose_file" up -d grafana
    
    sleep 5
    
    echo ""
    echo "✅ 监控栈启动完成！"
    echo ""
    echo "📊 监控服务访问地址:"
    echo "   • Prometheus: http://localhost:9090"
    echo "   • Grafana:    http://localhost:3000 (admin/admin123)"
    echo "   • Loki:       http://localhost:3100"
}

# 停止监控栈
stop_monitoring() {
    echo "🛑 停止监控栈..."
    
    compose_file="deployments/compose/docker-compose.dev.yml"
    if [[ ! -f "$compose_file" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $compose_file"
        return 1
    fi
    
    # 停止监控服务
    docker-compose -f "$compose_file" stop grafana promtail loki prometheus
    
    echo "✅ 监控栈已停止"
}

# 主函数
main() {
    case ${1:-""} in
        "start")
            start_services $2
            ;;
        "stop")
            stop_services $2
            ;;
        "restart")
            restart_services $2
            ;;
        "status")
            show_status $2
            ;;
        "list")
            echo "可用服务:"
            for service in "${SERVICES[@]}"; do
                IFS=':' read -r name port desc <<< "$service"
                echo "   $name - $desc (端口 $port)"
            done
            ;;
        "monitor")
            start_monitoring
            ;;
        "stop-monitor")
            stop_monitoring
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            echo "❌ 未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"