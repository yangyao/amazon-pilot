#!/bin/bash

# Amazon Pilot - Export Local PostgreSQL DDL Script
# Run this script from your local machine to export DDL from local PostgreSQL

set -e

echo "🚀 Amazon Pilot DDL Export Script"
echo "=================================="

# Configuration
LOCAL_HOST="${PGHOST:-localhost}"
LOCAL_PORT="${PGPORT:-5432}"
LOCAL_USER="${PGUSER:-postgres}"
LOCAL_DB="${PGDATABASE:-amazon_pilot}"
OUTPUT_FILE="amazon_pilot_production_ddl.sql"

echo "📋 Configuration:"
echo "  Host: $LOCAL_HOST"
echo "  Port: $LOCAL_PORT"
echo "  User: $LOCAL_USER"
echo "  Database: $LOCAL_DB"
echo "  Output: $OUTPUT_FILE"
echo ""

# Check if pg_dump exists
if ! command -v pg_dump &> /dev/null; then
    echo "❌ pg_dump not found. Please install PostgreSQL client tools."
    exit 1
fi

# Export DDL (schema only, production ready)
echo "📦 Exporting DDL from local PostgreSQL..."
pg_dump -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" \
  --schema-only \
  --no-owner \
  --no-privileges \
  --no-comments \
  --clean \
  --if-exists \
  --create \
  -f "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ DDL exported successfully to: $OUTPUT_FILE"
    echo ""
    echo "📊 File size: $(du -h $OUTPUT_FILE | cut -f1)"
    echo "📄 Line count: $(wc -l < $OUTPUT_FILE) lines"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Review the exported DDL file"
    echo "2. Move it to deployments/compose/init-db/ if needed"
    echo "3. Update docker-compose.yml to use the new DDL file"
else
    echo "❌ DDL export failed!"
    exit 1
fi

# Optional: Also export sample data
read -p "🤔 Do you want to export sample data as well? (y/N): " export_data
if [[ $export_data =~ ^[Yy]$ ]]; then
    DATA_FILE="amazon_pilot_sample_data.sql"
    echo "📦 Exporting sample data..."
    pg_dump -h "$LOCAL_HOST" -p "$LOCAL_PORT" -U "$LOCAL_USER" -d "$LOCAL_DB" \
      --data-only \
      --inserts \
      --no-owner \
      --no-privileges \
      -f "$DATA_FILE"

    if [ $? -eq 0 ]; then
        echo "✅ Sample data exported to: $DATA_FILE"
    else
        echo "⚠️  Data export failed, but DDL export was successful."
    fi
fi

echo ""
echo "🎉 Export completed!"