package logic

import (
	"context"
	"encoding/json"
	"regexp"
	"strings"
	"time"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/hibiken/asynq"
	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type AddProductTrackingLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewAddProductTrackingLogic(ctx context.Context, svcCtx *svc.ServiceContext) *AddProductTrackingLogic {
	return &AddProductTrackingLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *AddProductTrackingLogic) AddProductTracking(req *types.AddTrackingRequest) (resp *types.AddTrackingResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证ASIN格式
	if !isValidASIN(req.ASIN) {
		return nil, errors.NewValidationError("Invalid ASIN format", []errors.FieldError{
			{Field: "asin", Message: "ASIN must be 10 characters alphanumeric"},
		})
	}

	// 查找或创建产品
	var product models.Product
	err = l.svcCtx.DB.Where("asin = ?", req.ASIN).First(&product).Error
	if err == gorm.ErrRecordNotFound {
		// 产品不存在，创建新产品记录
		product = models.Product{
			ASIN:          req.ASIN,
			Category:      &req.Category,
			FirstSeenAt:   time.Now(),
			LastUpdatedAt: time.Now(),
			DataSource:    "manual",
		}
		
		if err = l.svcCtx.DB.Create(&product).Error; err != nil {
			l.Errorf("Failed to create product: %v", err)
			return nil, errors.ErrInternalServer
		}
		
		l.Infof("Created new product with ASIN: %s", req.ASIN)
	} else if err != nil {
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 检查用户是否已经在追踪这个产品
	var existingTrack models.TrackedProduct
	err = l.svcCtx.DB.Where("user_id = ? AND product_id = ?", userIDStr, product.ID).First(&existingTrack).Error
	if err == nil {
		return nil, errors.NewConflictError("Product is already being tracked")
	} else if err != gorm.ErrRecordNotFound {
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 创建追踪记录
	trackingSettings := req.Settings
	trackedProduct := models.TrackedProduct{
		UserID:                userIDStr,
		ProductID:             product.ID,
		IsActive:              true,
		TrackingFrequency:     "daily", // Fixed at daily per questions.md
		PriceChangeThreshold:  trackingSettings.PriceChangeThreshold,
		BSRChangeThreshold:    trackingSettings.BSRChangeThreshold,
	}

	if req.Alias != "" {
		trackedProduct.Alias = &req.Alias
	}

	// 计算下次检查时间
	nextCheck := calculateNextCheckTime("daily") // Fixed at daily per questions.md
	trackedProduct.NextCheckAt = &nextCheck

	if err = l.svcCtx.DB.Create(&trackedProduct).Error; err != nil {
		l.Errorf("Failed to create tracking record: %v", err)
		return nil, errors.ErrInternalServer
	}

	resp = &types.AddTrackingResponse{
		ProductID:  trackedProduct.ID,
		ASIN:       product.ASIN,
		Status:     "active",
		NextUpdate: nextCheck.Format(time.RFC3339),
	}

	// 🚀 添加产品后立即发送队列任务获取初始数据
	taskPayload := map[string]interface{}{
		"product_id":    product.ID,
		"tracked_id":    trackedProduct.ID,
		"asin":          product.ASIN,
		"user_id":       userIDStr,
		"requested_at":  time.Now().Format(time.RFC3339),
		"initial_fetch": true, // 标记为初始数据获取
	}

	payloadBytes, err := json.Marshal(taskPayload)
	if err != nil {
		l.Errorf("Failed to marshal initial fetch task payload: %v", err)
	} else {
		// 发送初始数据获取任务
		task := asynq.NewTask("refresh_product_data", payloadBytes)
		if info, err := l.svcCtx.AsynqClient.Enqueue(task); err != nil {
			l.Errorf("Failed to enqueue initial data fetch task: %v", err)
		} else {
			l.Infof("Enqueued initial data fetch for new product %s, task ID: %s", product.ASIN, info.ID)
		}
	}

	// 使用结构化日志记录业务操作
	serviceLogger := logger.NewServiceLogger("product")
	serviceLogger.LogBusinessOperation(l.ctx, "add_tracking", "product", product.ID, "success",
		"asin", req.ASIN,
		"alias", req.Alias,
		"frequency", "daily", // Fixed at daily per questions.md
		"initial_fetch_queued", err == nil,
	)

	return resp, nil
}

// isValidASIN 验证ASIN格式
func isValidASIN(asin string) bool {
	if len(asin) != 10 {
		return false
	}
	// ASIN格式：B + 9位字母数字组合
	asinRegex := regexp.MustCompile(`^[B][0-9A-Z]{9}$`)
	return asinRegex.MatchString(strings.ToUpper(asin))
}

// calculateNextCheckTime 计算下次检查时间
func calculateNextCheckTime(frequency string) time.Time {
	now := time.Now()
	switch frequency {
	case "hourly":
		return now.Add(time.Hour)
	case "daily":
		return now.Add(24 * time.Hour)
	case "weekly":
		return now.Add(7 * 24 * time.Hour)
	default:
		return now.Add(24 * time.Hour) // 默认每天
	}
}
