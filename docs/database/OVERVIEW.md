# Amazon Pilot 數據庫架構概覽

## 概述

Amazon 賣家產品監控與優化工具的數據庫架構設計，支援微服務架構。

## 技術架構

### 主要資料庫：PostgreSQL with TimescaleDB
- **版本**: PostgreSQL 15+ with TimescaleDB
- **主要用途**: 持久化資料儲存和時間序列數據
- **包含**: 用戶資料、產品資料、追蹤記錄、歷史數據、分析結果
- **ORM**: Gorm v2

### 快取層：Redis
- **版本**: Redis 7+
- **主要用途**: 高頻存取資料快取、任務隊列 (Asynq)
- **TTL 策略**: 不同資料類型設定不同過期時間

## 微服務數據庫劃分

### 1. Auth Service (認證服務)
- **主要表**: users, user_settings
- **職責**: 用戶認證、授權、配置管理
- **詳細設計**: [USERS.md](./USERS.md)

### 2. Product Service (產品服務)
- **主要表**: products, tracked_products, *_history
- **職責**: 產品追蹤、數據收集、歷史記錄
- **詳細設計**: [PRODUCTS.md](./PRODUCTS.md)

### 3. Competitor Service (競品服務)
- **主要表**: competitor_analysis_groups, competitor_products
- **職責**: 競品分析、對比報告
- **詳細設計**: [COMPETITORS.md](./COMPETITORS.md)

### 4. Optimization Service (優化服務)
- **主要表**: optimization_tasks, optimization_suggestions
- **職責**: 優化建議、A/B測試
- **詳細設計**: [OPTIMIZATION.md](./OPTIMIZATION.md)

### 5. Notification Service (通知服務)
- **主要表**: notifications, notification_templates
- **職責**: 通知管理、模板系統
- **詳細設計**: [NOTIFICATIONS.md](./NOTIFICATIONS.md)

## 跨服務關聯

### 外鍵關係
```sql
-- 產品服務關聯用戶
tracked_products.user_id → users.id

-- 競品服務關聯用戶和產品
competitor_analysis_groups.user_id → users.id
competitor_products.product_id → products.id

-- 優化服務關聯用戶和產品
optimization_tasks.user_id → users.id
optimization_tasks.product_id → products.id

-- 通知服務關聯用戶
notifications.user_id → users.id
```

## 技術策略

### 時間序列數據
- **TimescaleDB擴展**: 用於歷史數據表
- **自動分區**: 按月分區提升查詢性能
- **數據保留**: 配置化保留策略

### 索引策略
- **查詢優化**: 基於實際查詢模式設計
- **複合索引**: 支援多條件查詢
- **部分索引**: 減少存儲空間

### 快取策略
- **Redis層**: 高頻查詢數據快取
- **TTL設定**: 根據數據更新頻率調整
- **失效策略**: 數據更新時主動清理

---

**維護者**: Amazon Pilot Team
**最後更新**: 2025-09-13
**版本**: v1.0