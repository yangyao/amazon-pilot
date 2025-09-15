package main

import (
	"log"
	"net/http"
	"os"

	"amazonpilot/internal/pkg/logger"

	"github.com/hibiken/asynq"
	"github.com/hibiken/asynqmon"
	"github.com/joho/godotenv"
)

func main() {
	// 加载.env文件
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// 初始化结构化日志
	logger.InitStructuredLogger()

	// 从环境变量读取Redis配置
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		log.Fatal("REDIS_HOST environment variable is required")
	}

	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		log.Fatal("REDIS_PORT environment variable is required")
	}

	// Redis不使用密码

	dashboardPort := os.Getenv("DASHBOARD_PORT")
	if dashboardPort == "" {
		dashboardPort = "5555" // 默认端口
	}

	// 构建Redis连接配置
	redisAddr := redisHost + ":" + redisPort

	log.Printf("🚀 Starting Asynq Dashboard...")
	log.Printf("📡 Redis: %s", redisAddr)
	log.Printf("🌐 Dashboard: http://0.0.0.0:%s", dashboardPort)

	// 创建Redis连接选项（无密码）
	redisConnOpt := asynq.RedisClientOpt{
		Addr: redisAddr,
	}

	// 启动Asynq Dashboard
	h := asynqmon.New(asynqmon.Options{
		RootPath:     "/",
		RedisConnOpt: redisConnOpt,
	})

	// 启动HTTP服务器
	log.Printf("Dashboard server starting on port %s", dashboardPort)
	log.Fatal(http.ListenAndServe(":"+dashboardPort, h))
}