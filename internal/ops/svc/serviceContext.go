package svc

import (
	"net/http"
	"time"

	"amazonpilot/internal/ops/config"
	"amazonpilot/internal/ops/middleware"

	"github.com/zeromicro/go-zero/rest"
)

type ServiceContext struct {
	Config              config.Config
	RateLimitMiddleware rest.Middleware
	HTTPClient          *http.Client
	GatewayURL          string
	JWTSecret           string
}

func NewServiceContext(c config.Config) *ServiceContext {
	return &ServiceContext{
		Config:              c,
		RateLimitMiddleware: middleware.NewRateLimitMiddleware().Handle,
		HTTPClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		GatewayURL: "http://localhost:8080", // 通过Gateway调用其他服务
		JWTSecret:  "amazon-pilot-jwt-secret-2025", // 用于生成service-to-service JWT
	}
}
