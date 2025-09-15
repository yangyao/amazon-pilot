# 資料庫設計文件

## 概述

本文件描述 Amazon 賣家產品監控與優化工具的資料庫架構設計，包含資料模型、表結構、索引策略和優化方案。

## 資料庫架構

### 技術選型

**主資料庫**: PostgreSQL 15
- 關聯式資料庫，支持 ACID 事務
- JSON/JSONB 支持，適合半結構化資料
- 強大的索引和查詢優化能力
- 成熟的生態系統和工具支持

**快取資料庫**: Redis 7
- 高效能記憶體快取
- 支持多種資料結構
- 作為消息佇列和任務調度

### 資料庫命名規範

- 表名: 小寫蛇形命名，使用複數形式
- 欄位: 小寫蛇形命名
- 主鍵: `id` 或 `{table}_id`
- 外鍵: `{referenced_table}_id`
- 索引: `idx_{table}_{columns}`
- 約束: `{table}_{constraint_type}_{columns}`

## 核心資料模型

### 用戶管理模組

#### users 表 (用戶基本資訊)
- `id` (UUID): 主鍵
- `email` (VARCHAR): 唯一索引
- `password_hash` (VARCHAR): bcrypt 加密
- `name` (VARCHAR): 用戶名稱
- `plan_type` (ENUM): free/basic/premium/enterprise
- `is_active` (BOOLEAN): 帳戶狀態
- `created_at` (TIMESTAMP): 註冊時間
- `updated_at` (TIMESTAMP): 更新時間

### 產品追蹤模組

#### products 表 (產品主資料)
- `id` (UUID): 主鍵
- `asin` (VARCHAR): Amazon 產品編號，唯一索引
- `title` (TEXT): 產品標題
- `brand` (VARCHAR): 品牌
- `category` (VARCHAR): 類目
- `bullet_points` (JSONB): 產品特點
- `images` (JSONB): 產品圖片
- `current_price` (DECIMAL): 當前價格
- `current_bsr` (INTEGER): 當前 BSR 排名
- `current_rating` (DECIMAL): 當前評分
- `current_reviews_count` (INTEGER): 評論數
- `last_updated` (TIMESTAMP): 最後更新時間
- `created_at` (TIMESTAMP): 建立時間

#### tracked_products 表 (用戶追蹤設定)
- `id` (UUID): 主鍵
- `user_id` (UUID): 外鍵 -> users.id
- `product_id` (UUID): 外鍵 -> products.id
- `price_threshold` (DECIMAL): 價格闾值
- `bsr_threshold` (INTEGER): BSR 闾值
- `rating_threshold` (DECIMAL): 評分闾值
- `is_active` (BOOLEAN): 追蹤狀態
- `created_at` (TIMESTAMP): 開始追蹤時間
- `updated_at` (TIMESTAMP): 更新時間

#### product_price_history 表 (價格歷史)
- `id` (UUID): 主鍵
- `product_id` (UUID): 外鍵 -> products.id
- `price` (DECIMAL): 價格
- `currency` (VARCHAR): 貨幣
- `buybox_price` (DECIMAL): Buy Box 價格
- `recorded_at` (TIMESTAMP): 記錄時間
- 索引: `idx_price_history_product_time`

#### product_ranking_history 表 (BSR 和評分歷史)
- `id` (UUID): 主鍵
- `product_id` (UUID): 外鍵 -> products.id
- `bsr` (INTEGER): BSR 排名
- `category_rank` (INTEGER): 類目排名
- `rating` (DECIMAL): 評分
- `reviews_count` (INTEGER): 評論數
- `recorded_at` (TIMESTAMP): 記錄時間
- 索引: `idx_ranking_history_product_time`

#### product_review_history 表 (評論變化追蹤)
- `id` (UUID): 主鍵
- `product_id` (UUID): 外鍵 -> products.id
- `total_reviews` (INTEGER): 總評論數
- `positive_reviews` (INTEGER): 正面評論
- `negative_reviews` (INTEGER): 負面評論
- `average_rating` (DECIMAL): 平均評分
- `recorded_at` (TIMESTAMP): 記錄時間

#### product_buybox_history 表 (Buy Box 變化)
- `id` (UUID): 主鍵
- `product_id` (UUID): 外鍵 -> products.id
- `seller_name` (VARCHAR): 賣家名稱
- `price` (DECIMAL): Buy Box 價格
- `is_fba` (BOOLEAN): 是否 FBA
- `recorded_at` (TIMESTAMP): 記錄時間

#### product_anomaly_events 表 (異常事件)
- `id` (UUID): 主鍵
- `product_id` (UUID): 外鍵 -> products.id
- `event_type` (ENUM): price_drop/price_spike/bsr_change/rating_drop
- `severity` (ENUM): low/medium/high
- `old_value` (JSONB): 舊值
- `new_value` (JSONB): 新值
- `change_percentage` (DECIMAL): 變化百分比
- `detected_at` (TIMESTAMP): 檢測時間
- `is_notified` (BOOLEAN): 是否已通知

### 競品分析模組

#### competitor_analysis_groups 表 (分析組)
- `id` (UUID): 主鍵
- `user_id` (UUID): 外鍵 -> users.id
- `main_product_id` (UUID): 外鍵 -> products.id
- `name` (VARCHAR): 分析組名稱
- `description` (TEXT): 描述
- `is_active` (BOOLEAN): 狀態
- `created_at` (TIMESTAMP): 建立時間
- `updated_at` (TIMESTAMP): 更新時間

#### competitor_products 表 (競品關聯)
- `id` (UUID): 主鍵
- `analysis_group_id` (UUID): 外鍵 -> competitor_analysis_groups.id
- `product_id` (UUID): 外鍵 -> products.id
- `added_at` (TIMESTAMP): 加入時間
- 唯一約束: `(analysis_group_id, product_id)`

#### competitor_analysis_results 表 (分析結果)
- `id` (UUID): 主鍵
- `analysis_group_id` (UUID): 外鍵 -> competitor_analysis_groups.id
- `analysis_data` (JSONB): 多維度分析數據
- `llm_report` (JSONB): LLM 生成的報告
- `recommendations` (JSONB): 優化建議
- `generated_at` (TIMESTAMP): 生成時間

### 優化建議模組

#### optimization_analyses 表 (優化分析)
- `id` (UUID): 主锵
- `product_id` (UUID): 外鍵 -> products.id
- `user_id` (UUID): 外鍵 -> users.id
- `optimization_type` (ENUM): listing/pricing/keyword
- `current_score` (INTEGER): 當前分數
- `potential_score` (INTEGER): 潛在分數
- `status` (ENUM): pending/completed/implemented
- `created_at` (TIMESTAMP): 分析時間

#### optimization_suggestions 表 (優化建議)
- `id` (UUID): 主鍵
- `analysis_id` (UUID): 外鍵 -> optimization_analyses.id
- `suggestion_type` (VARCHAR): 建議類型
- `current_value` (TEXT): 當前值
- `suggested_value` (TEXT): 建議值
- `impact_score` (INTEGER): 影響分數
- `is_implemented` (BOOLEAN): 是否已實施

### 通知管理模組

#### notifications 表 (通知記錄)
- `id` (UUID): 主鍵
- `user_id` (UUID): 外鍵 -> users.id
- `type` (ENUM): price_alert/ranking_change/analysis_complete
- `title` (VARCHAR): 標題
- `message` (TEXT): 內容
- `data` (JSONB): 相關數據
- `is_read` (BOOLEAN): 是否已讀
- `created_at` (TIMESTAMP): 建立時間

#### notification_preferences 表 (通知偏好)
- `id` (UUID): 主鍵
- `user_id` (UUID): 外鍵 -> users.id
- `email_enabled` (BOOLEAN): Email 通知
- `push_enabled` (BOOLEAN): 推送通知
- `notification_types` (JSONB): 啟用的通知類型
- `updated_at` (TIMESTAMP): 更新時間

## 索引策略

### 主鍵索引
所有表的 `id` 欄位自動建立主鍵索引

### 唯一索引
- `users.email`
- `products.asin`
- `(tracked_products.user_id, tracked_products.product_id)`
- `(competitor_products.analysis_group_id, competitor_products.product_id)`

### 複合索引
- `idx_tracked_products_user_active`: (user_id, is_active)
- `idx_price_history_product_time`: (product_id, recorded_at DESC)
- `idx_ranking_history_product_time`: (product_id, recorded_at DESC)
- `idx_anomaly_events_product_time`: (product_id, detected_at DESC)
- `idx_notifications_user_read`: (user_id, is_read, created_at DESC)

### 部分索引
- `idx_products_active_bsr`: (current_bsr) WHERE is_active = true
- `idx_anomaly_events_unnotified`: (product_id) WHERE is_notified = false

## 效能優化

### 分區策略

#### 歷史數據分區
以月份為單位分區歷史表:
- `product_price_history`
- `product_ranking_history`
- `product_review_history`
- `product_buybox_history`

分區優勢:
- 查詢效能提升
- 易於歸檔舊數據
- 維護成本降低

### 查詢優化

#### 物化視圖
為複雜的統計查詢建立物化視圖:
- 產品每日統計
- 用戶活躍度統計
- 異常事件彙總

#### 查詢快取
使用 Redis 快取高頻查詢:
- 熱門產品資料
- 用戶追蹤列表
- 最近的分析結果

### 資料庫連接池

連接池配置:
- 最大連接數: 100
- 最小空閒連接: 10
- 連接超時: 30秒
- 空閒超時: 10分鐘

## 資料安全

### 敏感資料保護

#### 加密存儲
- 密碼: bcrypt 雜湊
- Token: SHA-256 雜湊
- API 密鑰: AES-256 加密

#### 資料脫敏
- 日誌中不記錄敏感資料
- API 回應中隱藏部分資訊
- 備份檔案加密存儲

### 訪問控制

#### 行級安全 (RLS)
啟用 PostgreSQL 行級安全:
- 用戶只能訪問自己的數據
- 管理員可以訪問所有數據

#### 審計日誌
記錄所有敏感操作:
- 用戶登入/登出
- 數據修改
- 權限變更

## 備份與恢復

### 備份策略

#### 全量備份
- 頻率: 每日凌晨 2:00
- 保留: 30 天
- 存儲: 異地備份

#### 增量備份
- 頻率: 每小時
- 保留: 7 天
- WAL 歸檔

### 恢復機制

#### 時間點恢復 (PITR)
- 支持恢復到任意時間點
- RPO: < 1 小時
- RTO: < 2 小時

#### 災難恢復
- 主從複製
- 自動故障轉移
- 跨區域備份

## 監控與維護

### 效能監控

#### 關鍵指標
- 查詢響應時間
- 事務處理量
- 連接池使用率
- 快取命中率

#### 慢查詢日誌
記錄超過 100ms 的查詢:
- 查詢語句
- 執行時間
- 執行計畫
- 資源消耗

### 維護作業

#### 定期維護
- VACUUM: 每週
- ANALYZE: 每日
- REINDEX: 每月
- 清理過期數據: 每月

#### 健康檢查
- 表膨脹檢查
- 索引效率分析
- 鎖衝突檢測
- 連接數監控

## 擴展性考慮

### 垂直擴展
- 增加 CPU 和記憶體
- SSD 存儲優化
- 連接池調整

### 水平擴展
- 讀寫分離
- 分片策略
- 多主複製

### 數據歸檔
- 超過 1 年的歷史數據歸檔
- 使用專門的歷史數據庫
- 壓縮存儲節省空間