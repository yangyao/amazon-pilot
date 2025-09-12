package main

import (
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
		ServiceName: "asynq-scheduler",
		Mode:        "file",
		Path:        "/var/log/amazon-pilot",
		Level:       "info",
	})

	// 获取 Redis 地址
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis://localhost:6379"
	}

	// 创建调度器
	scheduler := asynq.NewScheduler(
		asynq.RedisClientOpt{Addr: redisAddr},
		nil,
	)

	// 注册定时任务
	registerPeriodicTasks(scheduler)

	// 启动调度器
	logx.Info("Starting Asynq scheduler...")

	// 优雅关闭
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		logx.Info("Shutting down scheduler...")
		scheduler.Shutdown()
	}()

	if err := scheduler.Run(); err != nil {
		log.Fatalf("Could not start scheduler: %v", err)
	}
}

func registerPeriodicTasks(scheduler *asynq.Scheduler) {
	// 每日上午 9 点执行产品更新
	_, err := scheduler.Register("@daily 09:00", asynq.NewTask("schedule_daily_updates", nil))
	if err != nil {
		logx.Errorf("Failed to register daily update task: %v", err)
	}

	// 每 6 小时执行高频率产品更新
	_, err = scheduler.Register("0 */6 * * *", asynq.NewTask("schedule_high_frequency_updates", nil))
	if err != nil {
		logx.Errorf("Failed to register high frequency update task: %v", err)
	}

	// 每小時執行高頻產品更新
	_, err = scheduler.Register("@hourly", asynq.NewTask("schedule_hourly_updates", nil))
	if err != nil {
		logx.Errorf("Failed to register hourly update task: %v", err)
	}

	// 週日凌晨 2 點執行競品分析
	_, err = scheduler.Register("0 2 * * 0", asynq.NewTask("schedule_weekly_analysis", nil))
	if err != nil {
		logx.Errorf("Failed to register weekly analysis task: %v", err)
	}

	// 每日凌晨 3 點執行資料清理
	_, err = scheduler.Register("0 3 * * *", asynq.NewTask("schedule_daily_cleanup", nil))
	if err != nil {
		logx.Errorf("Failed to register daily cleanup task: %v", err)
	}

	// 每週日凌晨 1 點執行優化分析
	_, err = scheduler.Register("0 1 * * 0", asynq.NewTask("schedule_weekly_optimization", nil))
	if err != nil {
		logx.Errorf("Failed to register weekly optimization task: %v", err)
	}

	logx.Info("All periodic tasks registered successfully")
}
