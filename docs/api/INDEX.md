# Amazon Pilot API 設計索引

## 概述

Amazon Pilot 微服務 API 設計文檔索引，按服務模組化組織。

## API 設計文件結構

### 核心設計文件
- **[OVERVIEW.md](./OVERVIEW.md)** - API 架構概覽和設計規範
- **[AUTHENTICATION.md](./AUTHENTICATION.md)** - 認證和授權機制
- **[ERROR_HANDLING.md](./ERROR_HANDLING.md)** - 統一錯誤處理規範
- **[RATE_LIMITING.md](./RATE_LIMITING.md)** - API 限流策略

### 按服務拆分的 API 設計
- **[AUTH.md](./AUTH.md)** - 認證服務 API 設計
- **[PRODUCT.md](./PRODUCT.md)** - 產品服務 API 設計 ⭐
- **[COMPETITOR.md](./COMPETITOR.md)** - 競品服務 API 設計
- **[OPTIMIZATION.md](./OPTIMIZATION.md)** - 優化服務 API 設計
- **[NOTIFICATION.md](./NOTIFICATION.md)** - 通知服務 API 設計
- **[GATEWAY.md](./GATEWAY.md)** - API Gateway 路由設計

## API 定義文件位置

### OpenAPI 規範文件 (Source of Truth)
```
api/openapi/
├── auth.api           # 認證服務 API 定義
├── product.api        # 產品服務 API 定義 ⭐
├── competitor.api     # 競品服務 API 定義
├── optimization.api   # 優化服務 API 定義
└── notification.api   # 通知服務 API 定義
```

## Questions.md 要求映射

### 核心功能 API (已實現)

**產品資料追蹤系統 (選項1):**
- **搜索產品** → `POST /api/product/search-products`
- **添加追蹤** → `POST /api/product/products/track`
- **查看追蹤** → `GET /api/product/products/tracked`
- **刷新數據** → `POST /api/product/products/:id/refresh`
- **產品歷史** → `GET /api/product/products/:id/history`

**競品分析引擎 (選項2):**
- **創建分組** → `POST /api/competitor/groups`
- **添加競品** → `POST /api/competitor/groups/:id/products`
- **分析報告** → `GET /api/competitor/groups/:id/analysis`

**優化建議生成器 (選項3):**
- **生成建議** → `POST /api/optimization/suggestions`
- **獲取建議** → `GET /api/optimization/suggestions/:id`
- **A/B測試** → `POST /api/optimization/ab-tests`

## 統一 API 規範

### 1. 路由前綴
- 所有 API 使用統一前綴：`/api/{service}/`
- Gateway 自動路由到對應服務

### 2. 認證機制
- JWT Bearer Token 認證
- 統一的 token 格式和驗證

### 3. 錯誤處理
- 統一的 JSON 錯誤格式
- 標準 HTTP 狀態碼

### 4. 響應格式
- 統一的 JSON 響應結構
- 分頁、過濾、排序標準化

---

**維護說明**: 每個服務的 API 設計獨立維護，便於並行開發
**API 版本**: v1.0
**最後更新**: 2025-09-13