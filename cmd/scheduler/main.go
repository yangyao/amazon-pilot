package main

import (
	"flag"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/queue"
	"amazonpilot/internal/pkg/scheduler"

	"github.com/zeromicro/go-zero/core/conf"
)

var configFile = flag.String("f", "cmd/scheduler/etc/scheduler.yaml", "the config file")

type Config struct {
	Database struct {
		Host     string `yaml:"Host"`
		Port     int    `yaml:"Port"`
		User     string `yaml:"User"`
		Password string `yaml:"Password"`
		DBName   string `yaml:"DBName"`
		SSLMode  string `yaml:"SSLMode"`
	} `yaml:"Database"`
	Redis struct {
		Addr     string `yaml:"Addr"`
		Password string `yaml:"Password"`
		DB       int    `yaml:"DB"`
	} `yaml:"Redis"`
	Scheduler struct {
		CheckInterval string `yaml:"CheckInterval"`
		LogLevel      string `yaml:"LogLevel"`
	} `yaml:"Scheduler"`
}

func main() {
	flag.Parse()

	// 初始化结构化日志
	logger.InitStructuredLogger()

	var c Config
	conf.MustLoad(*configFile, &c)

	slog.Info("Starting Amazon Pilot Scheduler",
		"config_file", *configFile,
		"check_interval", c.Scheduler.CheckInterval,
	)

	// 初始化数据库连接
	db, err := database.NewConnection(database.Config{
		Host:     c.Database.Host,
		Port:     c.Database.Port,
		User:     c.Database.User,
		Password: c.Database.Password,
		DBName:   c.Database.DBName,
		SSLMode:  c.Database.SSLMode,
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 初始化队列管理器
	queueMgr := queue.NewQueueManager(c.Redis.Addr)

	// 初始化调度器服务
	schedulerService := scheduler.NewSchedulerService(db, queueMgr)

	// 设置信号处理
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 启动调度器
	if err := schedulerService.Start(); err != nil {
		log.Fatalf("Failed to start scheduler: %v", err)
	}

	slog.Info("Scheduler started successfully")

	// 等待信号
	sig := <-sigChan
	slog.Info("Received signal, shutting down scheduler",
		"signal", sig.String(),
	)

	// 优雅关闭
	schedulerService.Stop()
	slog.Info("Scheduler shutdown complete")
}

