package main

import (
	"encoding/json"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"

	"github.com/hibiken/asynq"
	"github.com/joho/godotenv"
	"github.com/robfig/cron/v3"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 加载.env文件
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// 初始化结构化日志
	logger.InitStructuredLogger()

	// 从环境变量读取配置
	databaseDSN := os.Getenv("DATABASE_DSN")
	if databaseDSN == "" {
		log.Fatal("DATABASE_DSN environment variable is required")
	}

	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		log.Fatal("REDIS_HOST environment variable is required")
	}

	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		log.Fatal("REDIS_PORT environment variable is required")
	}

	redisDBStr := os.Getenv("REDIS_DB")
	if redisDBStr == "" {
		log.Fatal("REDIS_DB environment variable is required")
	}
	redisDB, err := strconv.Atoi(redisDBStr)
	if err != nil {
		log.Fatal("Invalid REDIS_DB value: " + err.Error())
	}

	productUpdateInterval := os.Getenv("SCHEDULER_PRODUCT_UPDATE_INTERVAL")
	if productUpdateInterval == "" {
		log.Fatal("SCHEDULER_PRODUCT_UPDATE_INTERVAL environment variable is required")
	}

	slog.Info("Amazon Pilot Scheduler starting",
		"redis_host", redisHost,
		"redis_port", redisPort,
		"update_interval", productUpdateInterval,
	)

	// 连接数据库
	db, err := gorm.Open(postgres.Open(databaseDSN), &gorm.Config{})
	if err != nil {
		slog.Error("Failed to connect to database", "error", err)
		os.Exit(1)
	}

	// 初始化Redis客户端
	redisAddr := redisHost + ":" + redisPort
	asynqClient := asynq.NewClient(asynq.RedisClientOpt{
		Addr: redisAddr,
		DB:   redisDB,
	})
	defer asynqClient.Close()

	// 创建cron调度器
	cronScheduler := cron.New(cron.WithSeconds())

	// 添加产品更新任务 - 每1分钟执行一次
	_, err = cronScheduler.AddFunc("@every "+productUpdateInterval, func() {
		scheduleProductUpdates(db, asynqClient)
	})
	if err != nil {
		slog.Error("Failed to add cron job", "error", err)
		os.Exit(1)
	}

	// 启动调度器
	cronScheduler.Start()
	slog.Info("Scheduler started", "interval", productUpdateInterval)

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
		slog.Error("Failed to query tracked products", "error", err)
		return
	}

	slog.Info("Scheduling product updates", "products_count", len(trackedProducts))

	// 为每个产品创建更新任务
	successCount := 0
	for _, tp := range trackedProducts {
		// 创建任务payload
		taskPayload := map[string]interface{}{
			"product_id":    tp.ProductID,
			"tracked_id":    tp.ID,
			"asin":          tp.Product.ASIN,
			"user_id":       tp.UserID,
			"scheduled_at":  time.Now().Format(time.RFC3339),
		}

		payloadBytes, err := json.Marshal(taskPayload)
		if err != nil {
			slog.Error("Failed to marshal task payload", "product_id", tp.ProductID, "error", err)
			continue
		}

		// 发送任务到Redis队列
		task := asynq.NewTask("refresh_product_data", payloadBytes)
		info, err := client.Enqueue(task)
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
