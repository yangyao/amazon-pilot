#!/bin/bash

# 设置分区表的专用脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🗄️  设置 change_events 分区表..."

# 数据库连接配置
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-amazon_pilot}"

echo "📊 数据库配置: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# 设置密码
export PGPASSWORD="$DB_PASSWORD"

# 执行分区migration
echo "📋 创建分区表和触发器..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/migrations/006_change_events_partitioned.sql"

echo "🔧 设置混合触发器..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$PROJECT_ROOT/migrations/005_hybrid_triggers.sql"

# 显示分区状态
echo ""
echo "📊 分区表状态:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    tablename as partition_name,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) as size
FROM pg_tables 
WHERE tablename LIKE 'change_events_%'
ORDER BY tablename;
"

echo ""
echo "🏥 创建监控函数测试:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    'Function Created' as status,
    'get_change_events_health' as function_name
WHERE EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'get_change_events_health'
);
"

echo ""
echo "✅ 分区表设置完成！"
echo ""
echo "📋 可用的管理命令:"
echo "   • 创建新分区: SELECT create_monthly_partition('2024-03-01');"
echo "   • 清理旧分区: SELECT drop_old_partitions(3);"
echo "   • 分区维护:   SELECT maintain_change_events_partitions();"
echo "   • 健康检查:   SELECT * FROM get_change_events_health();"
echo "   • 分区统计:   SELECT * FROM change_events_partition_stats;"