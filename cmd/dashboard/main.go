package main

import (
	"log/slog"
	"net/http"

	baseconfig "amazonpilot/internal/pkg/config"
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"

	"github.com/hibiken/asynq"
	"github.com/hibiken/asynqmon"
)

func main() {
	serviceName := constants.ServiceDashboard

	// 初始化结构化日志
	logger.InitStructuredLogger(serviceName)

	// 加载环境变量配置
	envCfg := baseconfig.MustLoadEnvConfig(serviceName)

	// 验证必需的配置
	if err := envCfg.ValidateRequired(serviceName, []string{"DASHBOARD_PORT"}); err != nil {
		panic(err)
	}

	// 启动Asynq Dashboard
	h := asynqmon.New(asynqmon.Options{
		RootPath: "/",
		RedisConnOpt: asynq.RedisClientOpt{
			Addr: envCfg.Redis.Addr,
			DB:   envCfg.Redis.DB,
		},
	})

	// 启动HTTP服务器
	slog.Info("Dashboard server is starting",
		"port", envCfg.Dashboard.Port,
		"redis", envCfg.Redis.Addr,
	)

	err := http.ListenAndServe(":"+envCfg.Dashboard.Port, h)
	if err != nil {
		slog.Error("Failed to start dashboard server", "error", err)
		panic(err)
	}
}
