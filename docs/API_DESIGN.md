# API 設計文件

## 📋 概述

Amazon Pilot 採用 RESTful API 設計，基於 go-zero 微服務框架實現，提供統一的 API 接口規範、版本管理策略和錯誤處理機制。本文件詳細說明了 API 設計原則、版本化策略、錯誤代碼規範以及具體的端點設計。

## 🏗️ API 架構設計

### 技術棧
- **框架**: go-zero 微服務框架
- **API 規範**: RESTful API
- **數據格式**: JSON
- **認證**: JWT Bearer Token
- **限流**: Token Bucket 算法
- **網關**: 統一路由和中間件處理

### 設計原則

1. **統一性**: 所有 API 遵循相同的設計規範
2. **可擴展性**: 支持版本化和向後兼容
3. **安全性**: 統一認證授權機制
4. **可觀測性**: 完整的請求日誌和指標監控
5. **錯誤友好**: 結構化錯誤響應格式

## 🔢 API 版本化策略

### 當前版本化實現

Amazon Pilot 使用 **URL Path 版本化** 策略，所有 API 都包含版本前綴：

```
/api/{service}/{endpoint}
```

#### 當前 API 前綴結構
```
/api/auth/*         # 認證服務 v1
/api/product/*      # 產品追蹤服務 v1
/api/competitor/*   # 競品分析服務 v1
/api/optimization/* # 優化建議服務 v1
```

#### go-zero 版本化配置

在每個 `.api` 文件中定義：

```go
syntax = "v1"

info (
    title:   "Amazon Monitor Product Tracking API"
    desc:    "Product tracking and monitoring service"
    author:  "Amazon Pilot Team"
    email:   "team@amazon-pilot.com"
    version: "v1"
)

@server (
    prefix: /api/product  // v1 版本前綴
    middleware: RateLimitMiddleware
)
service product-api {
    // API 端點定義
}
```

### 版本升級策略

#### 引入新版本 (v2)

1. **API 文件更新**:
   ```go
   syntax = "v2"

   info (
       version: "v2"
   )

   @server (
       prefix: /api/v2/product  // 明確版本號
   )
   ```

2. **並行部署**:
   ```
   /api/product/*     # v1 (默認，向後兼容)
   /api/v2/product/*  # v2 (新版本)
   ```

3. **代碼生成**:
   ```bash
   ./scripts/goctl-centralized.sh -s product    # 生成 v2 版本代碼
   ```

#### 版本廢棄計劃

1. **廢棄通知**: 在響應頭中添加廢棄警告
   ```
   Deprecation: true
   Sunset: 2025-12-31
   Link: </api/v2/product>; rel="successor-version"
   ```

2. **支持期限**: v1 版本支持期至少 6 個月
3. **遷移文檔**: 提供完整的 v1 -> v2 遷移指南

### 版本化最佳實踐

#### DO ✅
- **使用語義化版本號**: v1, v2, v3
- **保持向後兼容**: 新增字段，不刪除現有字段
- **提供遷移指南**: 詳細的版本升級文檔
- **監控版本使用**: 追蹤各版本的使用情況

#### DON'T ❌
- **頻繁發布新版本**: 避免版本碎片化
- **破壞性變更**: 在同一主版本內引入不兼容變更
- **突然廢棄**: 沒有充分通知就移除舊版本

## 🚨 錯誤代碼規範

### 錯誤響應格式

所有 API 錯誤統一使用以下 JSON 格式：

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": [
      {
        "field": "field_name",
        "message": "Field specific error"
      }
    ],
    "request_id": "req-uuid-string",
    "retry_after": 60
  }
}
```

### 標準錯誤代碼

#### 客戶端錯誤 (4xx)

| HTTP Status | Error Code | 說明 | 使用場景 |
|------------|------------|------|----------|
| 400 | `VALIDATION_ERROR` | 請求參數驗證失敗 | 缺少必填字段、格式錯誤 |
| 401 | `UNAUTHORIZED` | 未授權或令牌無效 | JWT 過期、無效令牌 |
| 403 | `FORBIDDEN` | 權限不足 | 用戶無權限訪問資源 |
| 404 | `NOT_FOUND` | 資源不存在 | 產品不存在、用戶不存在 |
| 409 | `CONFLICT` | 資源衝突 | 重複創建、狀態衝突 |
| 422 | `UNPROCESSABLE_ENTITY` | 業務邏輯錯誤 | 業務規則驗證失敗 |
| 429 | `RATE_LIMIT_EXCEEDED` | 請求頻率超限 | API 調用次數超限 |

#### 服務端錯誤 (5xx)

| HTTP Status | Error Code | 說明 | 使用場景 |
|------------|------------|------|----------|
| 500 | `INTERNAL_ERROR` | 內部服務器錯誤 | 未預期的系統錯誤 |
| 503 | `SERVICE_UNAVAILABLE` | 服務不可用 | 維護模式、依賴服務不可用 |

### 錯誤代碼實現

#### 1. 錯誤定義 (`internal/pkg/errors/errors.go`)

```go
// 預定義錯誤代碼常量
const (
    CodeValidationError    = "VALIDATION_ERROR"
    CodeUnauthorized      = "UNAUTHORIZED"
    CodeForbidden         = "FORBIDDEN"
    CodeNotFound          = "NOT_FOUND"
    CodeConflict          = "CONFLICT"
    CodeUnprocessableEntity = "UNPROCESSABLE_ENTITY"
    CodeRateLimitExceeded = "RATE_LIMIT_EXCEEDED"
    CodeInternalError     = "INTERNAL_ERROR"
    CodeServiceUnavailable = "SERVICE_UNAVAILABLE"
)

// APIError 結構
type APIError struct {
    ErrorDetail ErrorDetail `json:"error"`
}

type ErrorDetail struct {
    Code      string       `json:"code"`
    Message   string       `json:"message"`
    Details   []FieldError `json:"details,omitempty"`
    RequestID string       `json:"request_id"`
    RetryAfter *int        `json:"retry_after,omitempty"`
}
```

#### 2. 錯誤創建函數

```go
// 通用錯誤創建
func NewAPIError(httpStatus int, code, message string) *APIError

// 特定錯誤創建
func NewValidationError(message string, fieldErrors []FieldError) *APIError
func NewRateLimitError(retryAfter int) *APIError
func NewBadRequestError(message string) *APIError
func NewUnauthorizedError(message string) *APIError
func NewConflictError(message string) *APIError

// 預定義錯誤實例
var (
    ErrInternalServer = NewAPIError(500, CodeInternalError, "Internal server error")
    ErrUnauthorized   = NewAPIError(401, CodeUnauthorized, "Invalid or expired token")
    ErrForbidden      = NewAPIError(403, CodeForbidden, "Insufficient permissions")
    ErrNotFound       = NewAPIError(404, CodeNotFound, "Resource not found")
)
```

#### 3. HTTP 狀態碼映射 (`internal/pkg/utils/response.go`)

```go
func GetHTTPStatusFromCode(code string) int {
    switch code {
    case CodeValidationError:
        return http.StatusBadRequest       // 400
    case CodeUnauthorized:
        return http.StatusUnauthorized     // 401
    case CodeForbidden:
        return http.StatusForbidden        // 403
    case CodeNotFound:
        return http.StatusNotFound         // 404
    case CodeConflict:
        return http.StatusConflict         // 409
    case CodeUnprocessableEntity:
        return http.StatusUnprocessableEntity // 422
    case CodeRateLimitExceeded:
        return http.StatusTooManyRequests  // 429
    case CodeInternalError:
        return http.StatusInternalServerError // 500
    case CodeServiceUnavailable:
        return http.StatusServiceUnavailable  // 503
    default:
        return http.StatusInternalServerError // 500
    }
}
```

#### 4. 統一錯誤處理 (`internal/pkg/utils/response.go`)

```go
func HandleError(w http.ResponseWriter, err error) {
    if apiErr, ok := err.(*errors.APIError); ok {
        // 自定義 API 錯誤
        statusCode := GetHTTPStatusFromCode(apiErr.ErrorDetail.Code)
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(statusCode)
        json.NewEncoder(w).Encode(apiErr)
    } else {
        // 未知錯誤，轉換為內部服務器錯誤
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusInternalServerError)
        json.NewEncoder(w).Encode(errors.ErrInternalServer)
    }
}
```

### 錯誤使用示例

#### 1. 驗證錯誤
```go
// 單個驗證錯誤
return nil, errors.NewBadRequestError("Invalid ASIN format")

// 多字段驗證錯誤
fieldErrors := []errors.FieldError{
    {Field: "email", Message: "Email is required"},
    {Field: "password", Message: "Password must be at least 8 characters"},
}
return nil, errors.NewValidationError("Validation failed", fieldErrors)
```

#### 2. 業務邏輯錯誤
```go
// 資源不存在
return nil, errors.ErrNotFound

// 資源衝突
return nil, errors.NewConflictError("Product already being tracked")

// 權限不足
return nil, errors.ErrForbidden
```

#### 3. 限流錯誤
```go
// 限流錯誤，60秒後重試
return nil, errors.NewRateLimitError(60)
```

### 錯誤響應示例

#### 1. 驗證錯誤響應
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ],
    "request_id": "req-123e4567-e89b-12d3-a456-426614174000"
  }
}
```

#### 2. 認證錯誤響應
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token",
    "request_id": "req-123e4567-e89b-12d3-a456-426614174000"
  }
}
```

#### 3. 限流錯誤響應
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "request_id": "req-123e4567-e89b-12d3-a456-426614174000",
    "retry_after": 60
  }
}
```

## 🔐 認證與授權機制

### JWT 認證流程

1. **用戶登入**: POST `/api/auth/login`
2. **獲取令牌**: 返回 JWT Access Token
3. **API 請求**: 在 Header 中攜帶令牌
4. **令牌驗證**: 中間件自動驗證令牌有效性

### 認證配置

```go
@server (
    prefix: /api/product
    jwt:    Auth              // 啟用 JWT 認證
    middleware: RateLimitMiddleware
)
service product-api {
    // 需要認證的端點
}
```

### 請求頭格式

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

## 📊 限流策略

### Rate Limiting 實現

使用 Token Bucket 算法，基於用戶和 API 端點進行限流：

```go
@server (
    middleware: RateLimitMiddleware  // 所有端點都啟用限流
)
```

### 限流配置

| 用戶計劃 | 每分鐘請求數 | 突發請求數 | 限流範圍 |
|---------|-------------|-----------|----------|
| Basic   | 100 req/min | 120       | 按用戶ID |
| Premium | 500 req/min | 600       | 按用戶ID |
| Enterprise | 2000 req/min | 2500   | 按用戶ID |

### 限流響應

當觸發限流時，返回 429 狀態碼：

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "request_id": "req-uuid",
    "retry_after": 60
  }
}
```

## 📈 API 端點設計

### RESTful 設計原則

| HTTP Method | 用途 | 示例 |
|-------------|------|------|
| GET | 獲取資源 | `GET /api/product/products/tracked` |
| POST | 創建資源 | `POST /api/product/products/track` |
| PUT | 更新整個資源 | `PUT /api/auth/users/profile` |
| PATCH | 部分更新資源 | `PATCH /api/product/products/{id}` |
| DELETE | 刪除資源 | `DELETE /api/product/products/{id}/track` |

### URL 設計規範

#### 1. 資源命名
- 使用複數名詞：`/products`, `/users`, `/analysis`
- 使用小寫：`/api/product/products`
- 使用連字符：`/api/product/anomaly-events`

#### 2. 路徑參數
```
/api/product/products/{product_id}
/api/competitor/analysis/{analysis_id}
```

#### 3. 查詢參數
```
/api/product/products/tracked?page=1&limit=20&category=electronics
/api/product/products/anomaly-events?event_type=price_change&severity=critical
```

### 分頁設計

#### 請求參數
```json
{
  "page": 1,
  "limit": 20,
  "category": "electronics"
}
```

#### 響應格式
```json
{
  "tracked": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

## 🏷️ 服務端點概覽

### 1. 認證服務 (Auth API)

| 端點 | 方法 | 認證 | 描述 |
|------|------|------|------|
| `/api/auth/login` | POST | ❌ | 用戶登入 |
| `/api/auth/register` | POST | ❌ | 用戶註冊 |
| `/api/auth/logout` | POST | ❌ | 用戶登出 |
| `/api/auth/users/profile` | GET | ✅ | 獲取用戶資料 |
| `/api/auth/users/profile` | PUT | ✅ | 更新用戶資料 |

### 2. 產品追蹤服務 (Product API)

| 端點 | 方法 | 認證 | 描述 |
|------|------|------|------|
| `/api/product/products/track` | POST | ✅ | 添加產品追蹤 |
| `/api/product/products/tracked` | GET | ✅ | 獲取追蹤產品列表 |
| `/api/product/products/{id}` | GET | ✅ | 獲取產品詳情 |
| `/api/product/products/{id}/history` | GET | ✅ | 獲取產品歷史數據 |
| `/api/product/products/{id}/track` | DELETE | ✅ | 停止產品追蹤 |
| `/api/product/products/{id}/refresh` | POST | ✅ | 手動刷新產品數據 |
| `/api/product/products/anomaly-events` | GET | ✅ | 獲取異常事件 |

### 3. 競品分析服務 (Competitor API)

| 端點 | 方法 | 認證 | 描述 |
|------|------|------|------|
| `/api/competitor/analysis` | POST | ✅ | 創建分析組 |
| `/api/competitor/analysis` | GET | ✅ | 獲取分析組列表 |
| `/api/competitor/analysis/{id}` | GET | ✅ | 獲取分析結果 |
| `/api/competitor/analysis/{id}/competitors` | POST | ✅ | 添加競品 |
| `/api/competitor/analysis/{id}/generate-report` | POST | ✅ | 生成分析報告 |
| `/api/competitor/analysis/{id}/report-status` | GET | ✅ | 獲取報告狀態 |

### 4. 優化建議服務 (Optimization API)

| 端點 | 方法 | 認證 | 描述 |
|------|------|------|------|
| `/api/optimization/analyses` | POST | ✅ | 創建優化分析 |
| `/api/optimization/analyses` | GET | ✅ | 獲取分析列表 |
| `/api/optimization/analyses/{id}` | GET | ✅ | 獲取分析結果 |
| `/api/optimization/analyses/{id}/suggestions` | GET | ✅ | 獲取優化建議 |

### 5. 健康檢查端點

所有服務都提供標準的健康檢查端點：

| 端點 | 方法 | 認證 | 描述 |
|------|------|------|------|
| `/api/{service}/ping` | GET | ❌ | 簡單健康檢查 |
| `/api/{service}/health` | GET | ❌ | 詳細健康狀態 |

## 📝 API 文件生成

### go-zero API 文件結構

```go
syntax = "v1"

info (
    title:   "Service API"
    desc:    "Service description"
    author:  "Amazon Pilot Team"
    email:   "team@amazon-pilot.com"
    version: "v1"
)

type (
    // Request/Response 類型定義
)

@server (
    prefix:     /api/service
    middleware: RateLimitMiddleware
)
service service-api {
    // Public endpoints
}

@server (
    prefix:     /api/service
    jwt:        Auth
    middleware: RateLimitMiddleware
)
service service-api {
    // Protected endpoints
}
```

### 自動代碼生成

使用項目的統一代碼生成腳本：

```bash
# 生成所有服務代碼
./scripts/goctl-centralized.sh -s auth
./scripts/goctl-centralized.sh -s product
./scripts/goctl-centralized.sh -s competitor
./scripts/goctl-centralized.sh -s optimization
```

### 生成文件結構

```
internal/{service}/
├── handler/          # HTTP 處理器 (自動生成)
├── logic/           # 業務邏輯 (手動實現)
├── svc/             # 服務上下文 (手動配置)
├── types/           # 類型定義 (自動生成)
├── middleware/      # 中間件 (手動實現)
└── config/          # 配置 (手動實現)
```

## 🔍 API 監控與可觀測性

### 請求指標

所有 API 請求都會記錄以下指標：

1. **Request Rate**: 每秒請求數 (QPS)
2. **Response Time**: P50, P90, P95, P99 延遲
3. **Error Rate**: 錯誤率 (按狀態碼分組)
4. **Active Connections**: 活躍連接數

### 日誌格式

所有 API 請求都會記錄結構化 JSON 日誌：

```json
{
  "timestamp": "2025-09-16T10:30:00Z",
  "level": "info",
  "service": "product-api",
  "method": "GET",
  "path": "/api/product/products/tracked",
  "status_code": 200,
  "response_time_ms": 45,
  "user_id": "user-uuid",
  "request_id": "req-uuid",
  "ip": "192.168.1.100",
  "user_agent": "Amazon-Pilot-Client/1.0"
}
```

## 📚 API 使用指南

### 1. 認證流程
```bash
# 1. 用戶登入
curl -X POST /api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# 2. 使用返回的 access_token
curl -X GET /api/product/products/tracked \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

### 2. 錯誤處理
```javascript
try {
  const response = await fetch('/api/product/products/track', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ asin: 'B08N5WRWNW' })
  });

  if (!response.ok) {
    const errorData = await response.json();
    console.error('API Error:', errorData.error);
    // 處理特定錯誤代碼
    switch(errorData.error.code) {
      case 'VALIDATION_ERROR':
        // 顯示驗證錯誤
        break;
      case 'RATE_LIMIT_EXCEEDED':
        // 顯示限流提示
        break;
      default:
        // 通用錯誤處理
    }
  }
} catch (error) {
  console.error('Network Error:', error);
}
```

### 3. 分頁處理
```javascript
const fetchTrackedProducts = async (page = 1, limit = 20) => {
  const response = await fetch(
    `/api/product/products/tracked?page=${page}&limit=${limit}`,
    {
      headers: { 'Authorization': `Bearer ${token}` }
    }
  );

  const data = await response.json();
  return {
    products: data.tracked,
    pagination: data.pagination
  };
};
```

## 🚀 最佳實踐

### API 設計原則

#### DO ✅
1. **使用標準 HTTP 狀態碼**
2. **保持 API 的冪等性** (GET, PUT, DELETE)
3. **使用統一的錯誤格式**
4. **提供完整的 API 文檔**
5. **實現適當的限流策略**
6. **記錄結構化日誌**

#### DON'T ❌
1. **在 URL 中暴露敏感信息**
2. **忽略 API 版本化**
3. **返回不一致的錯誤格式**
4. **忽略安全考量** (HTTPS, 輸入驗證)
5. **缺乏適當的監控**

### 性能優化

1. **實現緩存策略**: 使用 Redis 緩存熱點數據
2. **優化數據庫查詢**: 使用索引和查詢優化
3. **實現分頁**: 避免返回大量數據
4. **使用 HTTP 壓縮**: 減少傳輸大小
5. **實現連接池**: 復用數據庫連接

## 📖 參考資料

- [RESTful API Design Guidelines](https://restfulapi.net/)
- [HTTP Status Codes](https://httpstatuses.com/)
- [JWT Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
- [API Versioning Best Practices](https://blog.postman.com/api-versioning/)
- [go-zero Documentation](https://go-zero.dev/)

---

**最後更新**: 2025-09-16
**版本**: v1.0
**維護者**: Amazon Pilot Team