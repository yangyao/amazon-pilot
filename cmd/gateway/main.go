package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"time"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/metrics"
	"amazonpilot/internal/pkg/middleware"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// 初始化结构化日志
	logger.InitStructuredLogger()

	// 服务映射
	services := map[string]string{
		"auth":         "http://localhost:8888",
		"product":      "http://localhost:8889",
		"competitor":   "http://localhost:8890",
		"optimization": "http://localhost:8891",
		"notification": "http://localhost:8892",
		"ops":          "http://localhost:8893",
	}

	// 创建代理
	proxies := make(map[string]*httputil.ReverseProxy)
	for service, target := range services {
		targetURL, _ := url.Parse(target)
		proxies[service] = httputil.NewSingleHostReverseProxy(targetURL)
		metrics.SetServiceHealth(service, true)
		slog.Info("Service registered", "service", service, "target", target)
	}

	// 创建路由
	mux := http.NewServeMux()

	// 健康检查
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		setCORSHeaders(w, r)
		if r.Method == "OPTIONS" {
			return
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"service":"api-gateway","status":"healthy","timestamp":%d}`, time.Now().Unix())
	})

	// Prometheus指标
	mux.Handle("/metrics", promhttp.Handler())

	// API代理
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		setCORSHeaders(w, r)
		
		if r.Method == "OPTIONS" {
			return
		}

		// 解析路径
		path := strings.TrimPrefix(r.URL.Path, "/api/")
		parts := strings.Split(path, "/")
		
		if len(parts) == 0 || parts[0] == "" {
			middleware.GatewayErrorHandler(w, http.StatusBadRequest, "Service name required")
			return
		}

		serviceName := parts[0]
		proxy, exists := proxies[serviceName]
		if !exists {
			middleware.GatewayErrorHandler(w, http.StatusNotFound, fmt.Sprintf("Service '%s' not found", serviceName))
			return
		}

		// 重写路径：保留service前缀
		// /api/auth/health -> /auth/health  
		// /api/auth/login -> /auth/login
		r.URL.Path = "/" + path

		// 记录日志
		slog.Info("Proxying request",
			"service", serviceName,
			"method", r.Method,
			"original_path", "/api/"+path,
			"target_path", r.URL.Path,
		)

		// 代理请求
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		proxy.ServeHTTP(rw, r)

		// 记录指标
		duration := time.Since(start)
		metrics.HTTPRequestsTotal.WithLabelValues(serviceName, r.Method, "/api/"+path, fmt.Sprintf("%d", rw.statusCode)).Inc()
		metrics.HTTPRequestDuration.WithLabelValues(serviceName, r.Method, "/api/"+path).Observe(float64(duration.Milliseconds()))
		
		slog.Info("Request completed",
			"service", serviceName,
			"status", rw.statusCode,
			"duration_ms", duration.Milliseconds(),
		)
	})

	fmt.Println("🚀 API Gateway starting on :8080")
	fmt.Println("📡 Service routing:")
	for service, target := range services {
		fmt.Printf("   /api/%s/* → %s\n", service, target)
	}

	if err := http.ListenAndServe(":8080", mux); err != nil {
		slog.Error("Gateway failed", "error", err)
	}
}

func setCORSHeaders(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "http://localhost:3000")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
	w.Header().Set("Access-Control-Allow-Credentials", "true")
	w.Header().Set("Access-Control-Max-Age", "86400")
}

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