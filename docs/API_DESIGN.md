# API 設計文件

## 概述

本文件描述 Amazon 賣家產品監控與優化工具的 RESTful API 設計，包含產品追蹤、競品分析和 Listing 優化建議功能。

## 基本資訊

- **Base URL**: `https://amazon-pilot-api.phpman.top`
- **協議**: HTTPS
- **格式**: JSON
- **編碼**: UTF-8
- **框架**: goZero (Go)
- **自動文檔**: goctl 自動生成 API 文檔

## 認證與授權

### JWT Bearer Token 認證

```http
Authorization: Bearer <jwt_token>
```

### 認證流程

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "role": "seller"
  }
}
```

## Rate Limiting

- **一般用戶**: 100 requests/minute
- **高級用戶**: 500 requests/minute
- **企業用戶**: 2000 requests/minute

Rate limit 資訊會在 response headers 中返回：

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## API Endpoints

### 1. 用戶管理

#### 用戶註冊
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password",
  "company_name": "Amazon Store Inc",
  "plan": "basic"
}

Response: 201 Created
{
  "message": "User created successfully",
  "user_id": "user-uuid"
}
```

### 2. 產品追蹤 API

#### 新增追蹤產品
```http
POST /products/track
Authorization: Bearer <token>
Content-Type: application/json

{
  "asin": "B08N5WRWNW",
  "alias": "我的藍牙耳機",
  "category": "electronics",
  "tracking_settings": {
    "price_change_threshold": 10,
    "bsr_change_threshold": 30,
    "update_frequency": "daily"
  }
}

Response: 201 Created
{
  "product_id": "prod-uuid",
  "asin": "B08N5WRWNW",
  "status": "active",
  "next_update": "2024-01-15T09:00:00Z"
}
```

#### 取得追蹤記錄列表

```http
GET /api/product/products/tracked?page=1&limit=20&category=electronics&status=active
Authorization: Bearer <token>

Response: 200 OK
{
  "tracked": [
    {
      "id": "tracked-record-uuid",           // tracked_products.id
      "product_id": "product-uuid",          // products.id (用于竞品分析)
      "asin": "B08N5WRWNW",
      "title": "Sony WH-1000XM4 Wireless Headphones",
      "alias": "我的蓝牙耳机",
      "current_price": 299.99,
      "currency": "USD",
      "bsr": 15,
      "rating": 4.5,
      "review_count": 1250,
      "buy_box_price": 299.99,
      "last_updated": "2025-09-14T15:30:00Z",
      "status": "active"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 10,
    "total_pages": 1
  }
}
```

#### 取得單一產品詳細資料
```http
GET /products/{product_id}
Authorization: Bearer <token>

Response: 200 OK
{
  "id": "prod-uuid",
  "asin": "B08N5WRWNW",
  "title": "Sony WH-1000XM4 Wireless Headphones",
  "description": "Industry-leading noise canceling...",
  "brand": "Sony",
  "category": "Electronics > Headphones",
  "current_price": 299.99,
  "currency": "USD",
  "bsr": 15,
  "rating": 4.5,
  "review_count": 1250,
  "images": [
    "https://m.media-amazon.com/images/I/71o8Q5XJS5L._AC_SL1500_.jpg"
  ],
  "bullet_points": [
    "Industry-leading noise canceling",
    "30-hour battery life",
    "Touch sensor controls"
  ],
  "tracking_history": {
    "price_changes": 3,
    "bsr_changes": 5,
    "rating_changes": 2
  },
  "alerts": [
    {
      "type": "price_drop",
      "message": "Price dropped by 15%",
      "created_at": "2024-01-14T10:00:00Z"
    }
  ]
}
```

#### 取得產品歷史資料
```http
GET /products/{product_id}/history?metric=price&period=30d
Authorization: Bearer <token>

Response: 200 OK
{
  "product_id": "prod-uuid",
  "metric": "price",
  "period": "30d",
  "data": [
    {
      "date": "2024-01-01",
      "value": 349.99,
      "currency": "USD"
    },
    {
      "date": "2024-01-02",
      "value": 329.99,
      "currency": "USD"
    }
  ]
}
```

#### 停止追蹤產品
```http
DELETE /products/{product_id}/track
Authorization: Bearer <token>

Response: 200 OK
{
  "message": "Product tracking stopped successfully"
}
```

#### 获取异常检测事件
**实现异常变化监控**：价格变动>10%、BSR变动>30%、评分/评论数变化

```http
GET /api/product/products/anomaly-events?page=1&limit=50&event_type=price_change&severity=critical
Authorization: Bearer <token>

Response: 200 OK
{
  "events": [
    {
      "id": "anomaly-event-uuid",
      "product_id": "product-uuid",
      "asin": "B08N5WRWNW",
      "event_type": "price_change",
      "old_value": 299.99,
      "new_value": 249.99,
      "change_percentage": -16.67,
      "threshold": 10.0,
      "severity": "critical",
      "created_at": "2025-09-14T15:30:00Z",
      "product_title": "Sony WH-1000XM4"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 15,
    "total_pages": 1
  }
}
```

**支持的事件类型**：
- `price_change` - 价格变动 (阈值>10%)
- `bsr_change` - BSR排名变动 (阈值>30%)
- `rating_change` - 评分变化
- `review_count_change` - 评论数变化
- `buybox_change` - Buy Box价格变动

### 3. 競品分析 API


#### 建立競品分析群組
从已追踪产品中选择主产品和3-5个竞品，创建多维度比较分析组。

```http
POST /api/competitor/analysis
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "蓝牙耳机竞品分析",
  "description": "分析组描述（可选）",
  "main_product_id": "product-uuid-main",
  "competitor_product_ids": [
    "product-uuid-competitor1",
    "product-uuid-competitor2",
    "product-uuid-competitor3"
  ],
  "analysis_metrics": ["price", "bsr", "rating", "features"]
}

Response: 201 Created
{
  "id": "analysis-group-uuid",
  "name": "蓝牙耳机竞品分析",
  "main_product_id": "product-uuid-main",
  "status": "active",
  "created_at": "2025-09-14T15:30:00Z"
}
```

**特点：**
- 从已追踪产品选择，利用现有Apify数据
- 支持3-5个竞品产品

#### 列出分析群組
```http
GET /api/competitor/analysis?page=1&limit=20
Authorization: Bearer <token>

Response: 200 OK
{
  "groups": [
    {
      "id": "analysis-group-uuid",
      "name": "蓝牙耳机竞品分析",
      "description": "主打产品与市场竞品的全方位对比",
      "main_product_asin": "B08N5WRWNW",
      "competitor_count": 3,
      "status": "active",
      "last_analysis": "2025-09-14T15:30:00Z",
      "created_at": "2025-09-14T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "total_pages": 1
  }
}
```

#### 生成LLM竞争定位报告
**使用DeepSeek生成竞争分析报告**

```http
POST /api/competitor/analysis/{analysis_id}/generate-report
Authorization: Bearer <token>
Content-Type: application/json

{
  "force": false  // 是否强制重新生成
}

Response: 200 OK
{
  "report_id": "report-uuid",
  "status": "completed",
  "message": "竞争定位报告生成完成",
  "started_at": "2025-09-14T17:49:26+08:00"
}
```

**生成特点**：
- 同步生成，直接返回结果
- 基于真实产品数据（价格、BSR、评分）
- DeepSeek中文竞争分析专家
- 支持force重新生成已有报告

#### 取得競品分析結果
```http
GET /api/competitor/analysis/{analysis_id}
Authorization: Bearer <token>

Response: 200 OK
{
  "id": "analysis-group-uuid",
  "name": "蓝牙耳机竞品分析",
  "description": "竞品对比分析组",
  "main_product": {
    "id": "product-uuid-main",
    "asin": "B08N5WRWNW",
    "title": "Sony WH-1000XM4",
    "price": 299.99,
    "bsr": 15,
    "rating": 4.5,
    "review_count": 1250
  },
  "competitors": [
    {
      "asin": "B087C8Q3PD",
      "title": "Bose QuietComfort 45",
      "price": 329.99,
      "bsr": 8,
      "rating": 4.3,
      "review_count": 980,
      "price_difference": 30.00,
      "bsr_difference": -7,
      "rating_difference": -0.2
    }
  ],
  "insights": {
    "price_positioning": "mid_range",
    "competitive_advantages": [
      "Better battery life",
      "Superior noise canceling"
    ],
    "weaknesses": [
      "Higher price than average",
      "Lower BSR ranking"
    ],
    "recommendations": [
      "Consider price reduction to improve competitiveness",
      "Highlight unique features in listing"
    ]
  }
}
```

### 4. Listing 優化建議 API

#### 生成優化建議
```http
POST /api/optimization/analyze
Authorization: Bearer <token>
Content-Type: application/json

{
  "asin": "B08N5WRWNW",
  "analysis_type": "comprehensive",
  "focus_areas": [
    "title",
    "pricing",
    "description",
    "images",
    "keywords"
  ]
}

Response: 202 Accepted
{
  "analysis_id": "opt-uuid",
  "status": "processing",
  "estimated_completion": "2024-01-15T09:30:00Z"
}
```

#### 取得優化建議結果
```http
GET /api/optimization/{analysis_id}
Authorization: Bearer <token>

Response: 200 OK
{
  "id": "opt-uuid",
  "asin": "B08N5WRWNW",
  "status": "completed",
  "created_at": "2024-01-14T15:00:00Z",
  "suggestions": [
    {
      "id": "sugg-1",
      "category": "title",
      "priority": "high",
      "impact_score": 85,
      "current": "Sony WH-1000XM4 Wireless Headphones",
      "suggested": "Sony WH-1000XM4 Noise Cancelling Wireless Bluetooth Headphones - 30 Hours Battery, Quick Attention Mode, Black",
      "reasoning": "Adding high-volume keywords 'Noise Cancelling', 'Bluetooth', and key features '30 Hours Battery' can improve search visibility",
      "estimated_impact": {
        "search_ranking_improvement": "15-25%",
        "click_through_rate": "10-15%"
      }
    },
    {
      "id": "sugg-2",
      "category": "pricing",
      "priority": "medium",
      "impact_score": 70,
      "current": 299.99,
      "suggested": 279.99,
      "reasoning": "Price reduction of 6.7% can improve competitiveness against Bose QC45 and Apple AirPods Max",
      "estimated_impact": {
        "conversion_rate": "8-12%",
        "sales_volume": "15-20%"
      }
    }
  ],
  "overall_score": 75,
  "priority_actions": [
    "Update product title to include high-volume keywords",
    "Optimize main product image to show key features",
    "Add lifestyle images showing use cases"
  ]
}
```

#### 優化建議實施追蹤
```http
POST /optimization/{analysis_id}/implement
Authorization: Bearer <token>
Content-Type: application/json

{
  "suggestion_id": "sugg-1",
  "implementation_date": "2024-01-15",
  "notes": "Updated title as suggested"
}

Response: 200 OK
{
  "message": "Implementation tracked successfully",
  "tracking_id": "track-uuid"
}
```

## 錯誤處理

### 標準錯誤格式

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {
        "field": "asin",
        "message": "ASIN must be 10 characters long"
      }
    ],
    "request_id": "req-uuid-12345"
  }
}
```

### 錯誤代碼

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | VALIDATION_ERROR | 請求參數驗證失敗 |
| 401 | UNAUTHORIZED | 認證失敗或 token 過期 |
| 403 | FORBIDDEN | 權限不足 |
| 404 | NOT_FOUND | 資源不存在 |
| 409 | CONFLICT | 資源衝突（如重複追蹤） |
| 422 | UNPROCESSABLE_ENTITY | 請求格式正確但邏輯錯誤 |
| 429 | RATE_LIMIT_EXCEEDED | 超過 API 調用限制 |
| 500 | INTERNAL_ERROR | 伺服器內部錯誤 |
| 503 | SERVICE_UNAVAILABLE | 服務暫時不可用 |

### 錯誤處理範例

```http
POST /products/track
Authorization: Bearer <invalid_token>

Response: 401 Unauthorized
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token",
    "request_id": "req-uuid-12345"
  }
}
```

## 版本控制

API 使用 URL 版本控制：
- Current: `/v1/`
- Deprecated: 舊版本會保持 6 個月的向後兼容性
- 版本變更會在 response headers 中提供遷移資訊

```http
X-API-Version: 1.0
X-Deprecation-Warning: This version will be deprecated on 2024-07-01
X-Migration-Guide: https://docs.api.amazon-monitor.com/migration/v2
```

## 分頁

使用 offset-based 分頁：

```http
GET /products/tracked?page=2&limit=50
```

## 快取策略
- 產品資料快取 24 小時

```http
GET /products/{product_id}

Response Headers:
Cache-Control: public, max-age=86400
ETag: "abc123def456"
Last-Modified: Wed, 14 Jan 2024 15:30:00 GMT
```

## Webhook 支援

支援 webhook 推送重要事件：

```http
POST /webhooks/register
Authorization: Bearer <token>

{
  "url": "https://yourapp.com/webhooks/amazon-monitor",
  "events": ["price_alert", "bsr_change", "analysis_complete"],
  "secret": "your-webhook-secret"
}
```

Webhook payload 範例：

```json
{
  "event_type": "price_alert",
  "timestamp": "2024-01-14T15:30:00Z",
  "data": {
    "product_id": "prod-uuid",
    "asin": "B08N5WRWNW",
    "old_price": 299.99,
    "new_price": 254.99,
    "change_percentage": -15.0
  },
  "signature": "sha256=hash_value"
}
```
