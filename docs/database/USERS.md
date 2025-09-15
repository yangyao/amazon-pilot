# Auth Service Database Design

## 用戶管理相關表

### 1. users (用戶表)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_plan_type_check CHECK (plan_type IN ('basic', 'premium', 'enterprise'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan_type ON users(plan_type);
CREATE INDEX idx_users_created_at ON users(created_at);
```

> 說明：user_settings 已移除（由服務層配置代替），目前僅保留 users 表。

## 相關服務

- **API定義**: `api/openapi/auth.api`
- **服務實現**: `internal/auth/`
- **模型定義**: `internal/pkg/models/user.go`

---

**狀態**: ✅ 已實現
**最後更新**: 2025-09-13
