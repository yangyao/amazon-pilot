package config

import (
	"github.com/zeromicro/go-zero/rest"
)

// BaseConfig 基础配置结构
type BaseConfig struct {
	rest.RestConf
	Database DatabaseConfig `json:"database"`
	Redis    RedisConfig    `json:"redis"`
	Auth     AuthConfig     `json:"auth"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	DSN             string `json:"dsn"`
	MaxIdleConns    int    `json:"maxIdleConns,default=10"`
	MaxOpenConns    int    `json:"maxOpenConns,default=100"`
	ConnMaxLifetime int    `json:"connMaxLifetime,default=3600"`
}

// RedisConfig Redis 配置
type RedisConfig struct {
	Host     string `json:"host,default=localhost"`
	Port     int    `json:"port,default=6379"`
	Password string `json:"password,optional"`
	DB       int    `json:"db,default=0"`
}

// AuthConfig 认证配置
type AuthConfig struct {
	JWTSecret    string `json:"jwtSecret"`
	AccessExpire int64  `json:"accessExpire,default=86400"`
	AccessSecret string `json:"accessSecret"`
}