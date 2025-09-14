package config

import "github.com/zeromicro/go-zero/rest"

type Config struct {
	rest.RestConf
	Auth struct {
		JWTSecret    string `json:"jwtSecret"`
		AccessSecret string `json:"accessSecret"`
		AccessExpire int64  `json:"accessExpire"`
	}
}
