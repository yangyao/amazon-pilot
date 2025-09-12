# API 設計文件

## 概述

本文件描述 Amazon 賣家產品監控與優化工具的 RESTful API 設計，包含產品追蹤、競品分析和 Listing 優化建議功能。

## 基本資訊

- **Base URL**: `https://api.amazon-monitor.com/v1`
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

### goZero 認證實現

```go
// 認證服務
package auth

import (
    "errors"
    "time"

    "github.com/golang-jwt/jwt/v4"
    "github.com/zeromicro/go-zero/core/logx"
    "golang.org/x/crypto/bcrypt"
    "gorm.io/gorm"
)

type AuthService struct {
    db          *gorm.DB
    jwtSecret   string
    accessExpire int64
}

type Claims struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Plan   string `json:"plan"`
    jwt.RegisteredClaims
}

type User struct {
    ID           string `gorm:"primaryKey"`
    Email        string `gorm:"uniqueIndex"`
    PasswordHash string
    Plan         string
    CreatedAt    time.Time
    UpdatedAt    time.Time
}

func NewAuthService(db *gorm.DB, jwtSecret string, accessExpire int64) *AuthService {
    return &AuthService{
        db:           db,
        jwtSecret:    jwtSecret,
        accessExpire: accessExpire,
    }
}

// 密碼加密
func (s *AuthService) HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

// 密碼驗證
func (s *AuthService) CheckPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}

// 生成 JWT Token
func (s *AuthService) GenerateToken(userID, email, plan string) (string, error) {
    now := time.Now()
    claims := Claims{
        UserID: userID,
        Email:  email,
        Plan:   plan,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(s.accessExpire) * time.Second)),
            IssuedAt:  jwt.NewNumericDate(now),
            NotBefore: jwt.NewNumericDate(now),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(s.jwtSecret))
}

// 驗證 JWT Token
func (s *AuthService) ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New("unexpected signing method")
        }
        return []byte(s.jwtSecret), nil
    })

    if err != nil {
        return nil, err
    }

    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }

    return nil, errors.New("invalid token")
}

// 用戶登入
func (s *AuthService) Login(email, password string) (*User, string, error) {
    var user User
    if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, "", errors.New("user not found")
        }
        return nil, "", err
    }

    if !s.CheckPassword(password, user.PasswordHash) {
        return nil, "", errors.New("invalid password")
    }

    token, err := s.GenerateToken(user.ID, user.Email, user.Plan)
    if err != nil {
        return nil, "", err
    }

    return &user, token, nil
}

// 用戶註冊
func (s *AuthService) Register(email, password, plan string) (*User, error) {
    // 檢查用戶是否已存在
    var existingUser User
    if err := s.db.Where("email = ?", email).First(&existingUser).Error; err == nil {
        return nil, errors.New("user already exists")
    }

    // 加密密碼
    hashedPassword, err := s.HashPassword(password)
    if err != nil {
        return nil, err
    }

    // 創建新用戶
    user := User{
        ID:           generateUUID(),
        Email:        email,
        PasswordHash: hashedPassword,
        Plan:         plan,
        CreatedAt:    time.Now(),
        UpdatedAt:    time.Now(),
    }

    if err := s.db.Create(&user).Error; err != nil {
        return nil, err
    }

    return &user, nil
}

// 中間件：獲取當前用戶
func (s *AuthService) GetCurrentUser(tokenString string) (*User, error) {
    claims, err := s.ValidateToken(tokenString)
    if err != nil {
        return nil, err
    }

    var user User
    if err := s.db.Where("id = ?", claims.UserID).First(&user).Error; err != nil {
        return nil, err
    }

    return &user, nil
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

### goZero Rate Limiting 實現

```go
// 限流中間件
package middleware

import (
    "context"
    "fmt"
    "net/http"
    "strconv"
    "time"

    "github.com/zeromicro/go-zero/core/logx"
    "github.com/zeromicro/go-zero/core/stores/redis"
    "github.com/zeromicro/go-zero/rest/httpx"
)

type RateLimiter struct {
    redis *redis.Redis
}

func NewRateLimiter(redis *redis.Redis) *RateLimiter {
    return &RateLimiter{redis: redis}
}

// 根據用戶計劃獲取限流設定
func (rl *RateLimiter) getRateLimit(plan string) int {
    limits := map[string]int{
        "basic":     100,
        "premium":   500,
        "enterprise": 2000,
    }
    if limit, ok := limits[plan]; ok {
        return limit
    }
    return 100
}

// 限流中間件
func (rl *RateLimiter) RateLimitMiddleware() rest.Middleware {
    return func(next http.HandlerFunc) http.HandlerFunc {
        return func(w http.ResponseWriter, r *http.Request) {
            // 從 context 獲取用戶信息
            user := getUserFromContext(r.Context())
            if user == nil {
                httpx.WriteJson(w, http.StatusUnauthorized, map[string]interface{}{
                    "error": map[string]interface{}{
                        "code":    "UNAUTHORIZED",
                        "message": "User not authenticated",
                    },
                })
                return
            }

            // 獲取限流設定
            limit := rl.getRateLimit(user.Plan)
            
            // 檢查限流
            remaining, resetTime, allowed := rl.checkRateLimit(r, user.ID, limit)
            
            // 設置限流 headers
            w.Header().Set("X-RateLimit-Limit", strconv.Itoa(limit))
            w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))
            w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(resetTime, 10))
            
            if !allowed {
                httpx.WriteJson(w, http.StatusTooManyRequests, map[string]interface{}{
                    "error": map[string]interface{}{
                        "code":    "RATE_LIMIT_EXCEEDED",
                        "message": "Too many requests",
                        "retry_after": 60,
                    },
                })
                return
            }

            next(w, r)
        }
    }
}

// 檢查限流並返回詳細信息
func (rl *RateLimiter) checkRateLimit(r *http.Request, userID string, limit int) (remaining int, resetTime int64, allowed bool) {
    // 使用滑動窗口算法
    now := time.Now()
    windowStart := now.Unix() / 60
    key := fmt.Sprintf("rate_limit:%s:%d", userID, windowStart)
    
    // 獲取當前計數
    count, err := rl.redis.Get(key)
    if err != nil && err != redis.Nil {
        logx.Errorf("Failed to get rate limit count: %v", err)
        return limit, now.Unix() + 60, true // 出錯時允許通過
    }
    
    currentCount := 0
    if count != "" {
        currentCount, _ = strconv.Atoi(count)
    }
    
    remaining = limit - currentCount - 1
    resetTime = (windowStart + 1) * 60
    
    // 檢查是否超過限制
    if currentCount >= limit {
        return 0, resetTime, false
    }
    
    // 增加計數
    pipe := rl.redis.Pipeline()
    pipe.Incr(key)
    pipe.Expire(key, 60*time.Second)
    _, err = pipe.Exec()
    if err != nil {
        logx.Errorf("Failed to increment rate limit: %v", err)
    }
    
    return remaining, resetTime, true
}
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

#### FastAPI 實現

```python
from pydantic import BaseModel, EmailStr, validator
from typing import Optional, Literal
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer

# Pydantic 模型
class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str
    company_name: Optional[str] = None
    plan: Literal["basic", "premium", "enterprise"] = "basic"
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

class UserRegisterResponse(BaseModel):
    message: str
    user_id: str

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict

# 路由定義
auth_router = APIRouter(prefix="/auth", tags=["authentication"])

@auth_router.post("/register", response_model=UserRegisterResponse, status_code=201)
async def register_user(user_data: UserRegisterRequest):
    """用戶註冊"""
    try:
        # 檢查用戶是否已存在
        existing_user = await get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this email already exists"
            )
        
        # 創建新用戶
        user_id = await create_user(user_data)
        
        return UserRegisterResponse(
            message="User created successfully",
            user_id=user_id
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create user"
        )

@auth_router.post("/login", response_model=UserLoginResponse)
async def login_user(login_data: UserLoginRequest):
    """用戶登入"""
    # 驗證用戶憑證
    user = await authenticate_user(login_data.email, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 生成 JWT token
    access_token = auth_service.create_access_token(
        data={"sub": user.id, "email": user.email}
    )
    
    return UserLoginResponse(
        access_token=access_token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user={
            "id": user.id,
            "email": user.email,
            "role": user.role
        }
    )
```

#### 用戶資料更新
```http
PUT /users/profile
Authorization: Bearer <token>

{
  "company_name": "Updated Store Name",
  "notification_settings": {
    "email": true,
    "push": false
  }
}

Response: 200 OK
{
  "message": "Profile updated successfully"
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

#### 取得追蹤產品列表
```http
GET /products/tracked?page=1&limit=20&category=electronics&status=active
Authorization: Bearer <token>

Response: 200 OK
{
  "products": [
    {
      "id": "prod-uuid",
      "asin": "B08N5WRWNW",
      "title": "Sony WH-1000XM4 Wireless Headphones",
      "alias": "我的藍牙耳機",
      "current_price": 299.99,
      "currency": "USD",
      "bsr": 15,
      "rating": 4.5,
      "review_count": 1250,
      "buy_box_price": 299.99,
      "last_updated": "2024-01-14T15:30:00Z",
      "status": "active"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "total_pages": 3
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

### 3. 競品分析 API

#### 建立競品分析群組
```http
POST /competitor-analysis
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "藍牙耳機競品分析",
  "main_product_asin": "B08N5WRWNW",
  "competitor_asins": [
    "B087C8Q3PD",
    "B08PKHGJDQ",
    "B086DGBSPX"
  ],
  "analysis_settings": {
    "update_frequency": "daily",
    "metrics": ["price", "bsr", "rating", "features"]
  }
}

Response: 201 Created
{
  "analysis_id": "analysis-uuid",
  "status": "pending",
  "estimated_completion": "2024-01-15T10:00:00Z"
}
```

#### 取得競品分析結果
```http
GET /competitor-analysis/{analysis_id}
Authorization: Bearer <token>

Response: 200 OK
{
  "id": "analysis-uuid",
  "name": "藍牙耳機競品分析",
  "status": "completed",
  "created_at": "2024-01-14T15:00:00Z",
  "updated_at": "2024-01-14T16:30:00Z",
  "main_product": {
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

#### 取得競品分析報告
```http
GET /competitor-analysis/{analysis_id}/report
Authorization: Bearer <token>

Response: 200 OK
{
  "analysis_id": "analysis-uuid",
  "report": {
    "executive_summary": "Your product is positioned in the premium segment...",
    "price_analysis": {
      "your_price": 299.99,
      "avg_competitor_price": 285.50,
      "price_ranking": 3,
      "recommendation": "Consider 5-10% price reduction"
    },
    "performance_analysis": {
      "bsr_ranking": 15,
      "avg_competitor_bsr": 12,
      "rating_comparison": "Above average",
      "review_velocity": "Moderate"
    },
    "feature_comparison": {
      "unique_features": ["Quick Attention Mode", "LDAC Audio"],
      "missing_features": ["Water Resistance"],
      "feature_gaps": []
    }
  },
  "generated_at": "2024-01-14T16:30:00Z"
}
```

### 4. Listing 優化建議 API

#### 生成優化建議
```http
POST /optimization/analyze
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
GET /optimization/{analysis_id}
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

### 5. 通知與警告 API

#### 取得通知列表
```http
GET /notifications?page=1&limit=20&type=alert&status=unread
Authorization: Bearer <token>

Response: 200 OK
{
  "notifications": [
    {
      "id": "notif-uuid",
      "type": "price_alert",
      "title": "Price Drop Alert",
      "message": "Sony WH-1000XM4 price dropped by 15%",
      "product_id": "prod-uuid",
      "severity": "medium",
      "created_at": "2024-01-14T10:00:00Z",
      "read_at": null,
      "data": {
        "old_price": 299.99,
        "new_price": 254.99,
        "change_percentage": -15.0
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "total_pages": 1
  }
}
```

#### 標記通知為已讀
```http
PUT /notifications/{notification_id}/read
Authorization: Bearer <token>

Response: 200 OK
{
  "message": "Notification marked as read"
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

Response Headers:
Link: <https://api.amazon-monitor.com/v1/products/tracked?page=1&limit=50>; rel="first",
      <https://api.amazon-monitor.com/v1/products/tracked?page=3&limit=50>; rel="next",
      <https://api.amazon-monitor.com/v1/products/tracked?page=10&limit=50>; rel="last"
```

## 快取策略

- `Cache-Control` headers 用於指示快取策略
- ETags 用於條件式請求
- 產品資料快取 24 小時
- 分析結果快取 1 小時

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
