package config

import (
	"amazonpilot/internal/pkg/config"
)

type Config struct {
	config.BaseConfig
	Auth struct {
		JWTSecret    string `json:"jwtSecret"`
		AccessSecret string `json:"accessSecret"`
		AccessExpire int64  `json:"accessExpire"`
	}
}
