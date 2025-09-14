# Amazon Pilot API 架構概覽

## API 設計哲學

### 設計原則
1. **RESTful 設計** → 標準 HTTP 方法和狀態碼
2. **統一性** → 所有服務遵循相同規範
3. **可擴展性** → 支援微服務架構
4. **安全性** → JWT 認證 + 限流保護

### 微服務 API 架構

#### API Gateway 模式
```
客戶端 → API Gateway (8080) → 微服務
                ↓
         統一認證、限流、日誌
```

#### 服務路由規劃
- **認證服務** → `/api/auth/*`
- **產品服務** → `/api/product/*` ⭐
- **競品服務** → `/api/competitor/*`
- **優化服務** → `/api/optimization/*`
- **通知服務** → `/api/notification/*`

## 統一 API 規範

### 1. 請求格式
```http
POST /api/product/products/track
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "asin": "B08N5WRWNW",
  "alias": "Echo Dot 4th Gen",
  "category": "Electronics"
}
```

### 2. 成功響應格式
```json
{
  "success": true,
  "data": {
    "product_id": "uuid",
    "asin": "B08N5WRWNW",
    "status": "active"
  },
  "message": "Product added successfully"
}
```

### 3. 錯誤響應格式
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid ASIN format",
    "details": [
      {
        "field": "asin",
        "message": "ASIN must be 10 characters"
      }
    ],
    "request_id": "req-uuid"
  }
}
```

### 4. 分頁響應格式
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

## 認證和授權

### JWT Token 結構
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "plan": "premium",
  "exp": 1234567890,
  "iat": 1234567890
}
```

### 權限控制
- **基礎功能** → basic plan 用戶
- **高級分析** → premium plan 用戶
- **企業功能** → enterprise plan 用戶

## API 限流策略

### 限流層級
1. **全局限流** → Gateway 層面
2. **服務限流** → 各微服務層面
3. **用戶限流** → 基於 plan type

### 限流規則
```yaml
rate_limits:
  basic_plan:
    requests_per_minute: 60
    burst_size: 10
  premium_plan:
    requests_per_minute: 600
    burst_size: 50
  enterprise_plan:
    requests_per_minute: 6000
    burst_size: 100
```

## 錯誤碼標準

### 標準錯誤碼
- **VALIDATION_ERROR** → 400 Bad Request
- **UNAUTHORIZED** → 401 Unauthorized
- **FORBIDDEN** → 403 Forbidden
- **NOT_FOUND** → 404 Not Found
- **CONFLICT** → 409 Conflict
- **RATE_LIMIT_EXCEEDED** → 429 Too Many Requests
- **INTERNAL_ERROR** → 500 Internal Server Error

## 版本管理

### API 版本策略
- **URL 版本** → `/api/product/v1/...`
- **向後兼容** → 保持舊版本支援
- **棄用政策** → 提前通知，逐步遷移

---

**設計規範**: 基於 OpenAPI 3.0 規範
**最後更新**: 2025-09-13