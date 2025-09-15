# Database Migration Management

## 數據庫遷移管理

### 遷移文件結構

#### 文件命名規範
```
deployments/migrations/
├── 001_initial_schema.sql        # 初始化表結構
├── 002_add_user_settings.sql     # 已移除（保留歷史記錄）
├── 003_add_history_tables.sql    # 歷史追蹤表 (新增)
└── 004_add_competitor_tables.sql # 競品分析表 (待添加)
```

#### 版本控制
- **3位數字前綴** → 確保執行順序
- **描述性名稱** → 清楚表達變更內容
- **單一職責** → 每個文件處理一個功能模組

### 當前遷移狀態

#### 已應用遷移
1. **003_add_history_tables** ✅
   - product_review_history (評論歷史)
   - product_buybox_history (Buy Box歷史)
   - 支援 questions.md 完整追蹤要求

#### 待添加遷移
1. **004_add_competitor_tables** (規劃中)
   - competitor_analysis_groups
   - competitor_products
   - competitor_analysis_reports

2. **005_add_optimization_tables** (規劃中)
   - optimization_tasks
   - optimization_suggestions
   - ab_test_results

3. **006_add_notification_tables** (規劃中)
   - notifications
   - notification_templates
   - notification_settings

### 遷移執行

#### 自動執行腳本
```bash
# 執行所有新遷移
./scripts/run-migrations.sh

# 腳本功能：
# - 創建 schema_migrations 追蹤表
# - 檢查已應用遷移，避免重複
# - 按順序執行新遷移
# - 驗證表創建結果
# - 提供詳細日誌輸出
```

#### 手動執行
```bash
# 單獨執行特定遷移
psql -h localhost -U postgres -d amazon_pilot -f deployments/migrations/003_add_history_tables.sql

# 檢查遷移狀態
psql -h localhost -U postgres -d amazon_pilot -c "SELECT * FROM schema_migrations ORDER BY applied_at;"
```

### 遷移最佳實踐

#### 1. 向後兼容
```sql
-- ✅ 好的做法：添加可選欄位
ALTER TABLE products ADD COLUMN subcategory VARCHAR(255);

-- ❌ 避免：刪除現有欄位
-- ALTER TABLE products DROP COLUMN title;
```

#### 2. 數據安全
```sql
-- 重要變更前備份
CREATE TABLE products_backup AS SELECT * FROM products;

-- 使用事務確保原子性
BEGIN;
  -- 執行變更
  ALTER TABLE products ADD COLUMN new_field VARCHAR(255);
  -- 驗證結果
  SELECT COUNT(*) FROM products;
COMMIT;
```

#### 3. 性能考慮
```sql
-- 大表變更使用 CONCURRENTLY
CREATE INDEX CONCURRENTLY idx_products_new_field ON products(new_field);

-- 避免在高峰期執行重型遷移
-- 建議在維護窗口期間執行
```

### 遷移回滾

#### 1. 回滾腳本
```sql
-- 每個遷移都應該有對應的回滾腳本
-- deployments/rollbacks/003_rollback_history_tables.sql

DROP TABLE IF EXISTS product_review_history;
DROP TABLE IF EXISTS product_buybox_history;
DELETE FROM schema_migrations WHERE version = '003_add_history_tables';
```

#### 2. 回滾策略
- **測試環境先驗證** → 確保回滾腳本正確
- **備份重要數據** → 回滾前備份關鍵表
- **分步回滾** → 大型變更分多步回滾

### 環境管理

#### 1. 環境同步
```bash
# 開發環境
DB_HOST=localhost DB_USER=postgres ./scripts/run-migrations.sh

# 測試環境
DB_HOST=test-db DB_USER=test_user ./scripts/run-migrations.sh

# 生產環境 (需要額外驗證)
DB_HOST=prod-db DB_USER=prod_user ./scripts/run-migrations.sh
```

#### 2. 遷移驗證
```sql
-- 驗證表結構一致性
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name LIKE 'product_%'
ORDER BY table_name, ordinal_position;
```

### 監控和告警

#### 1. 遷移監控
```sql
-- 監控遷移執行時間
SELECT
    version,
    applied_at,
    applied_at - LAG(applied_at) OVER (ORDER BY applied_at) as duration
FROM schema_migrations
ORDER BY applied_at DESC;
```

#### 2. 表大小監控
```sql
-- 監控歷史表增長
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(table_name)) as size,
    pg_total_relation_size(table_name) as size_bytes
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE '%_history'
ORDER BY pg_total_relation_size(table_name) DESC;
```

---

**遷移責任**: 每個服務負責自己的表遷移文件
**執行時機**: 部署前自動執行，確保數據庫同步
**最後更新**: 2025-09-13
