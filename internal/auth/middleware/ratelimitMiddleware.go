package middleware

import (
	"net/http"

	sharedMiddleware "amazonpilot/internal/pkg/middleware"
)

// RateLimitMiddleware 包装共享的限流中间件
// 这样每个服务都可以使用相同的限流逻辑
type RateLimitMiddleware struct {
	shared *sharedMiddleware.RateLimitMiddleware
}

func NewRateLimitMiddleware() *RateLimitMiddleware {
	return &RateLimitMiddleware{
		shared: sharedMiddleware.NewRateLimitMiddleware(),
	}
}

func (m *RateLimitMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return m.shared.Handle(next)
}