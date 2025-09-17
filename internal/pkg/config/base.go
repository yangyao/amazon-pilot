package config

import (
	"github.com/zeromicro/go-zero/rest"
)

type Auth struct {
	JWTSecret    string `json:"jwtSecret"`
	AccessSecret string `json:"accessSecret"`
	AccessExpire int64  `json:"accessExpire"`
}

// BaseConfig 基础配置结构
type BaseConfig struct {
	rest.RestConf
	Auth       Auth       `json:"auth"`
	EnvConfig  *EnvConfig `json:"-"` // 环境变量配置，不序列化
}
