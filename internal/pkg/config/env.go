package config

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"

	"amazonpilot/internal/pkg/constants"
)

// EnvConfig 统一的环境变量配置
type EnvConfig struct {
	// 环境标识
	Environment string

	// 数据库配置
	Database DatabaseConfig

	// Redis配置
	Redis RedisConfig

	// JWT配置
	JWT JWTConfig

	// API密钥
	APIKeys APIKeysConfig

	// Worker配置
	Worker WorkerConfig

	// 调度器配置
	Scheduler SchedulerConfig

	// Dashboard配置
	Dashboard DashboardConfig
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	DSN             string
	MaxIdleConns    int
	MaxOpenConns    int
	ConnMaxLifetime time.Duration
}

// RedisConfig Redis配置
type RedisConfig struct {
	Host string
	Port string
	DB   int
	Addr string // 组合的地址 host:port
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret       string
	AccessSecret string
	AccessExpire int64
}

// APIKeysConfig API密钥配置
type APIKeysConfig struct {
	ApifyToken string
	OpenAIKey  string
}

// WorkerConfig Worker配置
type WorkerConfig struct {
	Concurrency int
}

// SchedulerConfig 调度器配置
type SchedulerConfig struct {
	ProductUpdateInterval string
}

// DashboardConfig Dashboard配置
type DashboardConfig struct {
	Port string
}

// LoadEnvConfig 加载环境变量配置
func LoadEnvConfig(serviceName constants.ServiceName) (*EnvConfig, error) {
	cfg := &EnvConfig{
		Environment: getEnvWithDefault("ENVIRONMENT", "development"),
	}

	// 数据库配置（某些服务如dashboard不需要）
	cfg.Database.DSN = os.Getenv("DATABASE_DSN")
	if cfg.Database.DSN == "" {
		// 只记录信息，不返回错误，因为某些服务（如dashboard）不需要数据库
		slog.Info("DATABASE_DSN not configured", "service", serviceName.String())
	} else {
		cfg.Database.MaxIdleConns = getEnvAsInt("DATABASE_MAX_IDLE_CONNS", 10)
		cfg.Database.MaxOpenConns = getEnvAsInt("DATABASE_MAX_OPEN_CONNS", 100)
		cfg.Database.ConnMaxLifetime = time.Duration(getEnvAsInt("DATABASE_CONN_MAX_LIFETIME", 3600)) * time.Second
	}

	// Redis配置
	cfg.Redis.Host = getEnvWithDefault("REDIS_HOST", "localhost")
	cfg.Redis.Port = getEnvWithDefault("REDIS_PORT", "6379")
	cfg.Redis.DB = getEnvAsInt("REDIS_DB", 0)
	cfg.Redis.Addr = cfg.Redis.Host + ":" + cfg.Redis.Port

	// JWT配置（某些服务可能不需要）
	cfg.JWT.Secret = os.Getenv("JWT_SECRET")
	cfg.JWT.AccessSecret = getEnvWithDefault("JWT_ACCESS_SECRET", cfg.JWT.Secret)
	cfg.JWT.AccessExpire = int64(getEnvAsInt("JWT_ACCESS_EXPIRE", 86400))

	// API密钥（某些服务可能不需要）
	cfg.APIKeys.ApifyToken = os.Getenv("APIFY_API_TOKEN")
	cfg.APIKeys.OpenAIKey = os.Getenv("OPENAI_API_KEY")

	// Worker配置
	cfg.Worker.Concurrency = getEnvAsInt("WORKER_CONCURRENCY", 10)

	// 调度器配置
	cfg.Scheduler.ProductUpdateInterval = getEnvWithDefault("SCHEDULER_PRODUCT_UPDATE_INTERVAL", "1h")

	// Dashboard配置
	cfg.Dashboard.Port = getEnvWithDefault("DASHBOARD_PORT", "5555")

	// 记录配置加载成功
	slog.Info("Environment configuration loaded",
		"service", serviceName.String(),
		"environment", cfg.Environment,
		"redis", cfg.Redis.Addr,
	)

	return cfg, nil
}

// MustLoadEnvConfig 加载环境变量配置，失败则panic
func MustLoadEnvConfig(serviceName constants.ServiceName) *EnvConfig {
	cfg, err := LoadEnvConfig(serviceName)
	if err != nil {
		panic(err)
	}
	return cfg
}

// ValidateRequired 验证特定服务所需的配置
func (c *EnvConfig) ValidateRequired(serviceName constants.ServiceName, required []string) error {

	for _, key := range required {
		var value string
		switch key {
		case "DATABASE_DSN":
			value = c.Database.DSN
		case "JWT_SECRET":
			value = c.JWT.Secret
		case "APIFY_API_TOKEN":
			value = c.APIKeys.ApifyToken
		case "OPENAI_API_KEY":
			value = c.APIKeys.OpenAIKey
		case "DASHBOARD_PORT":
			value = c.Dashboard.Port
		default:
			continue
		}

		if value == "" {
			err := fmt.Errorf("%s environment variable is required for %s service", key, serviceName.String())
			slog.Error("Missing required configuration", "service", serviceName.String(), "key", key)
			return err
		}
	}

	return nil
}

// 辅助函数

func getEnvWithDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}
	return value
}

func getEnvAsInt64(key string, defaultValue int64) int64 {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.ParseInt(valueStr, 10, 64)
	if err != nil {
		return defaultValue
	}
	return value
}