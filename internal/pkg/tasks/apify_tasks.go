package tasks

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"strings"
	"time"

	"amazonpilot/internal/pkg/apify"
	"amazonpilot/internal/pkg/cache"
	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/llm"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"

	"github.com/hibiken/asynq"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

const (
	TypeRefreshProductData = "refresh_product_data"
	TypeGenerateReport     = "generate_competitor_report"
)

type RefreshProductDataPayload struct {
	ProductID   string `json:"product_id"`
	TrackedID   string `json:"tracked_id"`
	ASIN        string `json:"asin"`
	UserID      string `json:"user_id"`
	RequestedAt string `json:"requested_at"`
}

type GenerateReportPayload struct {
	AnalysisID  string `json:"analysis_id"`
	UserID      string `json:"user_id"`
	TaskID      string `json:"task_id"`
	Force       bool   `json:"force"`
	RequestedAt string `json:"requested_at"`
}

type ApifyTaskProcessor struct {
	db          *gorm.DB
	redisClient *redis.Client
	apifyClient *apify.Client
	asynqClient *asynq.Client
	logger      *logger.ServiceLogger
}

func NewApifyTaskProcessor(dsn string, apifyToken string, redisAddr string) *ApifyTaskProcessor {
	// 连接数据库
	db, err := database.NewConnectionWithDSN(dsn, &database.Config{
		MaxIdleConns:    10,
		MaxOpenConns:    100,
		ConnMaxLifetime: 3600,
	})
	if err != nil {
		panic("Failed to connect to database: " + err.Error())
	}

	// 初始化Apify客户端
	apifyClient := apify.NewClient(apifyToken)

	// 初始化Asynq客户端 (用于发送异常检测消息)
	redisOpt := asynq.RedisClientOpt{
		Addr: redisAddr,
		DB:   0,
	}
	asynqClient := asynq.NewClient(redisOpt)

	serviceLogger := logger.NewServiceLogger("apify-worker")

	return &ApifyTaskProcessor{
		db:          db,
		apifyClient: apifyClient,
		asynqClient: asynqClient,
		logger:      serviceLogger,
	}
}

// HandleRefreshProductData 处理产品数据刷新任务
func (processor *ApifyTaskProcessor) HandleRefreshProductData(ctx context.Context, t *asynq.Task) error {
	var payload RefreshProductDataPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		return fmt.Errorf("failed to unmarshal payload: %w", err)
	}

	processor.logger.LogBusinessOperation(ctx, "refresh_task_started", "apify_worker", payload.ProductID, "processing",
		"asin", payload.ASIN,
		"task_id", t.Type(),
	)

	// 直接使用apify.Client调用产品详情actor
	productData, err := processor.apifyClient.FetchProductData(ctx, []string{payload.ASIN}, 60*time.Second)
	if err != nil {
		processor.logger.LogBusinessOperation(ctx, "refresh_task_failed", "apify_worker", payload.ProductID, "failed",
			"asin", payload.ASIN,
			"error", err.Error(),
		)
		return fmt.Errorf("failed to fetch product data from Apify: %w", err)
	}

	if len(productData) == 0 {
		processor.logger.LogBusinessOperation(ctx, "refresh_task_no_data", "apify_worker", payload.ProductID, "failed",
			"asin", payload.ASIN,
		)
		return fmt.Errorf("no product data returned from Apify for ASIN: %s", payload.ASIN)
	}

	// 直接使用返回的数据，因为apify client已经解析过了
	data := productData[0]

	// 记录获取到的数据
	processor.logger.LogBusinessOperation(ctx, "apify_data_received", "apify_worker", payload.ProductID, "success",
		"asin", data.ASIN,
		"title", data.Title,
		"price", data.Price,
		"rating", data.Rating,
		"review_count", data.ReviewCount,
		"bsr", data.BSR,
	)
	now := time.Now()

	// 开始数据库事务
	tx := processor.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 使用标准化的映射函数处理数据
	updates := MapApifyDataToProduct(&data, nil)
	updates["last_updated_at"] = now

	if err := tx.Table("products").Where("id = ?", payload.ProductID).Updates(updates).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update product: %w", err)
	}

	// 保存价格历史
	priceHistory := models.PriceHistory{
		ProductID:   payload.ProductID,
		Price:       data.Price,
		Currency:    data.Currency,
		BuyBoxPrice: data.BuyBoxPrice, // 使用实际的Buy Box价格，可能为nil
		RecordedAt:  now,
		DataSource:  "apify",
	}

	if err := tx.Create(&priceHistory).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to save price history: %w", err)
	}

	// 保存排名历史
	rankingHistory := models.RankingHistory{
		ProductID:   payload.ProductID,
		Category:    data.BSRCategory,
		BSRRank:     &data.BSR,
		Rating:      &data.Rating,
		ReviewCount: data.ReviewCount,
		RecordedAt:  now,
		DataSource:  "apify",
	}

	if err := tx.Create(&rankingHistory).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to save ranking history: %w", err)
	}

	// 保存评论历史
	reviewHistory := models.ReviewHistory{
		ProductID:     payload.ProductID,
		ReviewCount:   data.ReviewCount,
		AverageRating: &data.Rating,
		RecordedAt:    now,
		DataSource:    "apify",
		// 注意：Apify 没有提供详细的星级分布数据，所以其他字段使用默认值
	}

	if err := tx.Create(&reviewHistory).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to save review history: %w", err)
	}

	// 保存 BuyBox 历史
	buyboxHistory := models.BuyBoxHistory{
		ProductID:        payload.ProductID,
		WinnerSeller:     &data.Seller,
		WinnerPrice:      data.BuyBoxPrice, // 使用实际的Buy Box价格，可能为nil
		Currency:         data.Currency,
		IsPrime:          data.Prime,
		IsFBA:            (data.FulfilledBy == "Amazon"), // 如果由 Amazon 配送则认为是 FBA
		AvailabilityText: &data.Availability,
		RecordedAt:       now,
		DataSource:       "apify",
	}

	if err := tx.Create(&buyboxHistory).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to save buybox history: %w", err)
	}

	// 获取历史数据用于异常检测 (排除刚插入的记录)
	var lastPrice models.PriceHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, priceHistory.ID).
		Order("recorded_at DESC").
		First(&lastPrice)

	var lastRanking models.RankingHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, rankingHistory.ID).
		Order("recorded_at DESC").
		First(&lastRanking)

	var lastReview models.ReviewHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, reviewHistory.ID).
		Order("recorded_at DESC").
		First(&lastReview)

	var lastBuybox models.BuyBoxHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, buyboxHistory.ID).
		Order("recorded_at DESC").
		First(&lastBuybox)

	// 更新追踪记录的检查时间 (在事务提交前)
	if err := tx.Table("tracked_products").Where("id = ?", payload.TrackedID).Updates(map[string]interface{}{
		"last_checked_at": now,
	}).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update tracked product: %w", err)
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	// 🚀 数据保存成功，现在进行异常检测
	processor.detectAndRecordAnomalies(ctx, payload, data, lastPrice, lastRanking, lastReview, lastBuybox, priceHistory.ID, rankingHistory.ID, reviewHistory.ID, buyboxHistory.ID, now)

	// 清理相关缓存，确保前端获取最新数据
	processor.invalidateProductCache(ctx, payload.ASIN, payload.ProductID, payload.UserID)

	processor.logger.LogBusinessOperation(ctx, "refresh_task_completed", "apify_worker", payload.ProductID, "success",
		"asin", payload.ASIN,
		"price", data.Price,
		"bsr", data.BSR,
		"rating", data.Rating,
		"review_count", data.ReviewCount,
		"seller", data.Seller,
		"prime", data.Prime,
		"availability", data.Availability,
	)

	return nil
}

// detectAndRecordAnomalies 检测并记录异常变化 (requirements: 价格变动>10%, BSR变动>30%)
func (p *ApifyTaskProcessor) detectAndRecordAnomalies(ctx context.Context, payload RefreshProductDataPayload, newData apify.ProductData, lastPrice models.PriceHistory, lastRanking models.RankingHistory, lastReview models.ReviewHistory, lastBuybox models.BuyBoxHistory, newPriceID, newRankingID, newReviewID, newBuyboxID string, now time.Time) {

	// 获取用户设置的阈值
	var trackedProduct models.TrackedProduct
	if err := p.db.Where("id = ?", payload.TrackedID).First(&trackedProduct).Error; err != nil {
		p.logger.LogBusinessOperation(ctx, "anomaly_detection_failed", "apify_worker", payload.ProductID, "failed",
			"error", "failed to get tracking thresholds",
		)
		return
	}

	anomalyEvents := []models.AnomalyEvent{}

	// 1. 价格异常检测 (questions.md要求: >10%)
	if lastPrice.Price > 0 && newData.Price > 0 {
		priceChangePercentage := math.Abs((newData.Price-lastPrice.Price)/lastPrice.Price) * 100
		threshold := trackedProduct.PriceChangeThreshold
		if threshold == 0 {
			threshold = 10.0 // 默认阈值
		}

		if priceChangePercentage > threshold {
			thresholdPtr := &threshold
			severity := getSeverityForPriceChange(priceChangePercentage)
			anomalyEvent := models.AnomalyEvent{
				ProductID:        payload.ProductID,
				ASIN:             payload.ASIN,
				EventType:        "price_change",
				OldValue:         &lastPrice.Price,
				NewValue:         &newData.Price,
				ChangePercentage: &priceChangePercentage,
				Threshold:        thresholdPtr,
				Severity:         severity,
				CreatedAt:        now,
			}
			anomalyEvents = append(anomalyEvents, anomalyEvent)
		}
	}

	// 2. BSR异常检测 (questions.md要求: >30%)
	if lastRanking.BSRRank != nil && *lastRanking.BSRRank > 0 && newData.BSR > 0 {
		oldBSR := float64(*lastRanking.BSRRank)
		newBSR := float64(newData.BSR)
		bsrChangePercentage := math.Abs((newBSR-oldBSR)/oldBSR) * 100
		threshold := trackedProduct.BSRChangeThreshold
		if threshold == 0 {
			threshold = 30.0 // 默认阈值
		}

		if bsrChangePercentage > threshold {
			thresholdPtr := &threshold
			severity := getSeverityForBSRChange(bsrChangePercentage)
			anomalyEvent := models.AnomalyEvent{
				ProductID:        payload.ProductID,
				ASIN:             payload.ASIN,
				EventType:        "bsr_change",
				OldValue:         &oldBSR,
				NewValue:         &newBSR,
				ChangePercentage: &bsrChangePercentage,
				Threshold:        thresholdPtr,
				Severity:         severity,
				CreatedAt:        now,
			}
			anomalyEvents = append(anomalyEvents, anomalyEvent)
		}
	}


	// 3. 批量保存异常事件
	if len(anomalyEvents) > 0 {
		if err := p.db.Create(&anomalyEvents).Error; err != nil {
			p.logger.LogBusinessOperation(ctx, "anomaly_record_failed", "apify_worker", payload.ProductID, "failed",
				"error", err.Error(),
				"events_count", len(anomalyEvents),
			)
		} else {
			p.logger.LogBusinessOperation(ctx, "anomaly_detected", "apify_worker", payload.ProductID, "success",
				"asin", payload.ASIN,
				"events_count", len(anomalyEvents),
				"events", getEventSummary(anomalyEvents),
			)
		}
	}
}

// getSeverityForPriceChange 根据价格变化百分比确定严重程度
func getSeverityForPriceChange(percentage float64) string {
	if percentage >= 20 {
		return "critical"
	} else if percentage >= 10 {
		return "warning"
	}
	return "info"
}

// getSeverityForBSRChange 根据BSR变化百分比确定严重程度
func getSeverityForBSRChange(percentage float64) string {
	if percentage >= 50 {
		return "critical"
	} else if percentage >= 30 {
		return "warning"
	}
	return "info"
}

// getEventSummary 获取事件摘要用于日志
func getEventSummary(events []models.AnomalyEvent) string {
	summary := make([]string, len(events))
	for i, event := range events {
		summary[i] = fmt.Sprintf("%s:%.1f%%", event.EventType, *event.ChangePercentage)
	}
	return strings.Join(summary, ",")
}

// invalidateProductCache 清理产品相关缓存（使用统一缓存key）
func (p *ApifyTaskProcessor) invalidateProductCache(ctx context.Context, asin, productID, userID string) {
	// 使用统一的缓存key清理产品数据缓存
	productDataKey := cache.ProductDataKey(productID)
	if err := p.redisClient.Del(ctx, productDataKey).Err(); err != nil {
		p.logger.Error(ctx, "Failed to delete product data cache", "key", productDataKey, "error", err)
	}

	// 清理价格缓存
	priceCacheKey := cache.PriceCacheKey(productID)
	if err := p.redisClient.Del(ctx, priceCacheKey).Err(); err != nil {
		p.logger.Error(ctx, "Failed to delete price cache", "key", priceCacheKey, "error", err)
	}

	// 清理排名缓存
	rankingCacheKey := cache.RankingCacheKey(productID)
	if err := p.redisClient.Del(ctx, rankingCacheKey).Err(); err != nil {
		p.logger.Error(ctx, "Failed to delete ranking cache", "key", rankingCacheKey, "error", err)
	}

	p.logger.Info(ctx, "Invalidated product cache",
		"product_id", productID,
		"asin", asin,
		"initiator_user_id", userID)

	p.logger.LogBusinessOperation(ctx, "cache_invalidated", "apify_worker", productID, "success",
		"asin", asin,
		"initiator_user_id", userID,
	)
}

// HandleGenerateReport 处理异步报告生成任务
func (p *ApifyTaskProcessor) HandleGenerateReport(ctx context.Context, t *asynq.Task) error {
	// 解析任务载荷
	var payload GenerateReportPayload
	if err := json.Unmarshal(t.Payload(), &payload); err != nil {
		p.logger.Error(ctx, "Failed to unmarshal generate report payload", "error", err)
		return fmt.Errorf("failed to unmarshal payload: %w", err)
	}

	p.logger.Info(ctx, "Starting async report generation",
		"analysis_id", payload.AnalysisID,
		"task_id", payload.TaskID,
		"user_id", payload.UserID,
		"force", payload.Force,
	)

	// 更新任务状态为处理中
	if err := p.updateReportStatus(ctx, payload.TaskID, "processing", nil, nil); err != nil {
		p.logger.Error(ctx, "Failed to update status to processing", "task_id", payload.TaskID, "error", err)
		return err
	}

	// 执行报告生成逻辑（复用同步版本的逻辑）
	if err := p.generateReportAsync(ctx, payload); err != nil {
		// 更新状态为失败
		errorMsg := err.Error()
		if updateErr := p.updateReportStatus(ctx, payload.TaskID, "failed", nil, &errorMsg); updateErr != nil {
			p.logger.Error(ctx, "Failed to update failed status", "task_id", payload.TaskID, "error", updateErr)
		}

		p.logger.Error(ctx, "Async report generation failed",
			"analysis_id", payload.AnalysisID,
			"task_id", payload.TaskID,
			"error", err,
		)
		return err
	}

	p.logger.Info(ctx, "Async report generation completed successfully",
		"analysis_id", payload.AnalysisID,
		"task_id", payload.TaskID,
		"user_id", payload.UserID,
	)

	return nil
}

// updateReportStatus 更新报告生成状态
func (p *ApifyTaskProcessor) updateReportStatus(ctx context.Context, taskID, status string, completedAt *time.Time, errorMsg *string) error {
	updates := map[string]interface{}{
		"status": status,
	}

	if completedAt != nil {
		updates["completed_at"] = *completedAt
	}

	if errorMsg != nil {
		updates["error_message"] = *errorMsg
	}

	return p.db.Model(&models.CompetitorAnalysisResult{}).
		Where("task_id = ?", taskID).
		Updates(updates).Error
}

// generateReportAsync 异步执行报告生成的核心逻辑
func (p *ApifyTaskProcessor) generateReportAsync(ctx context.Context, payload GenerateReportPayload) error {
	// 1. 获取分析组数据
	var analysisGroup models.CompetitorAnalysisGroup
	err := p.db.Where("id = ?", payload.AnalysisID).
		Preload("MainProduct").
		Preload("Competitors.Product").
		First(&analysisGroup).Error
	if err != nil {
		return fmt.Errorf("failed to fetch analysis group: %w", err)
	}

	// 2. 获取OpenAI API Key
	openaiKey := os.Getenv("OPENAI_API_KEY")
	if openaiKey == "" {
		return fmt.Errorf("OpenAI API key not configured")
	}

	// 3. 获取主产品的最新数据
	mainProductData, err := p.getLatestProductDataForReport(analysisGroup.MainProduct.ID)
	if err != nil {
		return fmt.Errorf("failed to fetch main product data: %w", err)
	}

	// 4. 准备分析数据
	analysisData := llm.CompetitorAnalysisData{
		MainProduct: llm.ProductData{
			ASIN:        analysisGroup.MainProduct.ASIN,
			Title:       p.getStringValue(analysisGroup.MainProduct.Title),
			Price:       mainProductData.Price,
			Currency:    mainProductData.Currency,
			BSR:         mainProductData.BSR,
			Rating:      mainProductData.Rating,
			ReviewCount: mainProductData.ReviewCount,
		},
		Competitors:     make([]llm.ProductData, len(analysisGroup.Competitors)),
		AnalysisMetrics: []string{"price", "bsr", "rating", "features"},
	}

	// 5. 获取竞品数据
	for i, comp := range analysisGroup.Competitors {
		competitorData, err := p.getLatestProductDataForReport(comp.Product.ID)
		if err != nil {
			p.logger.Error(ctx, "Failed to get competitor data", "asin", comp.Product.ASIN, "error", err)
			// 使用默认数据继续处理
			competitorData = &ProductDataForReport{
				Price: 0, Currency: "USD", BSR: 0, Rating: 0, ReviewCount: 0,
			}
		}

		analysisData.Competitors[i] = llm.ProductData{
			ASIN:        comp.Product.ASIN,
			Title:       p.getStringValue(comp.Product.Title),
			Price:       competitorData.Price,
			Currency:    competitorData.Currency,
			BSR:         competitorData.BSR,
			Rating:      competitorData.Rating,
			ReviewCount: competitorData.ReviewCount,
		}
	}

	// 6. 调用DeepSeek生成报告
	client := llm.NewDeepSeekClient(openaiKey)
	report, err := client.GenerateCompetitorReport(ctx, analysisData)
	if err != nil {
		return fmt.Errorf("failed to generate LLM report: %w", err)
	}

	// 7. 保存分析结果
	analysisDataJSON, _ := json.Marshal(analysisData)
	insightsJSON, _ := json.Marshal(report)
	recommendationsJSON, _ := json.Marshal(report.Recommendations)
	completedAt := time.Now()

	err = p.updateReportStatus(ctx, payload.TaskID, "completed", &completedAt, nil)
	if err != nil {
		return fmt.Errorf("failed to save final result: %w", err)
	}

	// 8. 更新完整的分析结果
	updates := map[string]interface{}{
		"analysis_data":   analysisDataJSON,
		"insights":        insightsJSON,
		"recommendations": recommendationsJSON,
	}

	err = p.db.Model(&models.CompetitorAnalysisResult{}).
		Where("task_id = ?", payload.TaskID).
		Updates(updates).Error
	if err != nil {
		return fmt.Errorf("failed to update analysis data: %w", err)
	}

	p.logger.LogBusinessOperation(ctx, "generate_report_async_completed", "analysis_group", payload.AnalysisID, "success",
		"task_id", payload.TaskID,
		"competitor_count", len(analysisGroup.Competitors),
		"has_recommendations", len(report.Recommendations),
	)

	return nil
}

// ProductDataForReport 产品数据结构（避免与其他地方冲突）
type ProductDataForReport struct {
	Price       float64
	Currency    string
	BSR         int
	Rating      float64
	ReviewCount int
}

// getLatestProductDataForReport 获取产品的最新数据
func (p *ApifyTaskProcessor) getLatestProductDataForReport(productID string) (*ProductDataForReport, error) {
	// 获取最新价格数据
	var latestPrice models.PriceHistory
	err := p.db.Where("product_id = ?", productID).
		Order("recorded_at DESC").
		First(&latestPrice).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	// 获取最新排名数据
	var latestRanking models.RankingHistory
	err = p.db.Where("product_id = ?", productID).
		Order("recorded_at DESC").
		First(&latestRanking).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	data := &ProductDataForReport{
		Price:       latestPrice.Price,
		Currency:    latestPrice.Currency,
		ReviewCount: latestRanking.ReviewCount,
	}

	// 安全设置BSR和Rating
	if latestRanking.BSRRank != nil {
		data.BSR = *latestRanking.BSRRank
	}
	if latestRanking.Rating != nil {
		data.Rating = *latestRanking.Rating
	}

	return data, nil
}

// getStringValue 安全获取字符串指针的值
func (p *ApifyTaskProcessor) getStringValue(str *string) string {
	if str != nil {
		return *str
	}
	return ""
}
