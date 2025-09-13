package middleware

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

// RequestIDMiddleware Request ID中间件
type RequestIDMiddleware struct{}

// NewRequestIDMiddleware 创建Request ID中间件
func NewRequestIDMiddleware() *RequestIDMiddleware {
	return &RequestIDMiddleware{}
}

// Handle 处理Request ID
func (m *RequestIDMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 生成或获取Request ID
		requestID := r.Header.Get("X-Request-ID")
		if requestID == "" {
			requestID = "req-" + uuid.New().String()
		}

		// 设置响应头
		w.Header().Set("X-Request-ID", requestID)

		// 添加到context
		ctx := context.WithValue(r.Context(), "request_id", requestID)
		r = r.WithContext(ctx)

		// 转发给后端服务
		r.Header.Set("X-Request-ID", requestID)

		next(w, r)
	}
}

// GetRequestIDFromContext 从context获取Request ID
func GetRequestIDFromContext(ctx context.Context) string {
	if requestID, ok := ctx.Value("request_id").(string); ok {
		return requestID
	}
	return "req-" + uuid.New().String()
}