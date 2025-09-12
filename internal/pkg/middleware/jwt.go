package middleware

import (
	"context"
	"net/http"
	"strings"

	"amazonpilot/internal/pkg/auth"
	"amazonpilot/internal/pkg/errors"

	"github.com/zeromicro/go-zero/rest/httpx"
)

// JWTMiddleware JWT认证中间件
type JWTMiddleware struct {
	jwtAuth *auth.JWTAuth
}

// NewJWTMiddleware 创建JWT中间件
func NewJWTMiddleware(jwtAuth *auth.JWTAuth) *JWTMiddleware {
	return &JWTMiddleware{
		jwtAuth: jwtAuth,
	}
}

// Handle JWT认证处理
func (m *JWTMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 从Authorization header获取token
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			httpx.ErrorCtx(r.Context(), w, errors.NewUnauthorizedError("Authorization header is required"))
			return
		}

		// 检查Bearer前缀
		if !strings.HasPrefix(authHeader, "Bearer ") {
			httpx.ErrorCtx(r.Context(), w, errors.NewUnauthorizedError("Invalid authorization header format"))
			return
		}

		// 提取token
		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token == "" {
			httpx.ErrorCtx(r.Context(), w, errors.NewUnauthorizedError("Token is required"))
			return
		}

		// 验证token
		claims, err := m.jwtAuth.ValidateToken(token)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, errors.NewUnauthorizedError("Invalid or expired token"))
			return
		}

		// 将用户信息添加到context
		ctx := context.WithValue(r.Context(), "user_id", claims.UserID)
		ctx = context.WithValue(ctx, "user_email", claims.Email)
		ctx = context.WithValue(ctx, "user_plan", claims.Plan)

		// 继续处理请求
		next(w, r.WithContext(ctx))
	}
}

// GetUserIDFromContext 从context获取用户ID
func GetUserIDFromContext(ctx context.Context) string {
	if userID, ok := ctx.Value("user_id").(string); ok {
		return userID
	}
	return ""
}

// GetUserEmailFromContext 从context获取用户邮箱
func GetUserEmailFromContext(ctx context.Context) string {
	if email, ok := ctx.Value("user_email").(string); ok {
		return email
	}
	return ""
}

// GetUserPlanFromContext 从context获取用户计划
func GetUserPlanFromContext(ctx context.Context) string {
	if plan, ok := ctx.Value("user_plan").(string); ok {
		return plan
	}
	return ""
}