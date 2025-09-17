package svc

import (
	"amazonpilot/internal/product/config"
	"amazonpilot/internal/product/middleware"
	"amazonpilot/internal/pkg/apify"
	"amazonpilot/internal/pkg/auth"
	"amazonpilot/internal/pkg/database"

	"github.com/hibiken/asynq"
	"github.com/redis/go-redis/v9"
	"github.com/zeromicro/go-zero/rest"
	"gorm.io/gorm"
)

type ServiceContext struct {
	Config               config.Config
	DB                   *gorm.DB
	RedisClient          *redis.Client
	AsynqClient          *asynq.Client
	ApifyClient          *apify.Client
	JWTAuth              *auth.JWTAuth
	RateLimitMiddleware  rest.Middleware
}

func NewServiceContext(c config.Config) *ServiceContext {
	// 使用传入的环境配置
	envCfg := c.EnvConfig
	if envCfg == nil {
		panic("EnvConfig is not set in config")
	}

	// 连接数据库 - 使用统一的配置
	db, err := database.NewConnectionWithDSN(envCfg.Database.DSN, &database.Config{
		MaxIdleConns:    envCfg.Database.MaxIdleConns,
		MaxOpenConns:    envCfg.Database.MaxOpenConns,
		ConnMaxLifetime: int(envCfg.Database.ConnMaxLifetime.Seconds()),
	})
	if err != nil {
		panic("Failed to connect to database: " + err.Error())
	}

	// 初始化Redis客户端
	redisClient := redis.NewClient(&redis.Options{
		Addr:     envCfg.Redis.Addr,
		Password: "",
		DB:       envCfg.Redis.DB,
	})

	// 初始化Asynq客户端
	asynqClient := asynq.NewClient(asynq.RedisClientOpt{
		Addr: envCfg.Redis.Addr,
		DB:   envCfg.Redis.DB,
	})

	// 初始化Apify客户端
	apifyClient := apify.NewClient(envCfg.APIKeys.ApifyToken)

	// 初始化JWT认证
	jwtAuth := auth.NewJWTAuth(envCfg.JWT.Secret, envCfg.JWT.AccessExpire)

	// 初始化中间件
	rateLimitMiddleware := middleware.NewRateLimitMiddleware()

	return &ServiceContext{
		Config:              c,
		DB:                  db,
		RedisClient:         redisClient,
		AsynqClient:         asynqClient,
		ApifyClient:         apifyClient,
		JWTAuth:             jwtAuth,
		RateLimitMiddleware: rateLimitMiddleware.Handle,
	}
}