package main

import (
	"log"
	"log/slog"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/tasks"

	"github.com/hibiken/asynq"
	"github.com/joho/godotenv"
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

	apifyAPIToken := os.Getenv("APIFY_API_TOKEN")
	if apifyAPIToken == "" {
		log.Fatal("APIFY_API_TOKEN environment variable is required")
	}

	concurrencyStr := os.Getenv("WORKER_CONCURRENCY")
	if concurrencyStr == "" {
		log.Fatal("WORKER_CONCURRENCY environment variable is required")
	}
	concurrency, err := strconv.Atoi(concurrencyStr)
	if err != nil {
		log.Fatal("Invalid WORKER_CONCURRENCY value: " + err.Error())
	}

	slog.Info("Amazon Pilot Worker starting",
		"redis_host", redisHost,
		"redis_port", redisPort,
		"redis_db", redisDB,
		"concurrency", concurrency,
	)

	// Redis连接配置 (从环境变量读取)
	redisAddr := redisHost + ":" + redisPort
	redisOpt := asynq.RedisClientOpt{
		Addr: redisAddr,
		DB:   redisDB,
	}

	// 创建任务服务器 (使用环境变量配置)
	srv := asynq.NewServer(redisOpt, asynq.Config{
		Concurrency: concurrency,
		Queues: map[string]int{
			"critical": 6,  // 异常检测、紧急通知
			"default":  3,  // 一般数据刷新
			"apify":    2,  // Apify数据获取
			"cleanup":  1,  // 数据清理
		},
	})

	// 创建任务处理器 (使用环境变量配置)
	processor := tasks.NewApifyTaskProcessor(
		databaseDSN,
		apifyAPIToken,
		redisAddr,
	)

	// 注册任务处理函数
	mux := asynq.NewServeMux()
	mux.HandleFunc(tasks.TypeRefreshProductData, processor.HandleRefreshProductData)

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