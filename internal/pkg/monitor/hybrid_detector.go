package monitor

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/queue"

	"github.com/jackc/pgx/v5"
	"gorm.io/gorm"
)

// HybridAnomalyDetector 混合异常检测器 (推荐方案)
// 结合PostgreSQL触发器的实时性和应用层的灵活性
type HybridAnomalyDetector struct {
	db       *gorm.DB
	queueMgr *queue.QueueManager
	logger   *logger.ServiceLogger
	conn     *pgx.Conn
	ctx      context.Context
	cancel   context.CancelFunc
}

// ChangeEvent 轻量级变更事件
type ChangeEvent struct {
	ProductID  string    `json:"product_id"`
	ChangeType string    `json:"change_type"` // price, bsr, rating
	OldValue   *float64  `json:"old_value,omitempty"`
	NewValue   *float64  `json:"new_value,omitempty"`
	Timestamp  time.Time `json:"timestamp"`
}

// NewHybridAnomalyDetector 创建混合异常检测器
func NewHybridAnomalyDetector(dbURL string, db *gorm.DB, queueMgr *queue.QueueManager) (*HybridAnomalyDetector, error) {
	ctx, cancel := context.WithCancel(context.Background())
	
	// 连接PostgreSQL用于LISTEN
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to connect for LISTEN: %w", err)
	}

	return &HybridAnomalyDetector{
		db:       db,
		queueMgr: queueMgr,
		logger:   logger.NewServiceLogger("hybrid_detector"),
		conn:     conn,
		ctx:      ctx,
		cancel:   cancel,
	}, nil
}

// Start 启动混合检测器
func (had *HybridAnomalyDetector) Start() error {
	slog.Info("Starting Hybrid Anomaly Detector")

	// 监听轻量级变更通知
	if _, err := had.conn.Exec(had.ctx, "LISTEN product_changes"); err != nil {
		return fmt.Errorf("failed to listen to product_changes: %w", err)
	}

	// 启动监听循环
	go had.listenLoop()

	// 启动补偿任务 (处理可能丢失的事件)
	go had.compensationLoop()

	slog.Info("Hybrid anomaly detector started")
	return nil
}

// listenLoop 监听PostgreSQL通知
func (had *HybridAnomalyDetector) listenLoop() {
	for {
		select {
		case <-had.ctx.Done():
			return
		default:
			notification, err := had.conn.WaitForNotification(context.Background())
			if err != nil {
				if pgx.Timeout(err) {
					continue
				}
				had.logger.LogError(had.ctx, "Listen error", "error", err.Error())
				time.Sleep(5 * time.Second)
				continue
			}

			if notification != nil && notification.Channel == "product_changes" {
				go had.processChangeEvent(notification.Payload) // 异步处理
			}
		}
	}
}

// processChangeEvent 处理变更事件 (应用层)
func (had *HybridAnomalyDetector) processChangeEvent(payload string) {
	ctx := context.Background()
	
	var event ChangeEvent
	if err := json.Unmarshal([]byte(payload), &event); err != nil {
		had.logger.LogError(ctx, "Failed to parse change event", "error", err.Error())
		return
	}

	had.logger.LogInfo(ctx, "Processing change event",
		"product_id", event.ProductID,
		"change_type", event.ChangeType,
	)

	// 查询完整的产品和用户信息 (应用层)
	var result struct {
		Product models.Product
		User    models.User
		Tracked models.TrackedProduct
	}

	err := had.db.
		Select("products.*, users.*, tracked_products.*").
		Table("products").
		Joins("JOIN tracked_products ON products.id = tracked_products.product_id").
		Joins("JOIN users ON tracked_products.user_id = users.id").
		Where("products.id = ? AND tracked_products.is_active = true", event.ProductID).
		Scan(&result).Error

	if err != nil {
		had.logger.LogError(ctx, "Failed to query product details", 
			"product_id", event.ProductID, 
			"error", err.Error())
		return
	}

	// 根据变更类型进行异常检测
	switch event.ChangeType {
	case "price":
		had.detectPriceAnomaly(ctx, event, result)
	case "bsr":
		had.detectBSRAnomaly(ctx, event, result)
	case "rating":
		had.detectRatingAnomaly(ctx, event, result)
	}

	// 标记事件为已处理 (在change_events表中)
	had.db.Model(&models.ChangeEvent{}).
		Where("product_id = ? AND event_type = ? AND created_at = ?", 
			event.ProductID, event.ChangeType+"_change", event.Timestamp).
		Update("processed", true)
}

// detectPriceAnomaly 检测价格异常 (应用层灵活处理)
func (had *HybridAnomalyDetector) detectPriceAnomaly(ctx context.Context, event ChangeEvent, data interface{}) {
	if event.OldValue == nil || event.NewValue == nil || *event.OldValue == 0 {
		return
	}

	changeRate := (*event.NewValue - *event.OldValue) / *event.OldValue * 100
	
	// 用户自定义阈值检查 (可以从用户设置中读取)
	threshold := 10.0 // 默认10%，可以从用户配置读取
	
	if abs(changeRate) >= threshold {
		// 创建详细的异常通知
		severity := "warning"
		if abs(changeRate) >= 20 {
			severity = "critical"
		}

		// 构建通知数据
		notificationData := map[string]interface{}{
			"notification": map[string]interface{}{
				"type":     "price_alert",
				"title":    fmt.Sprintf("Price Alert: %s", data.(struct{Product models.Product}).Product.ASIN),
				"message":  fmt.Sprintf("Price changed by %.1f%% (from $%.2f to $%.2f)", changeRate, *event.OldValue, *event.NewValue),
				"severity": severity,
			},
			"change_data": map[string]interface{}{
				"old_price":         *event.OldValue,
				"new_price":         *event.NewValue,
				"change_percentage": changeRate,
				"timestamp":         event.Timestamp,
			},
		}

		// 高优先级入队
		priority := 7
		if severity == "critical" {
			priority = 9
		}

		// 这里可以添加更多业务逻辑：
		// - 检查用户通知偏好
		// - 根据用户套餐调整通知频率
		// - 智能去重（避免短时间内重复通知）
		
		had.queueMgr.EnqueueNotification(data.(struct{User models.User}).User.ID, notificationData, priority)
		
		had.logger.LogBusinessOperation(ctx, "price_anomaly_detected", "anomaly", "", "success",
			"product_id", event.ProductID,
			"change_rate", changeRate,
			"severity", severity,
		)
	}
}

// compensationLoop 补偿任务循环 (处理可能丢失的事件)
func (had *HybridAnomalyDetector) compensationLoop() {
	ticker := time.NewTicker(5 * time.Minute) // 每5分钟检查一次
	defer ticker.Stop()

	for {
		select {
		case <-had.ctx.Done():
			return
		case <-ticker.C:
			had.processUnhandledEvents()
		}
	}
}

// processUnhandledEvents 处理未处理的事件 (数据保障)
func (had *HybridAnomalyDetector) processUnhandledEvents() {
	// 查找5分钟前还未处理的事件
	fiveMinutesAgo := time.Now().Add(-5 * time.Minute)
	
	var unprocessedEvents []models.ChangeEvent
	err := had.db.Where("processed = false AND created_at < ?", fiveMinutesAgo).
		Limit(100). // 批量处理
		Find(&unprocessedEvents).Error
		
	if err != nil {
		had.logger.LogError(had.ctx, "Failed to query unprocessed events", "error", err.Error())
		return
	}

	for _, event := range unprocessedEvents {
		// 重新处理事件
		eventJSON, _ := json.Marshal(ChangeEvent{
			ProductID:  event.ProductID,
			ChangeType: event.EventType,
			Timestamp:  event.CreatedAt,
		})
		
		go had.processChangeEvent(string(eventJSON))
	}

	if len(unprocessedEvents) > 0 {
		slog.Info("Processed unhandled events", "count", len(unprocessedEvents))
	}
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

// Stop 停止检测器
func (had *HybridAnomalyDetector) Stop() {
	had.cancel()
	if had.conn != nil {
		had.conn.Close(had.ctx)
	}
}