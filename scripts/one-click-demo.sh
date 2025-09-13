#!/bin/bash

# Amazon Pilot 一键Demo脚本
# 完整设置并演示系统功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Amazon Pilot 一键Demo启动"
echo "=============================="
echo "📁 项目根目录: $PROJECT_ROOT"

# 切换到项目根目录
builtin cd "$PROJECT_ROOT"

# 检查环境
echo ""
echo "🔍 环境检查..."

# 检查Go依赖
if ! command -v go &> /dev/null; then
    echo "❌ Go 未安装"
    exit 1
fi

# 检查pnpm
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm 未安装"
    exit 1
fi

# 检查PostgreSQL客户端
if ! command -v psql &> /dev/null; then
    echo "❌ psql 未安装，请安装PostgreSQL客户端"
    exit 1
fi

echo "✅ 环境检查通过"

# 提示用户设置API Token
echo ""
echo "🔑 API Token 检查..."
if [ -z "$APIFY_API_TOKEN" ]; then
    echo "⚠️  Apify API Token 未设置"
    echo ""
    echo "📋 请按以下步骤设置 (questions.md中提供的Token):"
    echo ""
    echo "   1. 访问 Apify 账户:"
    echo "      账号: account@transbiz.co"
    echo "      密码: *LEK7HgOiCkh"
    echo ""
    echo "   2. 获取API Token并设置:"
    echo "      export APIFY_API_TOKEN='your_actual_token'"
    echo ""
    echo "   3. 重新运行此脚本"
    echo ""
    read -p "是否继续使用模拟数据进行Demo? [y/N]: " choice
    if [[ $choice != [yY] ]]; then
        echo "❌ 已取消"
        exit 1
    fi
    echo "📝 将使用模拟数据进行Demo"
else
    echo "✅ Apify API Token 已设置"
fi

# 设置数据库连接
echo ""
echo "🗄️  数据库设置..."
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USER="${DB_USER:-postgres}"
export DB_PASSWORD="${DB_PASSWORD:-postgres}"
export DB_NAME="${DB_NAME:-amazon_pilot}"
export PGPASSWORD="$DB_PASSWORD"

echo "📊 数据库配置: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# 检查数据库连接
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 无法连接到数据库"
    echo "💡 请确保PostgreSQL运行在 $DB_HOST:$DB_PORT"
    echo "💡 数据库 '$DB_NAME' 存在且用户 '$DB_USER' 有权限"
    exit 1
fi

echo "✅ 数据库连接成功"

# 执行数据库迁移
echo ""
echo "📋 执行数据库迁移..."
if [ -x "./scripts/setup-partitions.sh" ]; then
    ./scripts/setup-partitions.sh
else
    echo "⚠️  分区设置脚本不存在，跳过"
fi

# 准备Demo数据
echo ""
echo "🎯 准备Demo数据..."
if [ -x "./scripts/setup-demo-data.sh" ]; then
    ./scripts/setup-demo-data.sh
else
    echo "⚠️  Demo数据脚本不存在，跳过"
fi

# 编译并测试Apify集成
echo ""
echo "🧪 测试Apify API集成..."
echo "📡 运行Apify Demo测试..."

if go run scripts/test-apify-demo.go; then
    echo "✅ Apify API测试成功"
else
    echo "⚠️  Apify API测试失败，但可以继续使用模拟数据"
fi

# 启动完整系统
echo ""
echo "🚀 启动Amazon Pilot完整系统..."
echo "🔄 这将启动所有微服务、API Gateway、异步任务系统和前端..."
echo ""

# 确认启动
read -p "准备启动系统，继续吗? [Y/n]: " choice
if [[ $choice == [nN] ]]; then
    echo "❌ 已取消"
    exit 1
fi

# 启动系统
if [ -x "./scripts/start-full-system.sh" ]; then
    echo "🎬 启动完整系统..."
    ./scripts/start-full-system.sh
else
    echo "❌ 系统启动脚本不存在"
    exit 1
fi