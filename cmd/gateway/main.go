package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"time"

	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/metrics"
	"amazonpilot/internal/pkg/middleware"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"gopkg.in/yaml.v2"
)

type Config struct {
	Name      string            `yaml:"Name"`
	Host      string            `yaml:"Host"`
	Port      int               `yaml:"Port"`
	Services  map[string]string `yaml:"Services"`
	RateLimit struct {
		RequestsPerSecond int `yaml:"RequestsPerSecond"`
		BurstSize         int `yaml:"BurstSize"`
	} `yaml:"RateLimit"`
}

func loadConfig() *Config {
	configFile := "cmd/gateway/etc/gateway.yaml"
	if len(os.Args) > 1 && strings.HasPrefix(os.Args[1], "-f") {
		if len(os.Args) > 2 {
			configFile = os.Args[2]
		}
	}

	data, err := os.ReadFile(configFile)
	if err != nil {
		slog.Error("Failed to read config file", "file", configFile, "error", err)
		os.Exit(1)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		slog.Error("Failed to parse config file", "file", configFile, "error", err)
		os.Exit(1)
	}

	return &config
}

func main() {
	serviceName := constants.ServiceGateway

	// 初始化结构化日志
	logger.InitStructuredLogger(serviceName)

	// 加载YAML配置
	config := loadConfig()
	slog.Info("Gateway configuration loaded",
		"name", config.Name,
		"host", config.Host,
		"port", config.Port,
		"services", len(config.Services))

	// 服务映射从配置文件读取
	services := config.Services

	// 创建代理
	proxies := make(map[string]*httputil.ReverseProxy)
	for service, target := range services {
		targetURL, _ := url.Parse(target)
		proxy := httputil.NewSingleHostReverseProxy(targetURL)

		// 设置更长的超时时间，适合Apify搜索
		proxy.Transport = &http.Transport{
			ResponseHeaderTimeout: 10 * time.Minute, // 10分钟超时
			IdleConnTimeout:       15 * time.Minute,
		}

		proxies[service] = proxy
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

	// API代理 - 简化路由，直接转发完整路径
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		setCORSHeaders(w, r)

		if r.Method == "OPTIONS" {
			return
		}

		// 解析服务名：/api/auth/... -> auth
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

		// 记录日志
		slog.Info("Proxying request", "service", serviceName, "method", r.Method, "path", r.URL.Path)

		// 代理请求
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		proxy.ServeHTTP(rw, r)

		// 记录指标
		duration := time.Since(start)
		metrics.HTTPRequestsTotal.WithLabelValues(serviceName, r.Method, r.URL.Path, fmt.Sprintf("%d", rw.statusCode)).Inc()
		metrics.HTTPRequestDuration.WithLabelValues(serviceName, r.Method, r.URL.Path).Observe(float64(duration.Milliseconds()))

		slog.Info("Request completed", "service", serviceName, "status", rw.statusCode, "duration_ms", duration.Milliseconds())
	})

	addr := fmt.Sprintf("%s:%d", config.Host, config.Port)
	slog.Info("Gateway is starting", "name", config.Name, "address", addr)
	slog.Info("Service routing:")
	for service, target := range services {
		slog.Info("Service routing", "service", service, "target", target)
	}

	slog.Info("API Gateway is starting", "address", addr, "services", len(services))

	if err := http.ListenAndServe(addr, mux); err != nil {
		slog.Error("Gateway failed", "error", err)
		panic(err)
	}
}

func setCORSHeaders(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "http://localhost:4000")
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
