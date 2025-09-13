package scheduler

import (
	"context"
	"log/slog"
	"time"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/queue"

	"gorm.io/gorm"
)

// SchedulerService 调度器服务
type SchedulerService struct {
	db          *gorm.DB
	queueMgr    *queue.QueueManager
	logger      *logger.ServiceLogger
	ctx         context.Context
	cancelFunc  context.CancelFunc
}

// NewSchedulerService 创建调度器服务
func NewSchedulerService(db *gorm.DB, queueMgr *queue.QueueManager) *SchedulerService {
	ctx, cancel := context.WithCancel(context.Background())
	
	return &SchedulerService{
		db:         db,
		queueMgr:   queueMgr,
		logger:     logger.NewServiceLogger("scheduler"),
		ctx:        ctx,
		cancelFunc: cancel,
	}
}

// Start 启动调度器
func (ss *SchedulerService) Start() error {
	slog.Info("Starting scheduler service")

	// 设置周期性任务
	if err := ss.setupPeriodicTasks(); err != nil {
		return err
	}

	// 启动调度器
	if err := ss.queueMgr.Start(); err != nil {
		return err
	}

	// 启动后台任务调度
	go ss.runPeriodicScheduler()

	slog.Info("Scheduler service started successfully")
	return nil
}

// setupPeriodicTasks 设置周期性任务
func (ss *SchedulerService) setupPeriodicTasks() error {
	// 每小时更新活跃产品价格
	hourlyProductUpdate := queue.TaskPayload{
		TaskType:  queue.TaskTypeUpdateProduct,
		Priority:  5,
		Metadata: map[string]interface{}{
			"batch_update": true,
			"frequency":   "hourly",
		},
	}
	
	if err := ss.queueMgr.SchedulePeriodicTask("0 * * * *", queue.TaskTypeUpdateProduct, hourlyProductUpdate); err != nil {
		return err
	}

	// 每天凌晨2点执行数据清理
	dailyCleanup := queue.TaskPayload{
		TaskType: queue.TaskTypeDataCleanup,
		Priority: 2,
		Metadata: map[string]interface{}{
			"cleanup_type": "daily",
		},
	}
	
	if err := ss.queueMgr.SchedulePeriodicTask("0 2 * * *", queue.TaskTypeDataCleanup, dailyCleanup); err != nil {
		return err
	}

	// 每2小时执行异常检测 (价格变动>10%, BSR变动>30%)
	anomalyDetection := queue.TaskPayload{
		TaskType: queue.TaskTypeAnomalyDetection,
		Priority: 8, // 高优先级，因为是重要的监控功能
		Metadata: map[string]interface{}{
			"detection_type": "full_scan",
			"price_threshold": 10.0,
			"bsr_threshold": 30.0,
		},
	}
	
	if err := ss.queueMgr.SchedulePeriodicTask("0 */2 * * *", queue.TaskTypeAnomalyDetection, anomalyDetection); err != nil {
		return err
	}

	// 每天早上8点触发竞争对手分析 (对设置为daily的分析组)
	dailyCompetitorAnalysis := queue.TaskPayload{
		TaskType: queue.TaskTypeCompetitorAnalysis,
		Priority: 6,
		Metadata: map[string]interface{}{
			"frequency": "daily",
			"auto_trigger": true,
		},
	}
	
	if err := ss.queueMgr.SchedulePeriodicTask("0 8 * * *", queue.TaskTypeCompetitorAnalysis, dailyCompetitorAnalysis); err != nil {
		return err
	}

	slog.Info("Periodic tasks scheduled successfully")
	return nil
}

// runPeriodicScheduler 运行周期性调度器
func (ss *SchedulerService) runPeriodicScheduler() {
	ticker := time.NewTicker(10 * time.Minute) // 每10分钟检查一次
	defer ticker.Stop()

	for {
		select {
		case <-ss.ctx.Done():
			slog.Info("Scheduler stopped")
			return
		case <-ticker.C:
			ss.checkAndScheduleTasks()
		}
	}
}

// checkAndScheduleTasks 检查并调度任务
func (ss *SchedulerService) checkAndScheduleTasks() {
	// 检查需要更新的产品
	ss.scheduleProductUpdates()
	
	// 检查需要分析的竞争对手组
	ss.scheduleCompetitorAnalyses()
	
	// 检查需要处理的优化分析
	ss.scheduleOptimizationAnalyses()
}

// scheduleProductUpdates 调度产品更新任务
func (ss *SchedulerService) scheduleProductUpdates() {
	// 查找需要更新的产品 (超过2小时未更新的活跃产品)
	var products []models.Product
	twoHoursAgo := time.Now().Add(-2 * time.Hour)
	
	err := ss.db.Where("is_tracked = ? AND updated_at < ?", true, twoHoursAgo).
		Limit(50). // 批量处理，避免过载
		Find(&products).Error
	
	if err != nil {
		ss.logger.LogError(ss.ctx, "Failed to query products for update", "error", err.Error())
		return
	}

	for _, product := range products {
		if err := ss.queueMgr.EnqueueProductUpdate(product.ID, product.UserID, 5); err != nil {
			ss.logger.LogError(ss.ctx, "Failed to enqueue product update",
				"product_id", product.ID,
				"error", err.Error(),
			)
		}
	}

	if len(products) > 0 {
		slog.Info("Scheduled product updates", "count", len(products))
	}
}

// scheduleCompetitorAnalyses 调度竞争对手分析任务
func (ss *SchedulerService) scheduleCompetitorAnalyses() {
	// 查找需要分析的竞争对手组 (daily frequency且超过20小时未分析)
	var analysisGroups []models.CompetitorAnalysisGroup
	twentyHoursAgo := time.Now().Add(-20 * time.Hour)
	
	err := ss.db.Where("is_active = ? AND update_frequency = ? AND (last_analysis_at IS NULL OR last_analysis_at < ?)", 
		true, "daily", twentyHoursAgo).
		Limit(20).
		Find(&analysisGroups).Error
	
	if err != nil {
		ss.logger.LogError(ss.ctx, "Failed to query analysis groups", "error", err.Error())
		return
	}

	for _, group := range analysisGroups {
		if err := ss.queueMgr.EnqueueCompetitorAnalysis(group.ID, group.UserID, 6); err != nil {
			ss.logger.LogError(ss.ctx, "Failed to enqueue competitor analysis",
				"analysis_id", group.ID,
				"error", err.Error(),
			)
		}
	}

	if len(analysisGroups) > 0 {
		slog.Info("Scheduled competitor analyses", "count", len(analysisGroups))
	}
}

// scheduleOptimizationAnalyses 调度优化分析任务
func (ss *SchedulerService) scheduleOptimizationAnalyses() {
	// 查找pending状态的优化分析 (创建超过5分钟但未开始处理)
	var analyses []models.OptimizationAnalysis
	fiveMinutesAgo := time.Now().Add(-5 * time.Minute)
	
	err := ss.db.Where("status = ? AND started_at < ?", "pending", fiveMinutesAgo).
		Limit(10).
		Find(&analyses).Error
	
	if err != nil {
		ss.logger.LogError(ss.ctx, "Failed to query optimization analyses", "error", err.Error())
		return
	}

	for _, analysis := range analyses {
		if err := ss.queueMgr.EnqueueOptimizationAnalysis(analysis.ID, analysis.ProductID, analysis.UserID, 7); err != nil {
			ss.logger.LogError(ss.ctx, "Failed to enqueue optimization analysis",
				"analysis_id", analysis.ID,
				"error", err.Error(),
			)
		}
	}

	if len(analyses) > 0 {
		slog.Info("Scheduled optimization analyses", "count", len(analyses))
	}
}

// Stop 停止调度器
func (ss *SchedulerService) Stop() {
	ss.cancelFunc()
	slog.Info("Scheduler service stopped")
}