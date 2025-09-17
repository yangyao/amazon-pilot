package main

import (
	"flag"
	"log/slog"

	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	baseconfig "amazonpilot/internal/pkg/config"
	"amazonpilot/internal/product/config"
	"amazonpilot/internal/product/handler"
	"amazonpilot/internal/product/svc"
	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "cmd/product/etc/product-api.yaml", "the config file")

func main() {
	flag.Parse()

	serviceName := constants.ServiceProduct

	// 初始化结构化日志
	logger.InitStructuredLogger(serviceName)

	// 加载环境变量配置
	envCfg := baseconfig.MustLoadEnvConfig(serviceName)

	// 验证必需的配置
	if err := envCfg.ValidateRequired(serviceName, []string{"DATABASE_DSN", "JWT_SECRET", "APIFY_API_TOKEN"}); err != nil {
		panic(err)
	}

	// 加载YAML配置
	var c config.Config
	conf.MustLoad(*configFile, &c)

	// 设置Auth配置到config中（供自动生成的routes.go使用）
	c.Auth = baseconfig.Auth{
		JWTSecret:    envCfg.JWT.Secret,
		AccessSecret: envCfg.JWT.AccessSecret,
		AccessExpire: envCfg.JWT.AccessExpire,
	}

	// 传递环境配置给ServiceContext
	c.EnvConfig = envCfg

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	slog.Info("Product server is starting", "host", c.Host, "port", c.Port)
	server.Start()
}
