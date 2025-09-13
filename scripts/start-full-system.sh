#!/bin/bash

# Amazon Pilot 完整系统启动脚本
# 包含所有微服务、网关、前端、异步任务系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 启动完整的 Amazon Pilot 系统..."
echo "📁 项目根目录: $PROJECT_ROOT"

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 检查必要的依赖
echo "🔍 检查系统依赖..."
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm 未安装"
    exit 1
fi

echo "✅ 依赖检查完成"

# 函数：检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  端口 $port 已被占用，尝试关闭..."
        lsof -Pi :$port -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# 清理可能占用的端口
echo "🧹 清理端口..."
check_port 8080  # Gateway
check_port 8888  # Auth
check_port 8889  # Product  
check_port 8890  # Competitor
check_port 8891  # Optimization
check_port 8892  # Notification
check_port 3000  # Frontend

echo "✅ 端口清理完成"

# 启动后端服务
echo ""
echo "🔧 启动后端微服务..."

echo "1️⃣  启动 Auth 服务 (端口 8888)..."
./scripts/start-service.sh auth &
AUTH_PID=$!
sleep 3

echo "2️⃣  启动 Product 服务 (端口 8889)..."
./scripts/start-service.sh product &
PRODUCT_PID=$!
sleep 3

echo "3️⃣  启动 Competitor 服务 (端口 8890)..."
./scripts/start-service.sh competitor &
COMPETITOR_PID=$!
sleep 3

echo "4️⃣  启动 Optimization 服务 (端口 8891)..."
./scripts/start-service.sh optimization &
OPTIMIZATION_PID=$!
sleep 3

echo "5️⃣  启动 Notification 服务 (端口 8892)..."
./scripts/start-service.sh notification &
NOTIFICATION_PID=$!
sleep 3

# 启动API Gateway
echo "6️⃣  启动 API Gateway (端口 8080)..."
go run cmd/gateway/simple.go &
GATEWAY_PID=$!
sleep 3

# 启动异步任务系统
echo ""
echo "⚡ 启动异步任务系统..."

echo "7️⃣  启动 Worker (异步任务处理器)..."
./scripts/start-worker.sh &
WORKER_PID=$!
sleep 3

echo "8️⃣  启动 Scheduler (任务调度器)..."
./scripts/start-scheduler.sh &
SCHEDULER_PID=$!
sleep 3

# 启动前端
echo ""
echo "🌐 启动前端应用..."
echo "9️⃣  启动 Frontend (端口 3000)..."
builtin cd frontend && pnpm dev &
FRONTEND_PID=$!
builtin cd ..

# 等待所有服务启动
echo ""
echo "⏳ 等待所有服务启动..."
sleep 10

# 检查服务状态
echo ""
echo "🏥 检查服务健康状态..."

check_service() {
    local service_name=$1
    local url=$2
    echo -n "   $service_name: "
    if curl -s "$url" > /dev/null 2>&1; then
        echo "✅ 运行中"
    else
        echo "❌ 失败"
    fi
}

check_service "API Gateway" "http://localhost:8080/health"
check_service "Auth Service" "http://localhost:8080/api/auth/health"
check_service "Product Service" "http://localhost:8080/api/product/health"
check_service "Competitor Service" "http://localhost:8080/api/competitor/health"
check_service "Optimization Service" "http://localhost:8080/api/optimization/health"
check_service "Notification Service" "http://localhost:8080/api/notification/health"
check_service "Frontend" "http://localhost:3000"

echo ""
echo "🎉 Amazon Pilot 系统启动完成！"
echo ""
echo "📊 服务概览:"
echo "   • 🌐 前端:        http://localhost:3000"
echo "   • 🚪 API Gateway: http://localhost:8080"
echo "   • 🔐 认证服务:    http://localhost:8080/api/auth"
echo "   • 📦 产品服务:    http://localhost:8080/api/product"
echo "   • 🏆 竞争分析:    http://localhost:8080/api/competitor"
echo "   • 🚀 AI优化:      http://localhost:8080/api/optimization"
echo "   • 🔔 通知服务:    http://localhost:8080/api/notification"
echo "   • ⚡ 异步任务:    Worker + Scheduler 运行中"
echo ""
echo "🎯 核心功能已启用:"
echo "   • ✅ 用户认证和授权"
echo "   • ✅ 产品追踪和监控"
echo "   • ✅ 竞争对手分析"
echo "   • ✅ AI驱动的优化建议"
echo "   • ✅ 实时通知系统"
echo "   • ✅ 异常变化监控 (价格>10%, BSR>30%)"
echo "   • ✅ 企业级日志和监控"
echo ""
echo "🛑 停止系统: Ctrl+C"

# 优雅关闭处理
cleanup() {
    echo ""
    echo "🛑 正在关闭所有服务..."
    
    # 停止所有后台进程
    for pid in $FRONTEND_PID $SCHEDULER_PID $WORKER_PID $GATEWAY_PID $NOTIFICATION_PID $OPTIMIZATION_PID $COMPETITOR_PID $PRODUCT_PID $AUTH_PID; do
        if [ ! -z "$pid" ]; then
            kill $pid 2>/dev/null || true
        fi
    done
    
    # 等待进程关闭
    sleep 3
    
    echo "✅ 系统已关闭"
    exit 0
}

# 捕获信号
trap cleanup SIGINT SIGTERM

# 等待用户中断
echo "💡 系统正在运行... 按 Ctrl+C 停止"
wait