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

### 2. user_settings (用戶設定表)
```sql
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_email BOOLEAN DEFAULT true,
    notification_push BOOLEAN DEFAULT false,
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    default_tracking_frequency VARCHAR(20) DEFAULT 'daily',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT user_settings_user_id_unique UNIQUE (user_id),
    CONSTRAINT user_settings_frequency_check CHECK (default_tracking_frequency IN ('hourly', 'daily', 'weekly'))
);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
```

## 相關服務

- **API定義**: `api/openapi/auth.api`
- **服務實現**: `internal/auth/`
- **模型定義**: `internal/pkg/models/user.go`

---

**狀態**: ✅ 已實現
**最後更新**: 2025-09-13