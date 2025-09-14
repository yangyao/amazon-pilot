package tasks

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"

	"amazonpilot/internal/pkg/apify"
	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"

	"github.com/hibiken/asynq"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

const (
	TypeRefreshProductData = "refresh_product_data"
)

type RefreshProductDataPayload struct {
	ProductID   string `json:"product_id"`
	TrackedID   string `json:"tracked_id"`
	ASIN        string `json:"asin"`
	UserID      string `json:"user_id"`
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

	// 更新产品基础信息，包含完整的Apify数据映射
	updates := map[string]interface{}{
		"title":           data.Title,
		"brand":           data.Brand,
		"category":        data.Category,
		"description":     data.Description,
		"last_updated_at": now,
	}

	// 映射bullet points (Apify的features -> 数据库的bullet_points)
	if len(data.BulletPoints) > 0 {
		bulletPointsJSON, _ := json.Marshal(data.BulletPoints)
		updates["bullet_points"] = bulletPointsJSON
	}

	// 映射图片URLs
	if len(data.Images) > 0 {
		imagesJSON, _ := json.Marshal(data.Images)
		updates["images"] = imagesJSON
	}

	if err := tx.Table("products").Where("id = ?", payload.ProductID).Updates(updates).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update product: %w", err)
	}

	// 保存价格历史
	priceHistory := models.PriceHistory{
		ProductID:   payload.ProductID,
		Price:       data.Price,
		Currency:    data.Currency,
		BuyBoxPrice: &data.Price,
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

	// 获取历史数据用于异常检测 (排除刚插入的记录)
	var lastPrice models.PriceHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, priceHistory.ID).
		Order("recorded_at DESC").
		First(&lastPrice)

	var lastRanking models.RankingHistory
	processor.db.Where("product_id = ? AND id != ?", payload.ProductID, rankingHistory.ID).
		Order("recorded_at DESC").
		First(&lastRanking)

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
	processor.detectAndRecordAnomalies(ctx, payload, data, lastPrice, lastRanking, priceHistory.ID, rankingHistory.ID, now)

	// 清理相关缓存，确保前端获取最新数据
	processor.invalidateProductCache(ctx, payload.ASIN, payload.ProductID, payload.UserID)

	processor.logger.LogBusinessOperation(ctx, "refresh_task_completed", "apify_worker", payload.ProductID, "success",
		"asin", payload.ASIN,
		"price", data.Price,
		"bsr", data.BSR,
		"rating", data.Rating,
		"review_count", data.ReviewCount,
	)

	return nil
}

// detectAndRecordAnomalies 检测并记录异常变化 (requirements: 价格变动>10%, BSR变动>30%)
func (p *ApifyTaskProcessor) detectAndRecordAnomalies(ctx context.Context, payload RefreshProductDataPayload, newData apify.ProductData, lastPrice models.PriceHistory, lastRanking models.RankingHistory, newPriceID, newRankingID string, now time.Time) {

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

	// 3. 评分变化检测 (questions.md要求: 評分與評論數變化)
	if lastRanking.Rating != nil && *lastRanking.Rating > 0 && newData.Rating > 0 {
		oldRating := *lastRanking.Rating
		newRating := newData.Rating
		ratingChangePercentage := math.Abs((newRating-oldRating)/oldRating) * 100

		// 评分变化阈值可以设为5%（比较敏感）
		ratingThreshold := 5.0
		if ratingChangePercentage > ratingThreshold {
			thresholdPtr := &ratingThreshold
			severity := "info" // 评分变化通常是info级别
			if ratingChangePercentage > 20 {
				severity = "warning"
			}

			anomalyEvent := models.AnomalyEvent{
				ProductID:        payload.ProductID,
				ASIN:             payload.ASIN,
				EventType:        "rating_change",
				OldValue:         &oldRating,
				NewValue:         &newRating,
				ChangePercentage: &ratingChangePercentage,
				Threshold:        thresholdPtr,
				Severity:         severity,
				CreatedAt:        now,
			}
			anomalyEvents = append(anomalyEvents, anomalyEvent)
		}
	}

	// 4. 评论数变化检测 (questions.md要求: 評分與評論數變化)
	if lastRanking.ReviewCount > 0 && newData.ReviewCount > 0 {
		oldReviewCount := float64(lastRanking.ReviewCount)
		newReviewCount := float64(newData.ReviewCount)
		reviewChangePercentage := math.Abs((newReviewCount-oldReviewCount)/oldReviewCount) * 100

		// 评论数变化阈值设为20%
		reviewThreshold := 20.0
		if reviewChangePercentage > reviewThreshold {
			thresholdPtr := &reviewThreshold
			severity := "info"
			if reviewChangePercentage > 50 {
				severity = "warning"
			}

			anomalyEvent := models.AnomalyEvent{
				ProductID:        payload.ProductID,
				ASIN:             payload.ASIN,
				EventType:        "review_count_change",
				OldValue:         &oldReviewCount,
				NewValue:         &newReviewCount,
				ChangePercentage: &reviewChangePercentage,
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

// invalidateProductCache 清理产品相关缓存 (简化版本)
func (p *ApifyTaskProcessor) invalidateProductCache(ctx context.Context, asin, productID, userID string) {
	// 使用已配置的Redis客户端进行缓存清理
	defer p.redisClient.Close()

	// 清理产品基本信息缓存
	productCacheKey := fmt.Sprintf("amazon_pilot:product:%s", asin)
	p.redisClient.Del(ctx, productCacheKey)

	// 清理用户追踪产品列表缓存
	trackedCacheKey := fmt.Sprintf("amazon_pilot:tracked:%s", userID)
	p.redisClient.Del(ctx, trackedCacheKey)

	// 清理最新价格数据缓存
	priceCacheKey := fmt.Sprintf("amazon_pilot:price:%s:latest", productID)
	p.redisClient.Del(ctx, priceCacheKey)

	p.logger.LogBusinessOperation(ctx, "cache_invalidated", "apify_worker", productID, "success",
		"asin", asin,
		"user_id", userID,
	)
}
