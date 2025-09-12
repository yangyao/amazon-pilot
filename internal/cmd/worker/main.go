package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/hibiken/asynq"
	"github.com/zeromicro/go-zero/core/logx"
)

func main() {
	// 初始化日志
	logx.MustSetup(logx.LogConf{
		ServiceName: "asynq-worker",
		Mode:        "file",
		Path:        "/var/log/amazon-pilot",
		Level:       "info",
	})

	// 获取 Redis 地址
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis://localhost:6379"
	}

	// 创建 Asynq 服务器
	srv := asynq.NewServer(
		asynq.RedisClientOpt{Addr: redisAddr},
		asynq.Config{
			Concurrency: 10,
			Queues: map[string]int{
				"critical": 6,
				"default":  3,
				"low":      1,
			},
			StrictPriority: true,
			ErrorHandler: asynq.ErrorHandlerFunc(func(ctx context.Context, task *asynq.Task, err error) {
				logx.Errorf("Task %s failed: %v", task.Type(), err)
			}),
		},
	)

	// 注册任务处理器
	mux := asynq.NewServeMux()

	// 产品更新任务
	mux.HandleFunc("update_product", handleUpdateProduct)

	// 批次更新任务
	mux.HandleFunc("batch_update_products", handleBatchUpdate)

	// 竞品分析任务
	mux.HandleFunc("competitor_analysis", handleCompetitorAnalysis)

	// 优化分析任务
	mux.HandleFunc("optimization_analysis", handleOptimizationAnalysis)

	// 通知发送任务
	mux.HandleFunc("send_notification", handleSendNotification)

	// 启动服务器
	logx.Info("Starting Asynq worker server...")

	// 优雅关闭
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		logx.Info("Shutting down worker server...")
		srv.Shutdown()
	}()

	if err := srv.Run(mux); err != nil {
		log.Fatalf("Could not start server: %v", err)
	}
}

// 任务处理器实现
func handleUpdateProduct(ctx context.Context, t *asynq.Task) error {
	logx.Infof("Processing update product task: %s", t.Payload())

	// TODO: 实现产品更新逻辑
	// 1. 调用 Apify API 获取产品数据
	// 2. 更新数据库
	// 3. 检查变化并发送通知

	return nil
}

func handleBatchUpdate(ctx context.Context, t *asynq.Task) error {
	logx.Infof("Processing batch update task: %s", t.Payload())

	// TODO: 实现批次更新逻辑

	return nil
}

func handleCompetitorAnalysis(ctx context.Context, t *asynq.Task) error {
	logx.Infof("Processing competitor analysis task: %s", t.Payload())

	// TODO: 实现竞品分析逻辑
	// 1. 获取竞品数据
	// 2. 执行比较分析
	// 3. 生成洞察报告

	return nil
}

func handleOptimizationAnalysis(ctx context.Context, t *asynq.Task) error {
	logx.Infof("Processing optimization analysis task: %s", t.Payload())

	// TODO: 实现优化分析逻辑
	// 1. 调用 OpenAI API
	// 2. 生成优化建议

	return nil
}

func handleSendNotification(ctx context.Context, t *asynq.Task) error {
	logx.Infof("Processing send notification task: %s", t.Payload())

	// TODO: 实现通知发送逻辑
	// 1. 发送邮件
	// 2. 发送推送通知

	return nil
}
