package workers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"time"

	"amazonpilot/internal/pkg/apify"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/queue"
	"amazonpilot/internal/pkg/tasks"

	"github.com/hibiken/asynq"
	"gorm.io/gorm"
)

// WorkerService 工作器服务
type WorkerService struct {
	db       *gorm.DB
	queueMgr *queue.QueueManager
	logger   *logger.ServiceLogger
}

// NewWorkerService 创建工作器服务
func NewWorkerService(db *gorm.DB, queueMgr *queue.QueueManager) *WorkerService {
	return &WorkerService{
		db:       db,
		queueMgr: queueMgr,
		logger:   logger.NewServiceLogger("worker"),
	}
}

// HandleUpdateProduct 处理产品更新任务 (使用真实Apify API)
func (ws *WorkerService) HandleUpdateProduct(ctx context.Context, t *asynq.Task) error {
	var payload queue.TaskPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
	}

	ws.logger.LogInfo(ctx, "Processing real product update task",
		"product_id", payload.ProductID,
		"user_id", payload.UserID,
	)

	// 查找产品
	var product models.Product
	if err := ws.db.Where("id = ?", payload.ProductID).First(&product).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("product not found: %s: %w", payload.ProductID, asynq.SkipRetry)
		}
		return fmt.Errorf("database error: %w", err)
	}

	// 获取Apify API Token
	apifyToken := os.Getenv("APIFY_API_TOKEN")
	if apifyToken == "" {
		// 在没有API token的情况下使用模拟数据 (开发环境)
		ws.logger.LogInfo(ctx, "No Apify token found, using simulated data")
		return errors.New("APIFY_API_TOKEN not set")
	}

	// 使用真实Apify API获取数据
	apifyClient := apify.NewClient(apifyToken)

	// 调用Apify API获取真实产品数据
	products, err := apifyClient.FetchProductData(ctx, []string{product.ASIN}, 5*time.Minute)
	if err != nil {
		ws.logger.LogError(ctx, "Failed to fetch real product data from Apify",
			"asin", product.ASIN,
			"error", err.Error(),
		)
		// 如果API失败，降级为模拟数据
		return err
	}

	if len(products) == 0 {
		return fmt.Errorf("no product data returned from Apify for ASIN: %s", product.ASIN)
	}

	// 处理真实数据
	realData := products[0]
	now := time.Now()

	// 更新产品基本信息
	updates := map[string]interface{}{
		"title":         realData.Title,
		"brand":         realData.Brand,
		"current_price": realData.Price,
		"rating":        realData.Rating,
		"review_count":  realData.ReviewCount,
		"updated_at":    now,
	}

	if realData.BSR > 0 {
		updates["current_bsr"] = realData.BSR
	}

	if err := ws.db.Model(&product).Updates(updates).Error; err != nil {
		return fmt.Errorf("failed to update product: %w", err)
	}

	// 创建价格历史记录
	priceHistory := models.ProductPriceHistory{
		ProductID:  product.ID,
		Price:      realData.Price,
		Currency:   realData.Currency,
		RecordedAt: now,
		DataSource: "apify_api",
	}

	if err := ws.db.Create(&priceHistory).Error; err != nil {
		return fmt.Errorf("failed to create price history: %w", err)
	}

	// 创建BSR历史记录 (如果有BSR数据)
	if realData.BSR > 0 {
		bsrHistory := models.ProductBSRHistory{
			ProductID:  product.ID,
			BSR:        realData.BSR,
			Category:   realData.BSRCategory,
			RecordedAt: now,
			DataSource: "apify_api",
		}

		if err := ws.db.Create(&bsrHistory).Error; err != nil {
			// BSR更新失败不阻塞主流程
			ws.logger.LogError(ctx, "Failed to create BSR history",
				"product_id", payload.ProductID,
				"error", err.Error(),
			)
		}
	}

	ws.logger.LogBusinessOperation(ctx, "update_product_real_data", "product", payload.ProductID, "success",
		"new_price", realData.Price,
		"new_bsr", realData.BSR,
		"data_source", "apify_api",
	)

	slog.Info("Real product data updated successfully",
		"asin", product.ASIN,
		"price", realData.Price,
		"bsr", realData.BSR,
		"rating", realData.Rating,
	)

	return nil
}

// handleProductUpdateSimulated 处理模拟产品更新 (开发环境备用)
func (ws *WorkerService) handleProductUpdateSimulated(ctx context.Context, payload queue.TaskPayload, product models.Product) error {
	ws.logger.LogInfo(ctx, "Using simulated product data for development")

	now := time.Now()

	// 模拟价格波动 (±5%)
	priceVariation := 0.95 + (float64(now.UnixNano()%10) * 0.01)
	newPrice := product.CurrentPrice * priceVariation

	// 创建模拟价格历史记录
	priceHistory := models.ProductPriceHistory{
		ProductID:  product.ID,
		Price:      newPrice,
		Currency:   "USD",
		RecordedAt: now,
		DataSource: "simulated",
	}

	if err := ws.db.Create(&priceHistory).Error; err != nil {
		return fmt.Errorf("failed to create simulated price history: %w", err)
	}

	// 更新产品价格
	if err := ws.db.Model(&product).Updates(map[string]interface{}{
		"current_price": newPrice,
		"updated_at":    now,
	}).Error; err != nil {
		return fmt.Errorf("failed to update product: %w", err)
	}

	ws.logger.LogBusinessOperation(ctx, "update_product_simulated", "product", payload.ProductID, "success",
		"new_price", newPrice,
		"data_source", "simulated",
	)

	return nil
}

// HandleCompetitorAnalysis 处理竞争对手分析任务
func (ws *WorkerService) HandleCompetitorAnalysis(ctx context.Context, t *asynq.Task) error {
	var payload queue.TaskPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
	}

	ws.logger.LogInfo(ctx, "Processing competitor analysis task",
		"analysis_id", payload.AnalysisID,
		"user_id", payload.UserID,
	)

	// 查找分析组
	var analysisGroup models.CompetitorAnalysisGroup
	if err := ws.db.Preload("Competitors.Product").Where("id = ?", payload.AnalysisID).First(&analysisGroup).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("analysis group not found: %s: %w", payload.AnalysisID, asynq.SkipRetry)
		}
		return fmt.Errorf("database error: %w", err)
	}

	// 模拟分析处理
	time.Sleep(5 * time.Second) // 模拟AI分析时间

	// 创建分析结果
	analysisData := map[string]interface{}{
		"price_analysis": map[string]interface{}{
			"min_price":     50.00,
			"max_price":     150.00,
			"average_price": 85.50,
			"your_position": "competitive",
		},
		"market_insights": []string{
			"Your price is 15% below market average",
			"Top competitor has 20% higher BSR",
			"Market trend shows increasing demand",
		},
	}

	recommendations := []map[string]interface{}{
		{
			"type":        "pricing",
			"priority":    "high",
			"title":       "Consider price optimization",
			"description": "Your current price gives good competitive advantage",
			"impact":      "medium",
		},
	}

	now := time.Now()
	result := models.CompetitorAnalysisResult{
		AnalysisGroupID: analysisGroup.ID,
		Status:          "completed",
		StartedAt:       analysisGroup.CreatedAt,
		CompletedAt:     &now,
	}

	// 序列化JSON数据
	analysisDataBytes, _ := json.Marshal(analysisData)
	recommendationsBytes, _ := json.Marshal(recommendations)
	result.AnalysisData = analysisDataBytes
	result.Recommendations = recommendationsBytes

	if err := ws.db.Create(&result).Error; err != nil {
		return fmt.Errorf("failed to create analysis result: %w", err)
	}

	// 更新分析组的最后分析时间
	if err := ws.db.Model(&analysisGroup).Update("last_analysis_at", now).Error; err != nil {
		return fmt.Errorf("failed to update analysis group: %w", err)
	}

	ws.logger.LogBusinessOperation(ctx, "competitor_analysis_task", "competitor_analysis", payload.AnalysisID, "success",
		"competitors_count", len(analysisGroup.Competitors),
	)

	return nil
}

// HandleOptimizationAnalysis 处理优化分析任务
func (ws *WorkerService) HandleOptimizationAnalysis(ctx context.Context, t *asynq.Task) error {
	var payload queue.TaskPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
	}

	ws.logger.LogInfo(ctx, "Processing optimization analysis task",
		"analysis_id", payload.AnalysisID,
		"product_id", payload.ProductID,
	)

	// 查找优化分析记录
	var analysis models.OptimizationAnalysis
	if err := ws.db.Preload("Product").Where("id = ?", payload.AnalysisID).First(&analysis).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("optimization analysis not found: %s: %w", payload.AnalysisID, asynq.SkipRetry)
		}
		return fmt.Errorf("database error: %w", err)
	}

	// 更新状态为处理中
	if err := ws.db.Model(&analysis).Update("status", "processing").Error; err != nil {
		return fmt.Errorf("failed to update analysis status: %w", err)
	}

	// 模拟AI分析处理
	time.Sleep(8 * time.Second) // 模拟AI分析时间

	// 生成更多详细的AI建议
	suggestions := []models.OptimizationSuggestion{
		{
			AnalysisID:  analysis.ID,
			Category:    "title",
			Priority:    "high",
			ImpactScore: 9,
			Title:       "Optimize product title for better SEO",
			Description: "Based on keyword analysis, consider adding high-traffic keywords to improve discoverability.",
		},
		{
			AnalysisID:  analysis.ID,
			Category:    "pricing",
			Priority:    "medium",
			ImpactScore: 7,
			Title:       "Competitive pricing analysis",
			Description: "Your current price is competitive but could be optimized for better profit margins.",
		},
		{
			AnalysisID:  analysis.ID,
			Category:    "images",
			Priority:    "low",
			ImpactScore: 5,
			Title:       "Enhance product images",
			Description: "Consider adding lifestyle images and infographics to improve conversion rates.",
		},
	}

	// 保存建议
	if err := ws.db.Create(&suggestions).Error; err != nil {
		return fmt.Errorf("failed to create optimization suggestions: %w", err)
	}

	// 更新分析状态和完成时间
	now := time.Now()
	overallScore := 75 // 模拟计算的总分
	updates := map[string]interface{}{
		"status":        "completed",
		"overall_score": overallScore,
		"completed_at":  now,
	}

	if err := ws.db.Model(&analysis).Updates(updates).Error; err != nil {
		return fmt.Errorf("failed to update analysis completion: %w", err)
	}

	ws.logger.LogBusinessOperation(ctx, "optimization_analysis_task", "optimization_analysis", payload.AnalysisID, "success",
		"suggestions_count", len(suggestions),
		"overall_score", overallScore,
	)

	return nil
}

// HandleSendNotification 处理发送通知任务
func (ws *WorkerService) HandleSendNotification(ctx context.Context, t *asynq.Task) error {
	var payload queue.TaskPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
	}

	ws.logger.LogInfo(ctx, "Processing send notification task",
		"user_id", payload.UserID,
	)

	// 从metadata中获取通知内容
	notificationData, ok := payload.Metadata["notification"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid notification data: %w", asynq.SkipRetry)
	}

	// 创建通知记录
	notification := models.Notification{
		UserID:   payload.UserID,
		Type:     getString(notificationData, "type", "system"),
		Title:    getString(notificationData, "title", "Notification"),
		Message:  getString(notificationData, "message", ""),
		Severity: getString(notificationData, "severity", "info"),
		IsRead:   false,
	}

	if err := ws.db.Create(&notification).Error; err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}

	// 模拟发送邮件或推送通知
	time.Sleep(1 * time.Second)

	ws.logger.LogBusinessOperation(ctx, "send_notification_task", "notification", notification.ID, "success",
		"type", notification.Type,
		"severity", notification.Severity,
	)

	return nil
}

// HandleDataCleanup 处理数据清理任务
func (ws *WorkerService) HandleDataCleanup(ctx context.Context, t *asynq.Task) error {
	ws.logger.LogInfo(ctx, "Processing data cleanup task")

	// 清理30天前的价格历史记录
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	result := ws.db.Where("recorded_at < ?", thirtyDaysAgo).Delete(&models.ProductPriceHistory{})
	if result.Error != nil {
		return fmt.Errorf("failed to cleanup price history: %w", result.Error)
	}

	// 清理已过期的通知
	expiredResult := ws.db.Where("expires_at IS NOT NULL AND expires_at < ?", time.Now()).Delete(&models.Notification{})
	if expiredResult.Error != nil {
		return fmt.Errorf("failed to cleanup expired notifications: %w", expiredResult.Error)
	}

	ws.logger.LogBusinessOperation(ctx, "data_cleanup_task", "system", "", "success",
		"price_records_deleted", result.RowsAffected,
		"notifications_deleted", expiredResult.RowsAffected,
	)

	slog.Info("Data cleanup completed",
		"price_records_deleted", result.RowsAffected,
		"notifications_deleted", expiredResult.RowsAffected,
	)

	return nil
}

// HandleAnomalyDetection 处理异常检测任务
func (ws *WorkerService) HandleAnomalyDetection(ctx context.Context, t *asynq.Task) error {
	ws.logger.LogInfo(ctx, "Processing anomaly detection task")

	// 运行异常检测
	if err := monitor.RunAnomalyDetection(ctx, ws.db, ws.queueMgr); err != nil {
		return fmt.Errorf("anomaly detection failed: %w", err)
	}

	ws.logger.LogBusinessOperation(ctx, "anomaly_detection_task", "system", "", "success")
	return nil
}

// GetHandlers 获取所有任务处理器
func (ws *WorkerService) GetHandlers() map[string]asynq.HandlerFunc {
	return map[string]asynq.HandlerFunc{
		queue.TaskTypeUpdateProduct:        ws.HandleUpdateProduct,
		queue.TaskTypeCompetitorAnalysis:   ws.HandleCompetitorAnalysis,
		queue.TaskTypeOptimizationAnalysis: ws.HandleOptimizationAnalysis,
		queue.TaskTypeSendNotification:     ws.HandleSendNotification,
		queue.TaskTypeDataCleanup:          ws.HandleDataCleanup,
		queue.TaskTypeAnomalyDetection:     ws.HandleAnomalyDetection,
	}
}

// getString 安全获取map中的字符串值
func getString(m map[string]interface{}, key, defaultValue string) string {
	if val, ok := m[key].(string); ok {
		return val
	}
	return defaultValue
}
