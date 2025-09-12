package middleware

import (
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"amazonpilot/internal/pkg/errors"

	"github.com/zeromicro/go-zero/rest/httpx"
)

// RateLimiter 限流器接口
type RateLimiter interface {
	Allow(key string) bool
	GetRetryAfter(key string) int
}

// MemoryRateLimiter 内存限流器
type MemoryRateLimiter struct {
	requests map[string][]time.Time
	mutex    sync.RWMutex
	limit    int
	window   time.Duration
}

// NewMemoryRateLimiter 创建内存限流器
func NewMemoryRateLimiter(limit int, window time.Duration) *MemoryRateLimiter {
	return &MemoryRateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}
}

// Allow 检查是否允许请求
func (rl *MemoryRateLimiter) Allow(key string) bool {
	rl.mutex.Lock()
	defer rl.mutex.Unlock()

	now := time.Now()
	windowStart := now.Add(-rl.window)

	// 获取该key的请求记录
	requests, exists := rl.requests[key]
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
	if len(validRequests) >= rl.limit {
		rl.requests[key] = validRequests
		return false
	}

	// 添加当前请求
	validRequests = append(validRequests, now)
	rl.requests[key] = validRequests

	return true
}

// GetRetryAfter 获取重试等待时间（秒）
func (rl *MemoryRateLimiter) GetRetryAfter(key string) int {
	rl.mutex.RLock()
	defer rl.mutex.RUnlock()

	requests, exists := rl.requests[key]
	if !exists || len(requests) == 0 {
		return 0
	}

	// 计算最早请求的过期时间
	oldestRequest := requests[0]
	retryAfter := oldestRequest.Add(rl.window).Sub(time.Now())
	if retryAfter < 0 {
		return 0
	}

	return int(retryAfter.Seconds()) + 1
}

// RateLimitMiddleware 限流中间件
type RateLimitMiddleware struct {
	limiters map[string]RateLimiter
}

// NewRateLimitMiddleware 创建限流中间件
func NewRateLimitMiddleware() *RateLimitMiddleware {
	return &RateLimitMiddleware{
		limiters: map[string]RateLimiter{
			"basic":      NewMemoryRateLimiter(100, time.Minute),  // 100 requests/minute
			"premium":    NewMemoryRateLimiter(500, time.Minute),  // 500 requests/minute
			"enterprise": NewMemoryRateLimiter(2000, time.Minute), // 2000 requests/minute
		},
	}
}

// Handle 限流处理
func (m *RateLimitMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 获取用户计划（如果已认证）
		plan := "basic" // 默认计划
		if userPlan := GetUserPlanFromContext(r.Context()); userPlan != "" {
			plan = userPlan
		}

		// 生成限流key（基于IP和用户计划）
		clientIP := getClientIP(r)
		rateLimitKey := clientIP + ":" + plan

		// 获取对应计划的限流器
		limiter, exists := m.limiters[plan]
		if !exists {
			limiter = m.limiters["basic"] // 默认使用basic限制
		}

		// 检查是否允许请求
		if !limiter.Allow(rateLimitKey) {
			retryAfter := limiter.GetRetryAfter(rateLimitKey)

			// 设置限流响应头
			w.Header().Set("X-RateLimit-Limit", strconv.Itoa(getRateLimitForPlan(plan)))
			w.Header().Set("X-RateLimit-Remaining", "0")
			w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(time.Duration(retryAfter)*time.Second).Unix(), 10))
			w.Header().Set("Retry-After", strconv.Itoa(retryAfter))

			httpx.ErrorCtx(r.Context(), w, errors.NewRateLimitError(retryAfter))
			return
		}

		// 设置成功的限流响应头
		remaining := getRateLimitForPlan(plan) - getCurrentUsage(limiter, rateLimitKey)
		w.Header().Set("X-RateLimit-Limit", strconv.Itoa(getRateLimitForPlan(plan)))
		w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))
		w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(time.Minute).Unix(), 10))

		next(w, r)
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

// getCurrentUsage 获取当前使用量（简化实现）
func getCurrentUsage(limiter RateLimiter, key string) int {
	// 这里可以实现更精确的当前使用量计算
	// 简化实现，返回估计值
	return 1
}