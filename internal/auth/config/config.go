package config

import (
	"time"

	"github.com/zeromicro/go-zero/rest"
)

type Config struct {
	rest.RestConf
	Supabase struct {
		Dsn             string
		Ssl             bool
		PoolSize        int
		MaxIdleConns    int
		MaxOpenConns    int
		ConnMaxLifetime time.Duration
		ConnMaxIdleTime time.Duration
		ConnMaxOpenTime time.Duration
	}
}
