#!/bin/bash

# Database Migration Script
# Purpose: Apply new database migrations for Amazon Pilot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Database connection
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-amazon123}
DB_NAME=${DB_NAME:-amazon_pilot}

PSQL_CMD="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"

print_info "🗃️  Running Amazon Pilot Database Migrations..."
print_info "📍 Target: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# Create schema_migrations table if not exists
print_info "📋 Creating migrations tracking table..."
$PSQL_CMD -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
" 2>/dev/null || true

# Check existing migrations
print_info "🔍 Checking applied migrations..."
APPLIED_MIGRATIONS=$($PSQL_CMD -t -c "SELECT version FROM schema_migrations ORDER BY applied_at;" 2>/dev/null | xargs)
print_info "Applied migrations: $APPLIED_MIGRATIONS"

# Apply new migrations
MIGRATIONS_DIR="deployments/migrations"

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    print_error "Migrations directory not found: $MIGRATIONS_DIR"
    exit 1
fi

for migration_file in "$MIGRATIONS_DIR"/*.sql; do
    if [[ -f "$migration_file" ]]; then
        migration_name=$(basename "$migration_file" .sql)

        # Check if already applied
        if echo "$APPLIED_MIGRATIONS" | grep -q "$migration_name"; then
            print_info "⏭️  Skipping $migration_name (already applied)"
            continue
        fi

        print_info "🔄 Applying migration: $migration_name"

        # Apply migration
        if $PSQL_CMD -f "$migration_file"; then
            print_success "✅ Migration $migration_name applied successfully"
        else
            print_error "❌ Migration $migration_name failed"
            exit 1
        fi
    fi
done

# Verify new tables
print_info "🔍 Verifying new tables..."
NEW_TABLES=$($PSQL_CMD -t -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('product_review_history', 'product_buybox_history');
" 2>/dev/null | xargs)

if [[ "$NEW_TABLES" == *"product_review_history"* ]] && [[ "$NEW_TABLES" == *"product_buybox_history"* ]]; then
    print_success "✅ All required tables created successfully"
    print_success "📊 Tables: product_review_history, product_buybox_history"
else
    print_warning "⚠️  Some tables may not have been created: $NEW_TABLES"
fi

print_success "🎉 Database migrations completed successfully!"
print_info "📋 Summary:"
print_info "   • Added product_review_history table (track review changes)"
print_info "   • Added product_buybox_history table (track Buy Box changes)"
print_info "   • Supports questions.md requirements for complete tracking"