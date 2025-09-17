package main

import (
	"log"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	baseconfig "amazonpilot/internal/pkg/config"
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/tasks"

	"github.com/hibiken/asynq"
)

func main() {
	serviceName := constants.ServiceWorker

	// 初始化结构化日志
	logger.InitStructuredLogger(serviceName)

	// 加载环境变量配置
	envCfg := baseconfig.MustLoadEnvConfig(serviceName)

	// 验证必需的配置
	if err := envCfg.ValidateRequired(serviceName, []string{"APIFY_API_TOKEN"}); err != nil {
		panic(err)
	}

	slog.Info("Amazon Pilot Worker starting",
		"redis", envCfg.Redis.Addr,
		"redis_db", envCfg.Redis.DB,
		"concurrency", envCfg.Worker.Concurrency,
	)

	// Redis连接配置
	redisOpt := asynq.RedisClientOpt{
		Addr: envCfg.Redis.Addr,
		DB:   envCfg.Redis.DB,
	}

	// 创建任务服务器
	srv := asynq.NewServer(redisOpt, asynq.Config{
		Concurrency: envCfg.Worker.Concurrency,
		Queues: map[string]int{
			"critical": 6, // 异常检测、紧急通知
			"default":  3, // 一般数据刷新
			"apify":    2, // Apify数据获取
			"cleanup":  1, // 数据清理
		},
	})

	// 创建任务处理器
	processor := tasks.NewApifyTaskProcessor(
		envCfg.Database.DSN,
		envCfg.APIKeys.ApifyToken,
		envCfg.Redis.Addr,
	)

	// 注册任务处理函数
	mux := asynq.NewServeMux()
	mux.HandleFunc(tasks.TypeRefreshProductData, processor.HandleRefreshProductData)
	mux.HandleFunc(tasks.TypeGenerateReport, processor.HandleGenerateReport)

	// 优雅关闭处理
	go func() {
		slog.Info("Worker server starting processing")
		if err := srv.Run(mux); err != nil {
			slog.Error("Worker server failed", "error", err)
			log.Fatalf("Worker server failed: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGTERM, syscall.SIGINT)
	sig := <-quit

	slog.Info("Worker shutdown initiated", "signal", sig.String())
	srv.Shutdown()
	slog.Info("Worker shutdown complete")
}