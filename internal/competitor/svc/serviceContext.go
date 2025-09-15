package svc

import (
	"fmt"
	"os"
	"strconv"

	"amazonpilot/internal/competitor/config"
	"amazonpilot/internal/competitor/middleware"
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
	JWTAuth              *auth.JWTAuth
	RateLimitMiddleware  rest.Middleware
}

func NewServiceContext(c config.Config) *ServiceContext {
	// 强制从环境变量获取数据库配置
	dsn := os.Getenv("DATABASE_DSN")
	if dsn == "" {
		panic("DATABASE_DSN environment variable is required")
	}

	maxIdleConnsStr := os.Getenv("DATABASE_MAX_IDLE_CONNS")
	if maxIdleConnsStr == "" {
		panic("DATABASE_MAX_IDLE_CONNS environment variable is required")
	}
	maxIdleConns, err := strconv.Atoi(maxIdleConnsStr)
	if err != nil {
		panic("Invalid DATABASE_MAX_IDLE_CONNS: " + err.Error())
	}

	maxOpenConnsStr := os.Getenv("DATABASE_MAX_OPEN_CONNS")
	if maxOpenConnsStr == "" {
		panic("DATABASE_MAX_OPEN_CONNS environment variable is required")
	}
	maxOpenConns, err := strconv.Atoi(maxOpenConnsStr)
	if err != nil {
		panic("Invalid DATABASE_MAX_OPEN_CONNS: " + err.Error())
	}

	connMaxLifetimeStr := os.Getenv("DATABASE_CONN_MAX_LIFETIME")
	if connMaxLifetimeStr == "" {
		panic("DATABASE_CONN_MAX_LIFETIME environment variable is required")
	}
	connMaxLifetime, err := strconv.Atoi(connMaxLifetimeStr)
	if err != nil {
		panic("Invalid DATABASE_CONN_MAX_LIFETIME: " + err.Error())
	}

	// 连接数据库
	db, err := database.NewConnectionWithDSN(dsn, &database.Config{
		MaxIdleConns:    maxIdleConns,
		MaxOpenConns:    maxOpenConns,
		ConnMaxLifetime: connMaxLifetime,
	})
	if err != nil {
		panic("Failed to connect to database with DSN: " + err.Error())
	}

	// 强制从环境变量获取JWT配置
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		panic("JWT_SECRET environment variable is required")
	}

	accessExpireStr := os.Getenv("JWT_ACCESS_EXPIRE")
	if accessExpireStr == "" {
		panic("JWT_ACCESS_EXPIRE environment variable is required")
	}
	accessExpire, err := strconv.ParseInt(accessExpireStr, 10, 64)
	if err != nil {
		panic("Invalid JWT_ACCESS_EXPIRE: " + err.Error())
	}

	// 初始化JWT认证
	jwtAuth := auth.NewJWTAuth(jwtSecret, accessExpire)

	// 强制从环境变量获取Redis配置
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		panic("REDIS_HOST environment variable is required")
	}

	redisPortStr := os.Getenv("REDIS_PORT")
	if redisPortStr == "" {
		panic("REDIS_PORT environment variable is required")
	}
	redisPort, err := strconv.Atoi(redisPortStr)
	if err != nil {
		panic("Invalid REDIS_PORT: " + err.Error())
	}

	redisDBStr := os.Getenv("REDIS_DB")
	if redisDBStr == "" {
		redisDBStr = "0" // 默认值
	}
	redisDB, err := strconv.Atoi(redisDBStr)
	if err != nil {
		panic("Invalid REDIS_DB: " + err.Error())
	}

	// 创建Redis客户端
	redisClient := redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%d", redisHost, redisPort),
		DB:   redisDB,
	})

	// 创建Asynq客户端
	asynqClient := asynq.NewClient(asynq.RedisClientOpt{
		Addr: fmt.Sprintf("%s:%d", redisHost, redisPort),
		DB:   redisDB,
	})

	// 初始化中间件
	rateLimitMiddleware := middleware.NewRateLimitMiddleware()

	return &ServiceContext{
		Config:              c,
		DB:                  db,
		RedisClient:         redisClient,
		AsynqClient:         asynqClient,
		JWTAuth:             jwtAuth,
		RateLimitMiddleware: rateLimitMiddleware.Handle,
	}
}
