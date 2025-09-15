#!/bin/bash

# Amazon Pilot 统一服务管理脚本
# 支持启动、停止、重启、状态查看

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 确保 logs 目录存在
mkdir -p logs

# Docker Compose 文件路径
COMPOSE_DIR="deployments/compose"
BASE_COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
LOCAL_COMPOSE_FILE="$COMPOSE_DIR/docker-compose.local.yml"

# 开发环境使用组合文件（类似 compose-up.sh）
ENV_FILE=".env"
DOCKER_COMPOSE_FILES="-f $BASE_COMPOSE_FILE -f $LOCAL_COMPOSE_FILE"

# 如果存在 .env 文件，添加 --env-file 参数
if [[ -f "$ENV_FILE" ]]; then
    DOCKER_COMPOSE_CMD="docker-compose $DOCKER_COMPOSE_FILES --env-file $ENV_FILE"
else
    DOCKER_COMPOSE_CMD="docker-compose $DOCKER_COMPOSE_FILES"
fi

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
    echo "    $0 [命令] [模式] [服务名]"
    echo ""
    echo "命令:"
    echo "    start [service]                    本地启动服务"
    echo "    stop [service]                     本地停止服务"
    echo "    restart [service]                  本地重启服务"
    echo "    status [service]                   查看本地服务状态"
    echo ""
    echo "    compose-up                         Docker Compose 启动开发环境 (构建+启动)"
    echo "    compose-down                       Docker Compose 停止开发环境"
    echo "    docker [service]                   Docker 启动/停止服务 (自动检测状态)"
    echo "    docker-start [service]             Docker 启动服务"
    echo "    docker-stop [service]              Docker 停止服务"
    echo "    docker-build                       Docker 构建所有镜像"
    echo "    docker-status [service]            Docker 服务状态"
    echo "    docker-logs [service]              查看 Docker 服务日志"
    echo ""
    echo "    list                               列出所有可用服务"
    echo "    monitor                            启动监控栈 (Prometheus + Loki + Grafana)"
    echo "    stop-monitor                       停止监控栈"
    echo "    help                               显示此帮助信息"
    echo ""
    echo "服务名:"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name port desc <<< "$service"
        echo "    $name        $desc (端口 $port)"
    done
    echo ""
    echo "示例:"
    echo "    $0 start                   # 本地启动所有服务"
    echo "    $0 start auth              # 本地启动认证服务"
    echo "    $0 compose-up              # Docker 启动开发环境 (推荐)"
    echo "    $0 compose-down            # Docker 停止开发环境"
    echo "    $0 docker                  # Docker 启动/停止所有服务"
    echo "    $0 docker-build            # Docker 构建所有镜像"
    echo "    $0 status                  # 查看本地服务状态"
}

# Docker 服务启动
start_docker_services() {
    local target_service=$1

    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    if [[ -n "$target_service" ]]; then
        echo "🚀 Docker 启动服务: $target_service"

        # 查找 Docker 服务名映射
        local docker_service=""
        case $target_service in
            "auth") docker_service="amazon-pilot-auth-service" ;;
            "product") docker_service="amazon-pilot-product-service" ;;
            "competitor") docker_service="amazon-pilot-competitor-service" ;;
            "optimization") docker_service="amazon-pilot-optimization-service" ;;
            "gateway") docker_service="amazon-pilot-gateway" ;;
            "frontend") docker_service="amazon-pilot-frontend-service" ;;
            "worker") docker_service="amazon-pilot-worker" ;;
            "scheduler") docker_service="amazon-pilot-scheduler" ;;
            "postgres") docker_service="amazon-pilot-postgres" ;;
            "redis") docker_service="amazon-pilot-redis" ;;
            *)
                echo "❌ 未知服务: $target_service"
                return 1
                ;;
        esac

        $DOCKER_COMPOSE_CMD up -d "$docker_service"
        echo "✅ $target_service 服务启动完成"
    else
        echo "🚀 Docker 启动所有服务..."
        $DOCKER_COMPOSE_CMD up -d
        echo "✅ 所有服务启动完成"
    fi
}

# Docker 服务停止
stop_docker_services() {
    local target_service=$1

    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    if [[ -n "$target_service" ]]; then
        echo "🛑 Docker 停止服务: $target_service"

        # 查找 Docker 服务名映射
        local docker_service=""
        case $target_service in
            "auth") docker_service="amazon-pilot-auth-service" ;;
            "product") docker_service="amazon-pilot-product-service" ;;
            "competitor") docker_service="amazon-pilot-competitor-service" ;;
            "optimization") docker_service="amazon-pilot-optimization-service" ;;
            "gateway") docker_service="amazon-pilot-gateway" ;;
            "frontend") docker_service="amazon-pilot-frontend-service" ;;
            "worker") docker_service="amazon-pilot-worker" ;;
            "scheduler") docker_service="amazon-pilot-scheduler" ;;
            "postgres") docker_service="amazon-pilot-postgres" ;;
            "redis") docker_service="amazon-pilot-redis" ;;
            *)
                echo "❌ 未知服务: $target_service"
                return 1
                ;;
        esac

        $DOCKER_COMPOSE_CMD stop "$docker_service"
        echo "✅ $target_service 服务已停止"
    else
        echo "🛑 Docker 停止所有服务..."
        $DOCKER_COMPOSE_CMD down
        echo "✅ 所有服务已停止"
    fi
}

# Docker 服务状态
show_docker_status() {
    local target_service=$1

    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    echo "🏥 Docker 服务状态检查..."
    echo ""

    if [[ -n "$target_service" ]]; then
        # 查找 Docker 服务名映射
        local docker_service=""
        case $target_service in
            "auth") docker_service="amazon-pilot-auth-service" ;;
            "product") docker_service="amazon-pilot-product-service" ;;
            "competitor") docker_service="amazon-pilot-competitor-service" ;;
            "optimization") docker_service="amazon-pilot-optimization-service" ;;
            "gateway") docker_service="amazon-pilot-gateway" ;;
            "frontend") docker_service="amazon-pilot-frontend-service" ;;
            "worker") docker_service="amazon-pilot-worker" ;;
            "scheduler") docker_service="amazon-pilot-scheduler" ;;
            "postgres") docker_service="amazon-pilot-postgres" ;;
            "redis") docker_service="amazon-pilot-redis" ;;
            *)
                echo "❌ 未知服务: $target_service"
                return 1
                ;;
        esac

        $DOCKER_COMPOSE_CMD ps "$docker_service"
    else
        $DOCKER_COMPOSE_CMD ps
    fi
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
            # 直接启动其他服务
            case $service_name in
                "auth")
                    go run cmd/auth/main.go 2>&1 | tee logs/auth.log &
                    ;;
                "product")
                    go run cmd/product/main.go 2>&1 | tee logs/product.log &
                    ;;
                "competitor")
                    go run cmd/competitor/main.go 2>&1 | tee logs/competitor.log &
                    ;;
                "optimization")
                    go run cmd/optimization/main.go 2>&1 | tee logs/optimization.log &
                    ;;
                *)
                    echo "❌ 未知服务: $service_name"
                    return 1
                    ;;
            esac
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

# 启动所有或指定服务 (本地模式)
start_local_services() {
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

# 停止所有或指定服务 (本地模式)
stop_local_services() {
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
    local mode=$1
    local target_service=$2

    echo "🔄 重启服务..."
    if [[ "$mode" == "docker" ]]; then
        stop_docker_services $target_service
        sleep 2
        start_docker_services $target_service
    else
        stop_local_services $target_service
        sleep 2
        start_local_services $target_service
    fi
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

# 智能 Docker 切换（检测状态并自动启动/停止）
docker_toggle() {
    local target_service=$1

    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    # 检查 Docker 服务状态
    if [[ -n "$target_service" ]]; then
        local docker_service=""
        case $target_service in
            "auth") docker_service="amazon-pilot-auth-service" ;;
            "product") docker_service="amazon-pilot-product-service" ;;
            "competitor") docker_service="amazon-pilot-competitor-service" ;;
            "optimization") docker_service="amazon-pilot-optimization-service" ;;
            "gateway") docker_service="amazon-pilot-gateway" ;;
            "frontend") docker_service="amazon-pilot-frontend-service" ;;
            "worker") docker_service="amazon-pilot-worker" ;;
            "scheduler") docker_service="amazon-pilot-scheduler" ;;
            "postgres") docker_service="amazon-pilot-postgres" ;;
            "redis") docker_service="amazon-pilot-redis" ;;
            *)
                echo "❌ 未知服务: $target_service"
                return 1
                ;;
        esac

        # 检查容器状态
        if docker ps --format "table {{.Names}}" | grep -q "^${docker_service}$"; then
            echo "🛑 Docker 停止服务: $target_service"
            $DOCKER_COMPOSE_CMD stop "$docker_service"
        else
            # 如果是应用服务（非基础设施），先构建镜像
            if [[ "$target_service" != "postgres" && "$target_service" != "redis" ]]; then
                echo "🔨 构建 Docker 镜像..."
                if [[ -f "scripts/build-docker-images.sh" ]]; then
                    bash scripts/build-docker-images.sh
                else
                    echo "⚠️  未找到构建脚本，跳过构建步骤"
                fi
            fi

            echo "🚀 Docker 启动服务: $target_service"
            $DOCKER_COMPOSE_CMD up -d "$docker_service"
        fi
    else
        # 检查是否有任何容器在运行
        if $DOCKER_COMPOSE_CMD ps -q | head -1 | grep -q .; then
            echo "🛑 Docker 停止所有服务..."
            $DOCKER_COMPOSE_CMD down
        else
            echo "🔨 构建 Docker 镜像..."
            if [[ -f "scripts/build-docker-images.sh" ]]; then
                bash scripts/build-docker-images.sh
            else
                echo "⚠️  未找到构建脚本，跳过构建步骤"
            fi

            echo "🚀 Docker 启动所有服务..."
            $DOCKER_COMPOSE_CMD up -d

            echo ""
            echo "📊 服务状态:"
            $DOCKER_COMPOSE_CMD ps
        fi
    fi
}

# Docker Compose 启动开发环境
compose_up() {
    echo "🚀 Docker Compose 启动开发环境..."
    echo "📁 使用配置文件:"
    echo "   - $BASE_COMPOSE_FILE"
    echo "   - $LOCAL_COMPOSE_FILE"
    if [[ -f "$ENV_FILE" ]]; then
        echo "   - $ENV_FILE (环境变量)"
    fi
    echo ""

    # 检查必要文件
    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    # 构建镜像
    echo "🔨 构建 Docker 镜像..."
    if [[ -f "scripts/build-docker-images.sh" ]]; then
        bash scripts/build-docker-images.sh
    else
        echo "⚠️  未找到构建脚本，使用 docker-compose build"
        $DOCKER_COMPOSE_CMD build
    fi

    # 启动服务
    echo ""
    echo "🚀 启动所有服务..."
    $DOCKER_COMPOSE_CMD up -d

    # 显示状态
    echo ""
    echo "📊 服务状态:"
    $DOCKER_COMPOSE_CMD ps

    echo ""
    echo "✅ 开发环境启动完成！"
    echo ""
    echo "🌐 访问地址:"
    echo "   前端应用: http://localhost/"
    echo "   API网关:  http://localhost/api/"
    echo ""
    echo "📋 管理命令:"
    echo "   查看日志: $0 docker-logs"
    echo "   停止环境: $0 compose-down"
}

# Docker Compose 停止开发环境
compose_down() {
    echo "🛑 Docker Compose 停止开发环境..."

    # 检查必要文件
    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    # 停止并删除容器
    $DOCKER_COMPOSE_CMD down

    echo "✅ 开发环境已停止"
}

# Docker 构建镜像
docker_build() {
    echo "🔨 构建 Docker 镜像..."

    if [[ -f "scripts/build-docker-images.sh" ]]; then
        bash scripts/build-docker-images.sh
        echo "✅ Docker 镜像构建完成"
    else
        echo "❌ 未找到构建脚本: scripts/build-docker-images.sh"
        echo "📋 备用方案: 使用 docker-compose build"

        if [[ -f "$BASE_COMPOSE_FILE" ]]; then
            $DOCKER_COMPOSE_CMD build
            echo "✅ Docker 镜像构建完成"
        else
            echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
            return 1
        fi
    fi
}

# Docker 查看日志
docker_logs() {
    local target_service=$1

    if [[ ! -f "$BASE_COMPOSE_FILE" ]]; then
        echo "❌ 未找到 Docker Compose 文件: $BASE_COMPOSE_FILE"
        return 1
    fi

    if [[ -n "$target_service" ]]; then
        # 查找 Docker 服务名映射
        local docker_service=""
        case $target_service in
            "auth") docker_service="amazon-pilot-auth-service" ;;
            "product") docker_service="amazon-pilot-product-service" ;;
            "competitor") docker_service="amazon-pilot-competitor-service" ;;
            "optimization") docker_service="amazon-pilot-optimization-service" ;;
            "gateway") docker_service="amazon-pilot-gateway" ;;
            "frontend") docker_service="amazon-pilot-frontend-service" ;;
            "worker") docker_service="amazon-pilot-worker" ;;
            "scheduler") docker_service="amazon-pilot-scheduler" ;;
            "postgres") docker_service="amazon-pilot-postgres" ;;
            "redis") docker_service="amazon-pilot-redis" ;;
            *)
                echo "❌ 未知服务: $target_service"
                return 1
                ;;
        esac

        echo "📋 查看 $target_service 服务日志 (按 Ctrl+C 退出):"
        $DOCKER_COMPOSE_CMD logs -f "$docker_service"
    else
        echo "📋 查看所有服务日志 (按 Ctrl+C 退出):"
        $DOCKER_COMPOSE_CMD logs -f
    fi
}

# 主函数
main() {
    local command=${1:-""}
    local service=${2:-""}

    case $command in
        "start")
            start_local_services $service
            ;;
        "stop")
            stop_local_services $service
            ;;
        "restart")
            restart_services "local" $service
            ;;
        "status")
            show_status $service
            ;;
        "compose-up")
            compose_up
            ;;
        "compose-down")
            compose_down
            ;;
        "docker")
            docker_toggle $service
            ;;
        "docker-start")
            start_docker_services $service
            ;;
        "docker-stop")
            stop_docker_services $service
            ;;
        "docker-build")
            docker_build
            ;;
        "docker-status")
            show_docker_status $service
            ;;
        "docker-logs")
            docker_logs $service
            ;;
        "list")
            echo "可用服务:"
            for svc in "${SERVICES[@]}"; do
                IFS=':' read -r name port desc <<< "$svc"
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
            echo "❌ 未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"