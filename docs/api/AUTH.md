# Auth Service API Design

## 認證服務 API 設計

### API 前綴
- **Base URL**: `/api/auth`
- **認證**: 部分端點無需認證 (登錄、註冊)

## 核心 API 端點

### 1. 用戶認證

#### 用戶註冊
- **端點**: `POST /api/auth/register`
- **認證**: 無需
- **請求**:
```json
{
  "email": "user@example.com",
  "password": "secure_password",
  "company_name": "My Company"
}
```
- **響應**:
```json
{
  "message": "User created successfully",
  "user_id": "uuid"
}
```

#### 用戶登錄
- **端點**: `POST /api/auth/login`
- **認證**: 無需
- **請求**:
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```
- **響應**:
```json
{
  "access_token": "jwt_token",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "plan": "basic",
    "is_active": true
  }
}
```

#### Token 刷新
- **端點**: `POST /api/auth/refresh`
- **認證**: 需要有效 JWT
- **響應**: 新的 access_token

### 2. 用戶管理

#### 獲取用戶信息
- **端點**: `GET /api/auth/me`
- **認證**: JWT Required
- **響應**:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "company_name": "My Company",
    "plan": "premium",
    "is_active": true,
    "email_verified": true,
    "created_at": "2025-09-13T10:00:00Z"
  }
}
```

#### 更新用戶信息
- **端點**: `PUT /api/auth/me`
- **認證**: JWT Required
- **請求**:
```json
{
  "company_name": "Updated Company",
  "timezone": "Asia/Taipei"
}
```

### 3. 密碼管理

#### 修改密碼
- **端點**: `PUT /api/auth/password`
- **認證**: JWT Required
- **請求**:
```json
{
  "current_password": "old_password",
  "new_password": "new_secure_password"
}
```

#### 忘記密碼
- **端點**: `POST /api/auth/forgot-password`
- **認證**: 無需
- **請求**:
```json
{
  "email": "user@example.com"
}
```

## JWT Token 規範

### Token 結構
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "plan": "basic|premium|enterprise",
  "exp": 1694764800,
  "iat": 1694678400
}
```

### 過期策略
- **Access Token**: 24小時
- **Refresh Token**: 30天 (計劃中)

## 錯誤處理

### 常見錯誤
- **VALIDATION_ERROR**: 郵箱格式錯誤、密碼強度不足
- **UNAUTHORIZED**: 登錄憑證無效
- **CONFLICT**: 郵箱已存在
- **NOT_FOUND**: 用戶不存在

---

**API 定義文件**: `api/openapi/auth.api`
**服務實現**: `internal/auth/`
**狀態**: ✅ 已實現
**最後更新**: 2025-09-13