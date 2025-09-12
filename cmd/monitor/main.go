package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/hibiken/asynqmon"
	"github.com/zeromicro/go-zero/core/logx"
)

func main() {
	// 初始化日志
	logx.MustSetup(logx.LogConf{
		ServiceName: "asynq-monitor",
		Mode:        "file",
		Path:        "/var/log/amazon-pilot",
		Level:       "info",
	})

	// 获取 Redis 地址
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis://localhost:6379"
	}

	// 创建 Asynq Monitor
	h := asynqmon.New(asynqmon.Options{
		RootPath:     "/", // 根路径
		RedisConnOpt: asynqmon.RedisConnOpt{Addr: redisAddr},
		PayloadFormatter: asynqmon.PayloadFormatterFunc(func(payload []byte) string {
			// 格式化任务负载显示
			return string(payload)
		}),
	})

	// 启动监控服务器
	logx.Info("Starting Asynq monitor on :5555...")

	// 优雅关闭
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		logx.Info("Shutting down monitor...")
	}()

	// 启动 HTTP 服务器
	if err := h.Run(":5555"); err != nil {
		log.Fatalf("Could not start monitor: %v", err)
	}
}
