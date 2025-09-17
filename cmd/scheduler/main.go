package main

import (
	"encoding/json"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	baseconfig "amazonpilot/internal/pkg/config"
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"

	"github.com/hibiken/asynq"
	"github.com/robfig/cron/v3"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	serviceName := constants.ServiceScheduler

	// 初始化结构化日志
	logger.InitStructuredLogger(serviceName)

	// 加载环境变量配置
	envCfg := baseconfig.MustLoadEnvConfig(serviceName)

	slog.Info("Amazon Pilot Scheduler starting",
		"redis", envCfg.Redis.Addr,
		"update_interval", envCfg.Scheduler.ProductUpdateInterval,
	)

	// 连接数据库
	db, err := gorm.Open(postgres.Open(envCfg.Database.DSN), &gorm.Config{})
	if err != nil {
		slog.Error("Failed to connect to database", "error", err)
		panic(err)
	}

	// 初始化Redis客户端
	asynqClient := asynq.NewClient(asynq.RedisClientOpt{
		Addr: envCfg.Redis.Addr,
		DB:   envCfg.Redis.DB,
	})

	// 创建cron调度器
	cronScheduler := cron.New(cron.WithSeconds())

	// 添加产品更新任务 - 根据环境变量配置的间隔执行
	_, err = cronScheduler.AddFunc("@every "+envCfg.Scheduler.ProductUpdateInterval, func() {
		scheduleProductUpdates(db, asynqClient)
	})
	if err != nil {
		slog.Error("Failed to add cron job", "error", err)
		panic(err)
	}

	// 启动调度器
	cronScheduler.Start()
	slog.Info("Scheduler started", "interval", envCfg.Scheduler.ProductUpdateInterval)

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGTERM, syscall.SIGINT)
	sig := <-quit

	slog.Info("Scheduler shutdown initiated", "signal", sig.String())
	cronScheduler.Stop()
	slog.Info("Scheduler shutdown complete")
}

// scheduleProductUpdates 调度所有活跃产品的更新任务
func scheduleProductUpdates(db *gorm.DB, client *asynq.Client) {

	// 查询所有活跃的追踪产品
	var trackedProducts []models.TrackedProduct
	if err := db.Where("is_active = ?", true).Preload("Product").Find(&trackedProducts).Error; err != nil {
		slog.Error("Failed to fetch tracked products", "error", err)
		return
	}

	slog.Info("Scheduling product updates", "products_count", len(trackedProducts))

	// 为每个产品创建更新任务
	successCount := 0
	for _, tp := range trackedProducts {
		// 创建任务payload
		taskPayload := map[string]interface{}{
			"product_id":   tp.ProductID,
			"tracked_id":   tp.ID,
			"asin":         tp.Product.ASIN,
			"user_id":      tp.UserID,
			"scheduled_at": time.Now().Format(time.RFC3339),
		}

		payloadBytes, err := json.Marshal(taskPayload)
		if err != nil {
			slog.Error("Failed to marshal task payload", "product_id", tp.ProductID, "error", err)
			continue
		}

		// 创建任务并加入队列
		task := asynq.NewTask("refresh:product:data", payloadBytes)
		info, err := client.Enqueue(task, asynq.Queue("apify"))
		if err != nil {
			slog.Error("Failed to enqueue refresh task", "product_id", tp.ProductID, "asin", tp.Product.ASIN, "error", err)
			continue
		}

		successCount++
		slog.Info("Product update task scheduled", "asin", tp.Product.ASIN, "task_id", info.ID)
	}

	slog.Info("Product update scheduling completed",
		"total_products", len(trackedProducts),
		"successful_tasks", successCount,
	)
}