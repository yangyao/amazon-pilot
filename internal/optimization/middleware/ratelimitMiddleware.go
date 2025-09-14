package middleware

import (
	"net/http"

	sharedMiddleware "amazonpilot/internal/pkg/middleware"
)

// RateLimitMiddleware 包装共享的限流中间件
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