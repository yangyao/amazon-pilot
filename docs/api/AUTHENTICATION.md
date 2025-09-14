# API Authentication & Authorization

## 認證和授權機制

### JWT 認證流程

#### 1. 獲取 Token
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 86400
}
```

#### 2. 使用 Token
```http
GET /api/product/products/tracked
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Token 規範

#### JWT Payload 結構
```json
{
  "user_id": "uuid-string",
  "email": "user@example.com",
  "plan": "basic|premium|enterprise",
  "exp": 1694764800,
  "iat": 1694678400,
  "nbf": 1694678400
}
```

#### Token 安全配置
- **算法**: HS256
- **密鑰**: 環境變量配置
- **過期時間**: 24小時
- **刷新策略**: 計劃支援 refresh token

### 權限分級

#### Plan Type 權限
```yaml
basic:
  - 追蹤產品數量: 10個
  - API 請求限制: 60/分鐘
  - 數據保留期: 30天

premium:
  - 追蹤產品數量: 100個
  - API 請求限制: 600/分鐘
  - 數據保留期: 90天
  - 競品分析: 啟用

enterprise:
  - 追蹤產品數量: 無限制
  - API 請求限制: 6000/分鐘
  - 數據保留期: 365天
  - 所有功能: 啟用
```

### 認證中間件

#### 實現位置
- **Gateway層**: 統一認證檢查
- **服務層**: JWT token 解析和驗證
- **文件位置**: `internal/pkg/middleware/jwt.go`

#### 保護範圍
```yaml
無需認證:
  - /api/*/ping
  - /api/*/health
  - /api/auth/login
  - /api/auth/register

需要認證:
  - /api/product/* (除 ping/health)
  - /api/competitor/*
  - /api/optimization/*
  - /api/notification/*
```

### 安全措施

#### 1. Token 安全
- **HTTPS Only**: 生產環境強制 HTTPS
- **短過期時間**: 24小時自動過期
- **密鑰輪替**: 定期更換 JWT 密鑰

#### 2. 防護機制
- **Rate Limiting**: 防止暴力破解
- **CORS 配置**: 限制前端域名
- **輸入驗證**: 防止注入攻擊

---

**實現狀態**: ✅ 已完整實現
**安全等級**: 企業級
**最後更新**: 2025-09-13