# API Error Handling Standards

## 統一錯誤處理規範

### 錯誤響應格式

#### 標準錯誤結構
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
    "request_id": "req-uuid",
    "retry_after": 60
  }
}
```

### 標準錯誤碼

#### 客戶端錯誤 (4xx)
- **VALIDATION_ERROR** (400) → 請求格式或數據驗證錯誤
- **UNAUTHORIZED** (401) → 未提供有效認證
- **FORBIDDEN** (403) → 權限不足
- **NOT_FOUND** (404) → 請求的資源不存在
- **CONFLICT** (409) → 資源衝突 (如重複添加)
- **UNPROCESSABLE_ENTITY** (422) → 請求格式正確但語義錯誤
- **RATE_LIMIT_EXCEEDED** (429) → 超出API限流

#### 服務端錯誤 (5xx)
- **INTERNAL_ERROR** (500) → 內部服務器錯誤
- **SERVICE_UNAVAILABLE** (503) → 服務暫時不可用

### 實現方式

#### Go 錯誤結構
```go
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

#### 統一錯誤處理
- **Handler層**: 使用 `utils.HandleError(w, err)`
- **自動映射**: 錯誤碼自動映射到HTTP狀態碼
- **日誌記錄**: 所有錯誤自動記錄結構化日誌

---

**實現位置**: `internal/pkg/errors/` + `internal/pkg/utils/response.go`
**最後更新**: 2025-09-13