package monitor

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"time"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/queue"

	"gorm.io/gorm"
)

// AnomalyDetector 异常检测器
type AnomalyDetector struct {
	db       *gorm.DB
	queueMgr *queue.QueueManager
	logger   *logger.ServiceLogger
}

// AnomalyConfig 异常检测配置
type AnomalyConfig struct {
	PriceChangeThreshold float64 // 价格变动阈值 (百分比)
	BSRChangeThreshold   float64 // BSR变动阈值 (百分比)
	RatingChangeThreshold float64 // 评分变动阈值
	CheckPeriodHours     int     // 检查周期 (小时)
}

// AnomalyEvent 异常事件
type AnomalyEvent struct {
	Type        string    `json:"type"`
	ProductID   string    `json:"product_id"`
	ProductASIN string    `json:"product_asin"`
	UserID      string    `json:"user_id"`
	OldValue    float64   `json:"old_value"`
	NewValue    float64   `json:"new_value"`
	ChangeRate  float64   `json:"change_rate"`
	Severity    string    `json:"severity"`
	Timestamp   time.Time `json:"timestamp"`
	Message     string    `json:"message"`
}

// 异常类型常量
const (
	AnomalyTypePriceIncrease = "price_increase"
	AnomalyTypePriceDecrease = "price_decrease"
	AnomalyTypeBSRImprove    = "bsr_improve"
	AnomalyTypeBSRWorsen     = "bsr_worsen"
	AnomalyTypeRatingDrop    = "rating_drop"
)

// NewAnomalyDetector 创建异常检测器
func NewAnomalyDetector(db *gorm.DB, queueMgr *queue.QueueManager) *AnomalyDetector {
	return &AnomalyDetector{
		db:       db,
		queueMgr: queueMgr,
		logger:   logger.NewServiceLogger("anomaly_detector"),
	}
}

// DetectAnomalies 检测异常变化
func (ad *AnomalyDetector) DetectAnomalies(ctx context.Context, config AnomalyConfig) error {
	ad.logger.LogInfo(ctx, "Starting anomaly detection",
		"price_threshold", config.PriceChangeThreshold,
		"bsr_threshold", config.BSRChangeThreshold,
	)

	// 检测价格异常
	if err := ad.detectPriceAnomalies(ctx, config); err != nil {
		ad.logger.LogError(ctx, "Failed to detect price anomalies", "error", err.Error())
		return err
	}

	// 检测BSR异常
	if err := ad.detectBSRAnomalies(ctx, config); err != nil {
		ad.logger.LogError(ctx, "Failed to detect BSR anomalies", "error", err.Error())
		return err
	}

	// 检测评分异常
	if err := ad.detectRatingAnomalies(ctx, config); err != nil {
		ad.logger.LogError(ctx, "Failed to detect rating anomalies", "error", err.Error())
		return err
	}

	ad.logger.LogBusinessOperation(ctx, "anomaly_detection_complete", "system", "", "success")
	return nil
}

// detectPriceAnomalies 检测价格异常变化
func (ad *AnomalyDetector) detectPriceAnomalies(ctx context.Context, config AnomalyConfig) error {
	// 查找最近24小时内有价格更新的产品
	since := time.Now().Add(-time.Duration(config.CheckPeriodHours) * time.Hour)
	
	query := `
		SELECT DISTINCT p.id, p.asin, p.user_id, p.current_price,
			   LAG(ph.price) OVER (PARTITION BY p.id ORDER BY ph.recorded_at DESC) as previous_price
		FROM products p
		JOIN product_price_history ph ON p.id = ph.product_id
		WHERE p.is_tracked = true 
		  AND ph.recorded_at >= ?
		ORDER BY p.id, ph.recorded_at DESC
	`

	rows, err := ad.db.Raw(query, since).Rows()
	if err != nil {
		return fmt.Errorf("failed to query price changes: %w", err)
	}
	defer rows.Close()

	var anomalies []AnomalyEvent
	
	for rows.Next() {
		var productID, asin, userID string
		var currentPrice, previousPrice *float64
		
		if err := rows.Scan(&productID, &asin, &userID, &currentPrice, &previousPrice); err != nil {
			continue
		}

		if currentPrice == nil || previousPrice == nil || *previousPrice == 0 {
			continue
		}

		// 计算变化率
		changeRate := (*currentPrice - *previousPrice) / *previousPrice * 100

		// 检查是否超过阈值
		if math.Abs(changeRate) >= config.PriceChangeThreshold {
			anomalyType := AnomalyTypePriceIncrease
			severity := "warning"
			message := fmt.Sprintf("Price increased by %.1f%% (from $%.2f to $%.2f)", 
				changeRate, *previousPrice, *currentPrice)

			if changeRate < 0 {
				anomalyType = AnomalyTypePriceDecrease
				message = fmt.Sprintf("Price decreased by %.1f%% (from $%.2f to $%.2f)", 
					math.Abs(changeRate), *previousPrice, *currentPrice)
			}

			if math.Abs(changeRate) >= 20 {
				severity = "critical"
			}

			anomaly := AnomalyEvent{
				Type:        anomalyType,
				ProductID:   productID,
				ProductASIN: asin,
				UserID:      userID,
				OldValue:    *previousPrice,
				NewValue:    *currentPrice,
				ChangeRate:  changeRate,
				Severity:    severity,
				Timestamp:   time.Now(),
				Message:     message,
			}

			anomalies = append(anomalies, anomaly)
		}
	}

	// 发送通知
	for _, anomaly := range anomalies {
		if err := ad.sendAnomalyNotification(ctx, anomaly); err != nil {
			ad.logger.LogError(ctx, "Failed to send price anomaly notification",
				"product_id", anomaly.ProductID,
				"error", err.Error(),
			)
		}
	}

	slog.Info("Price anomaly detection completed",
		"anomalies_found", len(anomalies),
		"threshold", config.PriceChangeThreshold,
	)

	return nil
}

// detectBSRAnomalies 检测BSR异常变化
func (ad *AnomalyDetector) detectBSRAnomalies(ctx context.Context, config AnomalyConfig) error {
	// 查找最近的BSR变化
	since := time.Now().Add(-time.Duration(config.CheckPeriodHours) * time.Hour)
	
	query := `
		SELECT DISTINCT p.id, p.asin, p.user_id, p.current_bsr,
			   LAG(bh.bsr) OVER (PARTITION BY p.id ORDER BY bh.recorded_at DESC) as previous_bsr
		FROM products p
		JOIN product_bsr_history bh ON p.id = bh.product_id
		WHERE p.is_tracked = true 
		  AND bh.recorded_at >= ?
		  AND p.current_bsr IS NOT NULL
		ORDER BY p.id, bh.recorded_at DESC
	`

	rows, err := ad.db.Raw(query, since).Rows()
	if err != nil {
		return fmt.Errorf("failed to query BSR changes: %w", err)
	}
	defer rows.Close()

	var anomalies []AnomalyEvent
	
	for rows.Next() {
		var productID, asin, userID string
		var currentBSR, previousBSR *int
		
		if err := rows.Scan(&productID, &asin, &userID, &currentBSR, &previousBSR); err != nil {
			continue
		}

		if currentBSR == nil || previousBSR == nil || *previousBSR == 0 {
			continue
		}

		// 计算BSR变化率 (BSR越小越好，所以计算方式相反)
		changeRate := float64(*previousBSR - *currentBSR) / float64(*previousBSR) * 100

		// 检查是否超过阈值
		if math.Abs(changeRate) >= config.BSRChangeThreshold {
			anomalyType := AnomalyTypeBSRImprove
			severity := "info"
			message := fmt.Sprintf("BSR improved by %.1f%% (from #%d to #%d)", 
				math.Abs(changeRate), *previousBSR, *currentBSR)

			if changeRate < 0 {
				anomalyType = AnomalyTypeBSRWorsen
				severity = "warning"
				message = fmt.Sprintf("BSR worsened by %.1f%% (from #%d to #%d)", 
					math.Abs(changeRate), *previousBSR, *currentBSR)
			}

			if math.Abs(changeRate) >= 50 {
				severity = "critical"
			}

			anomaly := AnomalyEvent{
				Type:        anomalyType,
				ProductID:   productID,
				ProductASIN: asin,
				UserID:      userID,
				OldValue:    float64(*previousBSR),
				NewValue:    float64(*currentBSR),
				ChangeRate:  changeRate,
				Severity:    severity,
				Timestamp:   time.Now(),
				Message:     message,
			}

			anomalies = append(anomalies, anomaly)
		}
	}

	// 发送通知
	for _, anomaly := range anomalies {
		if err := ad.sendAnomalyNotification(ctx, anomaly); err != nil {
			ad.logger.LogError(ctx, "Failed to send BSR anomaly notification",
				"product_id", anomaly.ProductID,
				"error", err.Error(),
			)
		}
	}

	slog.Info("BSR anomaly detection completed",
		"anomalies_found", len(anomalies),
		"threshold", config.BSRChangeThreshold,
	)

	return nil
}

// detectRatingAnomalies 检测评分异常变化  
func (ad *AnomalyDetector) detectRatingAnomalies(ctx context.Context, config AnomalyConfig) error {
	// 查找最近的评分显著下降
	since := time.Now().Add(-time.Duration(config.CheckPeriodHours) * time.Hour)
	
	query := `
		SELECT p.id, p.asin, p.user_id, p.rating,
			   LAG(p.rating) OVER (PARTITION BY p.id ORDER BY p.updated_at DESC) as previous_rating
		FROM products p
		WHERE p.is_tracked = true 
		  AND p.updated_at >= ?
		  AND p.rating IS NOT NULL
		ORDER BY p.id, p.updated_at DESC
	`

	rows, err := ad.db.Raw(query, since).Rows()
	if err != nil {
		return fmt.Errorf("failed to query rating changes: %w", err)
	}
	defer rows.Close()

	var anomalies []AnomalyEvent
	
	for rows.Next() {
		var productID, asin, userID string
		var currentRating, previousRating *float64
		
		if err := rows.Scan(&productID, &asin, &userID, &currentRating, &previousRating); err != nil {
			continue
		}

		if currentRating == nil || previousRating == nil {
			continue
		}

		// 评分下降超过阈值
		ratingDrop := *previousRating - *currentRating
		if ratingDrop >= config.RatingChangeThreshold {
			severity := "warning"
			if ratingDrop >= 0.5 {
				severity = "critical"
			}

			message := fmt.Sprintf("Rating dropped by %.2f stars (from %.2f to %.2f)", 
				ratingDrop, *previousRating, *currentRating)

			anomaly := AnomalyEvent{
				Type:        AnomalyTypeRatingDrop,
				ProductID:   productID,
				ProductASIN: asin,
				UserID:      userID,
				OldValue:    *previousRating,
				NewValue:    *currentRating,
				ChangeRate:  ratingDrop,
				Severity:    severity,
				Timestamp:   time.Now(),
				Message:     message,
			}

			anomalies = append(anomalies, anomaly)
		}
	}

	// 发送通知
	for _, anomaly := range anomalies {
		if err := ad.sendAnomalyNotification(ctx, anomaly); err != nil {
			ad.logger.LogError(ctx, "Failed to send rating anomaly notification",
				"product_id", anomaly.ProductID,
				"error", err.Error(),
			)
		}
	}

	slog.Info("Rating anomaly detection completed",
		"anomalies_found", len(anomalies),
		"threshold", config.RatingChangeThreshold,
	)

	return nil
}

// sendAnomalyNotification 发送异常通知
func (ad *AnomalyDetector) sendAnomalyNotification(ctx context.Context, anomaly AnomalyEvent) error {
	// 创建通知数据
	notificationData := map[string]interface{}{
		"notification": map[string]interface{}{
			"type":     anomaly.Type,
			"title":    fmt.Sprintf("Product Alert: %s", anomaly.ProductASIN),
			"message":  anomaly.Message,
			"severity": anomaly.Severity,
		},
		"anomaly": anomaly,
	}

	// 确定优先级
	priority := 5 // 默认优先级
	switch anomaly.Severity {
	case "critical":
		priority = 9
	case "warning":
		priority = 7
	case "info":
		priority = 4
	}

	// 入队通知任务
	if err := ad.queueMgr.EnqueueNotification(anomaly.UserID, notificationData, priority); err != nil {
		return fmt.Errorf("failed to enqueue notification: %w", err)
	}

	// 直接创建数据库通知记录 (立即可见)
	notification := models.Notification{
		UserID:    anomaly.UserID,
		Type:      anomaly.Type,
		Title:     fmt.Sprintf("Product Alert: %s", anomaly.ProductASIN),
		Message:   anomaly.Message,
		Severity:  anomaly.Severity,
		ProductID: &anomaly.ProductID,
		IsRead:    false,
	}

	// 序列化异常数据到通知中
	anomalyBytes, _ := json.Marshal(anomaly)
	notification.Data = anomalyBytes

	if err := ad.db.Create(&notification).Error; err != nil {
		return fmt.Errorf("failed to create notification record: %w", err)
	}

	ad.logger.LogBusinessOperation(ctx, "anomaly_notification_sent", "notification", notification.ID, "success",
		"anomaly_type", anomaly.Type,
		"product_asin", anomaly.ProductASIN,
		"severity", anomaly.Severity,
		"change_rate", anomaly.ChangeRate,
	)

	return nil
}

// GetDefaultConfig 获取默认配置
func GetDefaultConfig() AnomalyConfig {
	return AnomalyConfig{
		PriceChangeThreshold:  10.0, // 10%价格变动
		BSRChangeThreshold:    30.0, // 30%BSR变动
		RatingChangeThreshold: 0.3,  // 0.3星评分下降
		CheckPeriodHours:      24,   // 24小时周期
	}
}

// RunAnomalyDetection 运行异常检测 (供调度器调用)
func RunAnomalyDetection(ctx context.Context, db *gorm.DB, queueMgr *queue.QueueManager) error {
	detector := NewAnomalyDetector(db, queueMgr)
	config := GetDefaultConfig()
	
	return detector.DetectAnomalies(ctx, config)
}