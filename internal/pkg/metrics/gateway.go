package metrics

import (
	"net/http"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Gateway metrics
var (
	// HTTP请求总数 (RED指标 - Rate)
	HTTPRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "amazon_pilot_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"service", "method", "path", "status"},
	)

	// HTTP请求耗时 (RED指标 - Duration) - 毫秒单位更精确
	HTTPRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "amazon_pilot_http_request_duration_milliseconds",
			Help:    "HTTP request duration in milliseconds",
			Buckets: []float64{1, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000},
		},
		[]string{"service", "method", "path"},
	)

	// HTTP错误计数 (RED指标 - Errors)
	HTTPErrorsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "amazon_pilot_http_errors_total",
			Help: "Total number of HTTP errors",
		},
		[]string{"service", "method", "path", "status"},
	)

	// 活跃连接数
	ActiveConnections = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "amazon_pilot_active_connections",
			Help: "Number of active connections",
		},
		[]string{"service"},
	)

	// 服务健康状态
	ServiceHealth = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "amazon_pilot_service_health",
			Help: "Service health status (1 = healthy, 0 = unhealthy)",
		},
		[]string{"service"},
	)

	// JWT认证成功/失败计数
	JWTAuthTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "amazon_pilot_jwt_auth_total",
			Help: "Total number of JWT authentication attempts",
		},
		[]string{"service", "result"},
	)

	// 限流触发计数
	RateLimitTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "amazon_pilot_rate_limit_total",
			Help: "Total number of rate limit triggers",
		},
		[]string{"service", "plan", "result"},
	)
)

// MetricsMiddleware Prometheus指标中间件
type MetricsMiddleware struct {
	serviceName string
}

// NewMetricsMiddleware 创建指标中间件
func NewMetricsMiddleware(serviceName string) *MetricsMiddleware {
	return &MetricsMiddleware{
		serviceName: serviceName,
	}
}

// Handle 处理指标收集
func (m *MetricsMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// 包装ResponseWriter以捕获状态码
		ww := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		// 增加活跃连接数
		ActiveConnections.WithLabelValues(m.serviceName).Inc()
		defer ActiveConnections.WithLabelValues(m.serviceName).Dec()
		
		// 执行请求
		next(ww, r)
		
		// 计算耗时
		duration := time.Since(start)
		statusCode := ww.statusCode
		
		// 记录指标
		labels := []string{m.serviceName, r.Method, r.URL.Path, strconv.Itoa(statusCode)}
		HTTPRequestsTotal.WithLabelValues(labels...).Inc()
		
		HTTPRequestDuration.WithLabelValues(m.serviceName, r.Method, r.URL.Path).Observe(duration.Seconds())
		
		// 记录错误
		if statusCode >= 400 {
			HTTPErrorsTotal.WithLabelValues(labels...).Inc()
		}
	}
}

// RecordJWTAuth 记录JWT认证指标
func RecordJWTAuth(serviceName string, success bool) {
	result := "success"
	if !success {
		result = "failure"
	}
	JWTAuthTotal.WithLabelValues(serviceName, result).Inc()
}

// RecordRateLimit 记录限流指标
func RecordRateLimit(serviceName, plan string, blocked bool) {
	result := "allowed"
	if blocked {
		result = "blocked"
	}
	RateLimitTotal.WithLabelValues(serviceName, plan, result).Inc()
}

// SetServiceHealth 设置服务健康状态
func SetServiceHealth(serviceName string, healthy bool) {
	value := float64(0)
	if healthy {
		value = 1
	}
	ServiceHealth.WithLabelValues(serviceName).Set(value)
}

// responseWriter 包装ResponseWriter以捕获状态码
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
	return rw.ResponseWriter.Write(b)
}