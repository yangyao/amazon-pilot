# Amazon Pilot 數據庫設計索引

## 概述

Amazon 賣家產品監控與優化工具的完整數據庫設計文件索引。

## 數據庫設計文件結構

### 核心設計文件
- **[OVERVIEW.md](./OVERVIEW.md)** - 數據庫架構概覽和技術選型
- **[USERS.md](./USERS.md)** - 用戶管理相關表設計
- **[PRODUCTS.md](./PRODUCTS.md)** - 產品追蹤相關表設計 ⭐
- **[COMPETITORS.md](./COMPETITORS.md)** - 競品分析相關表設計
- **[OPTIMIZATION.md](./OPTIMIZATION.md)** - 優化建議相關表設計
<!-- notifications 表已移除，不再提供對應 DB 設計文件 -->

### 技術文件
- **[INDEXING.md](./INDEXING.md)** - 索引策略和優化
- **[CACHING.md](./CACHING.md)** - Redis 快取策略
- **[PARTITIONING.md](./PARTITIONING.md)** - 時間序列數據分區
- **[MIGRATIONS.md](./MIGRATIONS.md)** - 數據庫遷移管理

## Questions.md 要求映射

根據 questions.md 要求的追蹤項目：

### 產品追蹤 (選項1 - 已實現)
- **價格變化** → `product_price_history` 表
- **BSR 趨勢** → `product_ranking_history` 表
- **評分與評論數變化** → `product_review_history` 表
- **Buy Box 價格** → `product_buybox_history` 表

### 競品分析 (選項2)
- **競品分組** → `competitor_analysis_groups` 表
- **競品產品** → `competitor_products` 表
- **比較報告** → `competitor_analysis_reports` 表

### 優化建議 (選項3)
- **優化任務** → `optimization_tasks` 表
- **建議記錄** → `optimization_suggestions` 表
- **A/B測試** → `ab_test_results` 表

## 快速導航

| 功能模組 | 主要表 | 文件連結 |
|---------|--------|----------|
| 用戶管理 | users | [USERS.md](./USERS.md) |
| 產品追蹤 | products, tracked_products, *_history | [PRODUCTS.md](./PRODUCTS.md) |
| 競品分析 | competitor_* | [COMPETITORS.md](./COMPETITORS.md) |
| 優化建議 | optimization_* | [OPTIMIZATION.md](./OPTIMIZATION.md) |
| 通知系統 | （不落庫） | - |

---

**維護說明**: 每個服務的表設計獨立維護，便於並行開發和文檔更新
**最後更新**: 2025-09-13
**版本**: v1.0 - 按服務拆分數據庫設計文件
