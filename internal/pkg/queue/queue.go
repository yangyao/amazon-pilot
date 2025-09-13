package queue

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"github.com/hibiken/asynq"
)

// QueueManager 任务队列管理器
type QueueManager struct {
	client    *asynq.Client
	server    *asynq.Server
	scheduler *asynq.Scheduler
	redisAddr string
}

// TaskPayload 通用任务载荷
type TaskPayload struct {
	ProductID    string                 `json:"product_id,omitempty"`
	UserID       string                 `json:"user_id,omitempty"`
	AnalysisID   string                 `json:"analysis_id,omitempty"`
	TaskType     string                 `json:"task_type"`
	Priority     int                    `json:"priority"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt    time.Time              `json:"created_at"`
}

// 任务类型常量
const (
	TaskTypeUpdateProduct        = "update_product"
	TaskTypeCompetitorAnalysis   = "competitor_analysis"
	TaskTypeOptimizationAnalysis = "optimization_analysis"
	TaskTypeSendNotification     = "send_notification"
	TaskTypeDataCleanup          = "data_cleanup"
	TaskTypeAnomalyDetection     = "anomaly_detection"
)

// 队列名称常量
const (
	QueueCritical = "critical"
	QueueDefault  = "default"
	QueueLow      = "low"
)

// NewQueueManager 创建队列管理器
func NewQueueManager(redisAddr string) *QueueManager {
	// 创建 Asynq 客户端
	client := asynq.NewClient(asynq.RedisClientOpt{Addr: redisAddr})
	
	// 创建 Asynq 服务器
	server := asynq.NewServer(
		asynq.RedisClientOpt{Addr: redisAddr},
		asynq.Config{
			Concurrency: 10,
			Queues: map[string]int{
				QueueCritical: 6,
				QueueDefault:  3,
				QueueLow:      1,
			},
			StrictPriority: true,
			ErrorHandler: asynq.ErrorHandlerFunc(func(ctx context.Context, task *asynq.Task, err error) {
				slog.Error("Task processing failed", 
					"task_type", task.Type(),
					"error", err.Error(),
				)
			}),
		},
	)
	
	// 创建调度器
	scheduler := asynq.NewScheduler(asynq.RedisClientOpt{Addr: redisAddr}, nil)
	
	qm := &QueueManager{
		client:    client,
		server:    server,
		scheduler: scheduler,
		redisAddr: redisAddr,
	}
	
	return qm
}

// EnqueueTask 入队任务
func (qm *QueueManager) EnqueueTask(taskType string, payload TaskPayload, opts ...asynq.Option) error {
	payload.TaskType = taskType
	payload.CreatedAt = time.Now()
	
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal task payload: %w", err)
	}
	
	task := asynq.NewTask(taskType, payloadBytes)
	
	// 根据优先级选择队列
	queue := QueueDefault
	if payload.Priority >= 8 {
		queue = QueueCritical
	} else if payload.Priority <= 3 {
		queue = QueueLow
	}
	
	// 添加队列选项
	opts = append(opts, asynq.Queue(queue))
	
	_, err = qm.client.Enqueue(task, opts...)
	if err != nil {
		return fmt.Errorf("failed to enqueue task: %w", err)
	}
	
	slog.Info("Task enqueued successfully",
		"task_type", taskType,
		"queue", queue,
		"priority", payload.Priority,
	)
	
	return nil
}

// EnqueueProductUpdate 入队产品更新任务
func (qm *QueueManager) EnqueueProductUpdate(productID, userID string, priority int) error {
	payload := TaskPayload{
		ProductID: productID,
		UserID:    userID,
		Priority:  priority,
	}
	
	return qm.EnqueueTask(TaskTypeUpdateProduct, payload)
}

// EnqueueCompetitorAnalysis 入队竞争对手分析任务
func (qm *QueueManager) EnqueueCompetitorAnalysis(analysisID, userID string, priority int) error {
	payload := TaskPayload{
		AnalysisID: analysisID,
		UserID:     userID,
		Priority:   priority,
	}
	
	return qm.EnqueueTask(TaskTypeCompetitorAnalysis, payload)
}

// EnqueueOptimizationAnalysis 入队优化分析任务
func (qm *QueueManager) EnqueueOptimizationAnalysis(analysisID, productID, userID string, priority int) error {
	payload := TaskPayload{
		AnalysisID: analysisID,
		ProductID:  productID,
		UserID:     userID,
		Priority:   priority,
	}
	
	return qm.EnqueueTask(TaskTypeOptimizationAnalysis, payload)
}

// EnqueueNotification 入队通知任务
func (qm *QueueManager) EnqueueNotification(userID string, notificationData map[string]interface{}, priority int) error {
	payload := TaskPayload{
		UserID:   userID,
		Priority: priority,
		Metadata: notificationData,
	}
	
	return qm.EnqueueTask(TaskTypeSendNotification, payload)
}

// EnqueueAnomalyDetection 入队异常检测任务
func (qm *QueueManager) EnqueueAnomalyDetection(priority int) error {
	payload := TaskPayload{
		Priority: priority,
		Metadata: map[string]interface{}{
			"detection_type": "full_scan",
		},
	}
	
	return qm.EnqueueTask(TaskTypeAnomalyDetection, payload)
}

// SchedulePeriodicTask 调度周期性任务
func (qm *QueueManager) SchedulePeriodicTask(cronExpr, taskType string, payload TaskPayload) error {
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal task payload: %w", err)
	}
	
	task := asynq.NewTask(taskType, payloadBytes)
	
	_, err = qm.scheduler.Register(cronExpr, task)
	if err != nil {
		return fmt.Errorf("failed to schedule periodic task: %w", err)
	}
	
	slog.Info("Periodic task scheduled",
		"task_type", taskType,
		"cron", cronExpr,
	)
	
	return nil
}

// Start 启动队列管理器
func (qm *QueueManager) Start() error {
	// 启动调度器
	if err := qm.scheduler.Start(); err != nil {
		return fmt.Errorf("failed to start scheduler: %w", err)
	}
	
	slog.Info("Queue manager started",
		"redis_addr", qm.redisAddr,
		"concurrency", 10,
	)
	
	return nil
}

// StartServer 启动服务器（Worker模式）
func (qm *QueueManager) StartServer(handlers map[string]asynq.HandlerFunc) error {
	// 注册任务处理器
	mux := asynq.NewServeMux()
	for taskType, handler := range handlers {
		mux.HandleFunc(taskType, handler)
	}
	
	// 启动调度器
	if err := qm.scheduler.Start(); err != nil {
		return fmt.Errorf("failed to start scheduler: %w", err)
	}
	
	slog.Info("Starting worker server",
		"redis_addr", qm.redisAddr,
		"handlers_count", len(handlers),
	)
	
	// 阻塞运行服务器
	return qm.server.Run(mux)
}

// Stop 停止队列管理器
func (qm *QueueManager) Stop() {
	if qm.client != nil {
		qm.client.Close()
	}
	if qm.server != nil {
		qm.server.Stop()
	}
	if qm.scheduler != nil {
		qm.scheduler.Shutdown()
	}
	
	slog.Info("Queue manager stopped")
}