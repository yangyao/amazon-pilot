#!/bin/bash

# run-migrations.sh
# 执行 Supabase 数据库 migrations

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查环境
check_environment() {
    if [[ ! -f ".env" ]]; then
        print_error ".env 文件未找到"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        print_error "psql 命令未找到，请安装 PostgreSQL 客户端"
        exit 1
    fi
    
    print_info "环境检查通过"
}

# 加载环境变量
load_env() {
    source .env
    
    if [[ -z "$SUPABASE_URL" ]]; then
        print_error "SUPABASE_URL 环境变量未设置"
        exit 1
    fi
    
    print_info "环境变量加载完成"
}

# 执行 migration 文件
run_migration() {
    local migration_file="$1"
    local migration_name=$(basename "$migration_file" .sql)
    
    print_info "执行 migration: $migration_name"
    
    if psql "$SUPABASE_URL" -f "$migration_file"; then
        print_success "✅ $migration_name 执行成功"
    else
        print_error "❌ $migration_name 执行失败"
        exit 1
    fi
}

# 主函数
main() {
    print_info "🚀 开始执行 Supabase migrations..."
    
    check_environment
    load_env
    
    # 按顺序执行所有 migration 文件
    for migration_file in migrations/*.sql; do
        if [[ -f "$migration_file" ]]; then
            run_migration "$migration_file"
        fi
    done
    
    print_success "🎉 所有 migrations 执行完成！"
    
    # 验证表创建
    print_info "🔍 验证表结构..."
    psql "$SUPABASE_URL" -c "\dt" | head -20
    
    print_success "📊 数据库已准备就绪！"
}

main "$@"