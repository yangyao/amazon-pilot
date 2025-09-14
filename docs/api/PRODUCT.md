# Product Service API Design

## 產品服務 API 設計規範

### API 前綴
- **Base URL**: `/api/product`
- **認證**: JWT Bearer Token (除健康檢查外)
- **限流**: 適用 Rate Limiting 中間件

## 核心 API 端點

### 1. 健康檢查 (無需認證)

#### Ping 檢查
- **端點**: `GET /api/product/ping`
- **用途**: 服務可用性檢查
- **響應**:
```json
{
  "status": "ok",
  "message": "Product service is running",
  "timestamp": 1694678400
}
```

#### 健康狀態
- **端點**: `GET /api/product/health`
- **用途**: 詳細健康狀態
- **響應**:
```json
{
  "service": "product-api",
  "status": "healthy",
  "version": "v1.0",
  "uptime": 3600
}
```

### 2. 產品搜索 (需認證)

#### 搜索產品按類目
- **端點**: `POST /api/product/search-products`
- **用途**: 使用 Apify 搜索 Amazon 產品
- **請求**:
```json
{
  "category": "wireless earbuds",
  "max_results": 10
}
```
- **響應**:
```json
{
  "success": true,
  "products_count": 10,
  "message": "Found 10 products in wireless earbuds category",
  "products": [
    {
      "asin": "B0D2XRXNGY",
      "title": "Anker Soundcore...",
      "brand": "Anker",
      "price": 39.99,
      "currency": "USD",
      "rating": 4.5,
      "review_count": 12450,
      "bsr": 67,
      "scraped_at": "2025-09-13T10:00:00Z"
    }
  ]
}
```

#### 手動獲取產品數據
- **端點**: `POST /api/product/fetch-amazon-product-data`
- **用途**: 根據 ASIN 列表獲取產品詳情
- **請求**:
```json
{
  "asins": ["B08N5WRWNW", "B085HN41M6"],
  "force": false
}
```

### 3. 產品追蹤管理 (需認證)

#### 添加產品追蹤
- **端點**: `POST /api/product/products/track`
- **用途**: 將產品添加到用戶追蹤列表
- **請求**:
```json
{
  "asin": "B08N5WRWNW",
  "alias": "Echo Dot 4th Gen",
  "category": "Electronics",
  "tracking_settings": {
    "price_change_threshold": 10,
    "bsr_change_threshold": 30,
    "update_frequency": "daily"
  }
}
```
- **響應**:
```json
{
  "product_id": "uuid",
  "asin": "B08N5WRWNW",
  "status": "active",
  "next_update": "2025-09-14T10:00:00Z"
}
```

#### 獲取追蹤產品列表 (增強版)
- **端點**: `GET /api/product/products/tracked`
- **參數**: `page`, `limit`, `category`, `status`
- **響應** (包含完整產品信息):
```json
{
  "products": [
    {
      "id": "uuid",
      "asin": "B0D2XRXNGY",
      "title": "Soundcore V20i by Anker Open-Ear Headphones...",
      "brand": "Soundcore",
      "category": "Electronics",
      "alias": "Anker耳机",
      "current_price": 23.49,
      "currency": "USD",
      "bsr": 73,
      "bsr_category": "Open-Ear Headphones",
      "rating": 4.4,
      "review_count": 6687,
      "buy_box_price": 23.49,
      "last_updated": "2025-09-14T10:00:00Z",
      "status": "active",
      "images": [
        "https://m.media-amazon.com/images/I/517WiAmP8qL._AC_SL1500_.jpg",
        "https://m.media-amazon.com/images/I/51Y4S01JpJL._AC_SL1500_.jpg"
      ],
      "description": "Ultra-Comfort with Open-Ear Design...",
      "bullet_points": [
        "Ultra-Comfort with Open-Ear Design",
        "Enhanced Situational Awareness",
        "Four Adjustable Positions"
      ],
      "tracking_settings": {
        "price_change_threshold": 10,
        "bsr_change_threshold": 30,
        "update_frequency": "daily"
      },
      "history_summary": {
        "price_changes_24h": 0,
        "bsr_changes_24h": 0,
        "rating_changes_24h": 0,
        "total_price_records": 3,
        "total_bsr_records": 2,
        "first_recorded_at": "2025-09-14T02:00:00Z",
        "last_price_update": "2025-09-14T10:00:00Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

**新增字段說明:**
- **brand, category** → 產品分類信息
- **images, description, bullet_points** → 豐富的產品展示信息
- **bsr_category** → 具體BSR排名類別
- **tracking_settings** → 用戶個性化追蹤設置
- **history_summary** → 歷史數據統計摘要

#### 停止產品追蹤
- **端點**: `DELETE /api/product/products/:product_id/track`
- **響應**:
```json
{
  "message": "Product tracking stopped successfully"
}
```

### 4. 數據刷新 (需認證)

#### 刷新產品數據
- **端點**: `POST /api/product/products/:product_id/refresh`
- **用途**: 異步刷新產品最新數據
- **響應**:
```json
{
  "success": true,
  "message": "Product data refresh task has been queued successfully. Data will be updated in background."
}
```

### 5. 歷史數據查詢 (需認證)

#### 產品詳情
- **端點**: `GET /api/product/products/:product_id`
- **響應**: 包含產品基本信息和最新數據

#### 歷史數據
- **端點**: `GET /api/product/products/:product_id/history`
- **參數**: `metric` (price/bsr/rating), `period` (7d/30d/90d)
- **響應**:
```json
{
  "product_id": "uuid",
  "metric": "price",
  "period": "30d",
  "data": [
    {
      "date": "2025-09-13",
      "value": 49.99,
      "currency": "USD"
    }
  ]
}
```

## Questions.md 要求映射

### 產品資料追蹤系統 (選項1) - 完全實現

**追蹤項目支援:**
- ✅ **價格變化** → 價格歷史 API + 異常檢測
- ✅ **BSR 趨勢** → 排名歷史 API + 趨勢分析
- ✅ **評分與評論數變化** → 評論歷史 API + 變化監控
- ✅ **Buy Box 價格** → Buy Box 歷史 API + 競爭分析

**技術要求滿足:**
- ✅ **Apify Actor 整合** → 真實 Amazon 數據
- ✅ **Redis 快取機制** → 24-48小時 TTL
- ✅ **背景任務排程** → Asynq 異步處理
- ✅ **異常變化通知** → >10% 價格變動，>30% BSR 變動

## 錯誤處理

### 常見錯誤情況
1. **ASIN 格式錯誤** → VALIDATION_ERROR
2. **產品已追蹤** → CONFLICT
3. **產品不存在** → NOT_FOUND
4. **Apify 限額** → RATE_LIMIT_EXCEEDED
5. **數據庫錯誤** → INTERNAL_ERROR

## 性能優化

### 響應時間目標
- **查詢類 API** → < 200ms
- **同步搜索** → < 60s
- **異步任務** → 立即返回，後台處理

### 快取策略
- **產品基本信息** → 24小時 TTL
- **追蹤列表** → 1小時 TTL
- **搜索結果** → 2小時 TTL

---

**API 定義文件**: `api/openapi/product.api`
**服務實現**: `internal/product/`
**狀態**: ✅ 完全實現，支援 Demo
**最後更新**: 2025-09-13