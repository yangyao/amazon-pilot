package middleware

import (
	"context"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"amazonpilot/internal/pkg/errors"

	"github.com/zeromicro/go-zero/rest/httpx"
)

type RateLimitMiddleware struct {
	requests map[string][]time.Time
	mutex    sync.RWMutex
}

func NewRateLimitMiddleware() *RateLimitMiddleware {
	return &RateLimitMiddleware{
		requests: make(map[string][]time.Time),
	}
}

func (m *RateLimitMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 获取客户端IP
		clientIP := getClientIP(r)
		
		// 获取用户计划（从JWT context或默认basic）
		plan := getUserPlan(r.Context())
		limit := getRateLimitForPlan(plan)
		window := time.Minute
		
		// 生成限流key
		rateLimitKey := clientIP + ":" + plan

		// 检查限流
		if !m.allow(rateLimitKey, limit, window) {
			retryAfter := m.getRetryAfter(rateLimitKey, window)

			// 设置限流响应头
			w.Header().Set("X-RateLimit-Limit", strconv.Itoa(limit))
			w.Header().Set("X-RateLimit-Remaining", "0")
			w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(window).Unix(), 10))
			w.Header().Set("Retry-After", strconv.Itoa(retryAfter))

			httpx.ErrorCtx(r.Context(), w, errors.NewRateLimitError(retryAfter))
			return
		}

		// 设置成功的限流响应头
		remaining := limit - m.getCurrentUsage(rateLimitKey, window)
		if remaining < 0 {
			remaining = 0
		}
		w.Header().Set("X-RateLimit-Limit", strconv.Itoa(limit))
		w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))
		w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(window).Unix(), 10))

		next(w, r)
	}
}

// allow 检查是否允许请求
func (m *RateLimitMiddleware) allow(key string, limit int, window time.Duration) bool {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	now := time.Now()
	windowStart := now.Add(-window)

	// 获取该key的请求记录
	requests, exists := m.requests[key]
	if !exists {
		requests = []time.Time{}
	}

	// 清理过期的请求记录
	validRequests := []time.Time{}
	for _, reqTime := range requests {
		if reqTime.After(windowStart) {
			validRequests = append(validRequests, reqTime)
		}
	}

	// 检查是否超过限制
	if len(validRequests) >= limit {
		m.requests[key] = validRequests
		return false
	}

	// 添加当前请求
	validRequests = append(validRequests, now)
	m.requests[key] = validRequests

	return true
}

// getRetryAfter 获取重试等待时间（秒）
func (m *RateLimitMiddleware) getRetryAfter(key string, window time.Duration) int {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	requests, exists := m.requests[key]
	if !exists || len(requests) == 0 {
		return 0
	}

	// 计算最早请求的过期时间
	oldestRequest := requests[0]
	retryAfter := oldestRequest.Add(window).Sub(time.Now())
	if retryAfter < 0 {
		return 0
	}

	return int(retryAfter.Seconds()) + 1
}

// getCurrentUsage 获取当前使用量
func (m *RateLimitMiddleware) getCurrentUsage(key string, window time.Duration) int {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	requests, exists := m.requests[key]
	if !exists {
		return 0
	}

	now := time.Now()
	windowStart := now.Add(-window)
	count := 0

	for _, reqTime := range requests {
		if reqTime.After(windowStart) {
			count++
		}
	}

	return count
}

// getUserPlan 从context获取用户计划
func getUserPlan(ctx context.Context) string {
	// 尝试从JWT context获取plan
	if plan := ctx.Value("plan"); plan != nil {
		if planStr, ok := plan.(string); ok {
			return planStr
		}
	}
	
	// 默认返回basic
	return "basic"
}

// getRateLimitForPlan 获取计划对应的限流数量
func getRateLimitForPlan(plan string) int {
	switch plan {
	case "premium":
		return 500
	case "enterprise":
		return 2000
	default:
		return 100
	}
}

// getClientIP 获取客户端IP
func getClientIP(r *http.Request) string {
	// 检查X-Forwarded-For header
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return strings.Split(xff, ",")[0]
	}

	// 检查X-Real-IP header
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}

	// 使用RemoteAddr
	return strings.Split(r.RemoteAddr, ":")[0]
}
