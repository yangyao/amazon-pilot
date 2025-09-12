package svc

import (
	"amazonpilot/internal/auth/config"
	"amazonpilot/internal/auth/middleware"
	"amazonpilot/internal/pkg/auth"
	"amazonpilot/internal/pkg/database"

	"github.com/zeromicro/go-zero/rest"
	"gorm.io/gorm"
)

type ServiceContext struct {
	Config               config.Config
	DB                   *gorm.DB
	JWTAuth              *auth.JWTAuth
	RateLimitMiddleware  rest.Middleware
}

func NewServiceContext(c config.Config) *ServiceContext {
	// 使用DSN直接连接数据库
	db, err := database.NewConnectionWithDSN(c.Database.DSN, &database.Config{
		MaxIdleConns:    c.Database.MaxIdleConns,
		MaxOpenConns:    c.Database.MaxOpenConns,
		ConnMaxLifetime: c.Database.ConnMaxLifetime,
	})
	if err != nil {
		panic("Failed to connect to database with DSN: " + err.Error())
	}

	// 初始化JWT认证
	jwtAuth := auth.NewJWTAuth(c.Auth.JWTSecret, c.Auth.AccessExpire)

	// 初始化中间件
	rateLimitMiddleware := middleware.NewRateLimitMiddleware()

	return &ServiceContext{
		Config:              c,
		DB:                  db,
		JWTAuth:             jwtAuth,
		RateLimitMiddleware: rateLimitMiddleware.Handle,
	}
}
