package main

import (
	"flag"
	"fmt"
	"log"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/listener"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/queue"

	"github.com/zeromicro/go-zero/core/conf"
)

var configFile = flag.String("f", "cmd/listener/etc/listener.yaml", "the config file")

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
	Listener struct {
		LogLevel string `yaml:"LogLevel"`
	} `yaml:"Listener"`
}

func main() {
	flag.Parse()

	// 初始化结构化日志
	logger.InitStructuredLogger()

	var c Config
	conf.MustLoad(*configFile, &c)

	slog.Info("Starting Amazon Pilot PostgreSQL Listener",
		"config_file", *configFile,
	)

	// 初始化数据库连接 (GORM)
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

	// 构建PostgreSQL连接字符串 (用于pgx LISTEN)
	dbURL := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		c.Database.User,
		c.Database.Password,
		c.Database.Host,
		c.Database.Port,
		c.Database.DBName,
		c.Database.SSLMode,
	)

	// 初始化队列管理器
	queueMgr := queue.NewQueueManager(c.Redis.Addr)

	// 初始化PostgreSQL通知监听器
	pgListener, err := listener.NewPgNotifyListener(dbURL, db, queueMgr)
	if err != nil {
		log.Fatalf("Failed to create PostgreSQL listener: %v", err)
	}

	// 设置信号处理
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 启动监听器
	if err := pgListener.Start(); err != nil {
		log.Fatalf("Failed to start PostgreSQL listener: %v", err)
	}

	slog.Info("PostgreSQL listener started successfully",
		"listening_channels", []string{"price_alerts", "bsr_alerts"},
	)

	// 等待信号
	sig := <-sigChan
	slog.Info("Received signal, shutting down listener",
		"signal", sig.String(),
	)

	// 优雅关闭
	pgListener.Stop()
	slog.Info("PostgreSQL listener shutdown complete")
}