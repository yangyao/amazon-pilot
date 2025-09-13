package listener

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
	"github.com/jackc/pgx/v5/pgxpool"
	"gorm.io/gorm"
)

// PgNotifyListener PostgreSQL通知监听器 (按照原始设计)
type PgNotifyListener struct {
	conn         *pgx.Conn
	db           *gorm.DB
	queueMgr     *queue.QueueManager
	logger       *logger.ServiceLogger
	ctx          context.Context
	cancelFunc   context.CancelFunc
}

// NotificationPayload PostgreSQL触发器通知负载
type NotificationPayload struct {
	EventType        string                 `json:"event_type"`
	UserID           string                 `json:"user_id"`
	UserEmail        string                 `json:"user_email"`
	UserPlan         string                 `json:"user_plan"`
	ProductID        string                 `json:"product_id"`
	ProductASIN      string                 `json:"product_asin"`
	NotificationData map[string]interface{} `json:"notification_data"`
	ChangeData       map[string]interface{} `json:"change_data"`
}

// NewPgNotifyListener 创建PostgreSQL通知监听器
func NewPgNotifyListener(dbURL string, db *gorm.DB, queueMgr *queue.QueueManager) (*PgNotifyListener, error) {
	ctx, cancel := context.WithCancel(context.Background())
	
	// 创建PostgreSQL连接 (用于LISTEN)
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		cancel()
		return &fmt.Errorf("failed to connect to PostgreSQL for LISTEN: %w", err), nil
	}

	return &PgNotifyListener{
		conn:       conn,
		db:         db,
		queueMgr:   queueMgr,
		logger:     logger.NewServiceLogger("pg_listener"),
		ctx:        ctx,
		cancelFunc: cancel,
	}, nil
}

// Start 开始监听PostgreSQL通知
func (pnl *PgNotifyListener) Start() error {
	slog.Info("Starting PostgreSQL notification listener")

	// 监听价格警报通道
	if _, err := pnl.conn.Exec(pnl.ctx, "LISTEN price_alerts"); err != nil {
		return fmt.Errorf("failed to listen to price_alerts: %w", err)
	}

	// 监听BSR警报通道
	if _, err := pnl.conn.Exec(pnl.ctx, "LISTEN bsr_alerts"); err != nil {
		return fmt.Errorf("failed to listen to bsr_alerts: %w", err)
	}

	// 启动监听循环
	go pnl.listenLoop()

	slog.Info("PostgreSQL notification listener started",
		"channels", []string{"price_alerts", "bsr_alerts"},
	)

	return nil
}

// listenLoop 监听循环
func (pnl *PgNotifyListener) listenLoop() {
	for {
		select {
		case <-pnl.ctx.Done():
			slog.Info("PostgreSQL listener stopped")
			return
		default:
			// 等待通知，超时时间30秒
			notification, err := pnl.conn.WaitForNotification(context.Background())
			if err != nil {
				// 处理超时和连接错误
				if pgx.Timeout(err) {
					continue // 超时是正常的，继续监听
				}
				
				pnl.logger.LogError(pnl.ctx, "PostgreSQL notification error", "error", err.Error())
				
				// 尝试重连
				if err := pnl.reconnect(); err != nil {
					pnl.logger.LogError(pnl.ctx, "Failed to reconnect to PostgreSQL", "error", err.Error())
					time.Sleep(5 * time.Second)
					continue
				}
			}

			if notification != nil {
				if err := pnl.handleNotification(notification); err != nil {
					pnl.logger.LogError(pnl.ctx, "Failed to handle notification",
						"channel", notification.Channel,
						"error", err.Error(),
					)
				}
			}
		}
	}
}

// handleNotification 处理收到的通知
func (pnl *PgNotifyListener) handleNotification(notification *pgx.Notification) error {
	pnl.logger.LogInfo(pnl.ctx, "Received PostgreSQL notification",
		"channel", notification.Channel,
		"payload_length", len(notification.Payload),
	)

	// 解析通知负载
	var payload NotificationPayload
	if err := json.Unmarshal([]byte(notification.Payload), &payload); err != nil {
		return fmt.Errorf("failed to unmarshal notification payload: %w", err)
	}

	// 根据通知类型处理
	switch notification.Channel {
	case "price_alerts":
		return pnl.handlePriceAlert(payload)
	case "bsr_alerts":
		return pnl.handleBSRAlert(payload)
	default:
		pnl.logger.LogError(pnl.ctx, "Unknown notification channel", "channel", notification.Channel)
		return nil
	}
}

// handlePriceAlert 处理价格警报
func (pnl *PgNotifyListener) handlePriceAlert(payload NotificationPayload) error {
	pnl.logger.LogInfo(pnl.ctx, "Processing price alert",
		"product_asin", payload.ProductASIN,
		"user_id", payload.UserID,
		"change_percentage", payload.ChangeData["change_percentage"],
	)

	// 1. 创建数据库通知记录
	notification := models.Notification{
		UserID:    payload.UserID,
		Type:      payload.EventType,
		Title:     fmt.Sprintf("Price Alert: %s", payload.ProductASIN),
		Message:   payload.NotificationData["message"].(string),
		Severity:  payload.NotificationData["severity"].(string),
		ProductID: &payload.ProductID,
		IsRead:    false,
	}

	// 序列化完整数据
	changeDataBytes, _ := json.Marshal(payload.ChangeData)
	notification.Data = changeDataBytes

	if err := pnl.db.Create(&notification).Error; err != nil {
		return fmt.Errorf("failed to create price alert notification: %w", err)
	}

	// 2. 入队高优先级通知任务 (用于邮件/推送)
	priority := 7 // warning级别
	if payload.NotificationData["severity"] == "critical" {
		priority = 9
	}

	notificationData := map[string]interface{}{
		"notification": payload.NotificationData,
		"change_data":  payload.ChangeData,
		"trigger_type": "postgresql_trigger",
	}

	if err := pnl.queueMgr.EnqueueNotification(payload.UserID, notificationData, priority); err != nil {
		return fmt.Errorf("failed to enqueue price alert notification: %w", err)
	}

	pnl.logger.LogBusinessOperation(pnl.ctx, "price_alert_processed", "notification", notification.ID, "success",
		"product_asin", payload.ProductASIN,
		"change_percentage", payload.ChangeData["change_percentage"],
		"severity", payload.NotificationData["severity"],
	)

	return nil
}

// handleBSRAlert 处理BSR警报
func (pnl *PgNotifyListener) handleBSRAlert(payload NotificationPayload) error {
	pnl.logger.LogInfo(pnl.ctx, "Processing BSR alert",
		"product_asin", payload.ProductASIN,
		"user_id", payload.UserID,
		"change_percentage", payload.ChangeData["change_percentage"],
		"is_improvement", payload.ChangeData["is_improvement"],
	)

	// 1. 创建数据库通知记录
	notification := models.Notification{
		UserID:    payload.UserID,
		Type:      payload.EventType,
		Title:     fmt.Sprintf("BSR Alert: %s", payload.ProductASIN),
		Message:   payload.NotificationData["message"].(string),
		Severity:  payload.NotificationData["severity"].(string),
		ProductID: &payload.ProductID,
		IsRead:    false,
	}

	// 序列化完整数据
	changeDataBytes, _ := json.Marshal(payload.ChangeData)
	notification.Data = changeDataBytes

	if err := pnl.db.Create(&notification).Error; err != nil {
		return fmt.Errorf("failed to create BSR alert notification: %w", err)
	}

	// 2. 入队通知任务
	priority := 6 // BSR变化优先级稍低于价格
	if payload.NotificationData["severity"] == "critical" {
		priority = 8
	}

	notificationData := map[string]interface{}{
		"notification": payload.NotificationData,
		"change_data":  payload.ChangeData,
		"trigger_type": "postgresql_trigger",
	}

	if err := pnl.queueMgr.EnqueueNotification(payload.UserID, notificationData, priority); err != nil {
		return fmt.Errorf("failed to enqueue BSR alert notification: %w", err)
	}

	pnl.logger.LogBusinessOperation(pnl.ctx, "bsr_alert_processed", "notification", notification.ID, "success",
		"product_asin", payload.ProductASIN,
		"change_percentage", payload.ChangeData["change_percentage"],
		"is_improvement", payload.ChangeData["is_improvement"],
		"severity", payload.NotificationData["severity"],
	)

	return nil
}

// reconnect 重新连接PostgreSQL
func (pnl *PgNotifyListener) reconnect() error {
	pnl.conn.Close(pnl.ctx)
	
	var err error
	pnl.conn, err = pgx.Connect(pnl.ctx, pnl.conn.Config().ConnString())
	if err != nil {
		return fmt.Errorf("failed to reconnect: %w", err)
	}

	// 重新监听通道
	if _, err := pnl.conn.Exec(pnl.ctx, "LISTEN price_alerts"); err != nil {
		return fmt.Errorf("failed to re-listen to price_alerts: %w", err)
	}

	if _, err := pnl.conn.Exec(pnl.ctx, "LISTEN bsr_alerts"); err != nil {
		return fmt.Errorf("failed to re-listen to bsr_alerts: %w", err)
	}

	slog.Info("PostgreSQL listener reconnected successfully")
	return nil
}

// Stop 停止监听器
func (pnl *PgNotifyListener) Stop() {
	pnl.cancelFunc()
	if pnl.conn != nil {
		pnl.conn.Close(pnl.ctx)
	}
	slog.Info("PostgreSQL notification listener stopped")
}