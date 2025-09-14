package logic

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/hibiken/asynq"
	"github.com/zeromicro/go-zero/core/logx"
)

type RefreshProductDataLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRefreshProductDataLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RefreshProductDataLogic {
	return &RefreshProductDataLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RefreshProductDataLogic) RefreshProductData(req *types.RefreshProductDataRequest) (resp *types.RefreshProductDataResponse, err error) {
	// 获取用户ID验证权限
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证用户是否追踪这个产品
	var trackedProduct models.TrackedProduct
	if err := l.svcCtx.DB.Where("id = ? AND user_id = ?", req.ProductID, userIDStr).
		Preload("Product").
		First(&trackedProduct).Error; err != nil {
		l.Errorf("Failed to find tracked product: %v", err)
		return nil, errors.ErrNotFound
	}

	// 创建异步任务payload
	taskPayload := map[string]interface{}{
		"product_id":    trackedProduct.ProductID,
		"tracked_id":    trackedProduct.ID,
		"asin":          trackedProduct.Product.ASIN,
		"user_id":       userIDStr,
		"requested_at":  time.Now().Format(time.RFC3339),
	}

	payloadBytes, err := json.Marshal(taskPayload)
	if err != nil {
		l.Errorf("Failed to marshal task payload: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 发送异步任务到Redis队列
	task := asynq.NewTask("refresh_product_data", payloadBytes)
	info, err := l.svcCtx.AsynqClient.Enqueue(task)
	if err != nil {
		l.Errorf("Failed to enqueue refresh task: %v", err)
		return nil, errors.ErrInternalServer
	}

	l.Infof("Enqueued refresh task for ASIN %s, task ID: %s", trackedProduct.Product.ASIN, info.ID)

	// 根据设计文档清理相关缓存，确保下次查询获取最新数据
	go l.invalidateProductCache(trackedProduct.Product.ASIN, trackedProduct.ProductID, userIDStr)

	resp = &types.RefreshProductDataResponse{
		Success: true,
		Message: "Product data refresh task has been queued successfully. Data will be updated in background.",
	}

	// 记录业务操作
	serviceLogger := logger.NewServiceLogger("product")
	serviceLogger.LogBusinessOperation(l.ctx, "refresh_task_queued", "product", trackedProduct.ProductID, "success",
		"asin", trackedProduct.Product.ASIN,
		"task_id", info.ID,
	)

	return resp, nil
}

// invalidateProductCache 根据设计文档清理产品相关缓存
func (l *RefreshProductDataLogic) invalidateProductCache(asin, productID, userID string) {
	ctx := context.Background()

	// 清理产品基本信息缓存
	productCacheKey := fmt.Sprintf("amazon_pilot:product:%s", asin)
	l.svcCtx.RedisClient.Del(ctx, productCacheKey)

	// 清理用户追踪产品列表缓存
	trackedCacheKey := fmt.Sprintf("amazon_pilot:tracked:%s", userID)
	l.svcCtx.RedisClient.Del(ctx, trackedCacheKey)

	// 清理最新价格数据缓存
	priceCacheKey := fmt.Sprintf("amazon_pilot:price:%s:latest", productID)
	l.svcCtx.RedisClient.Del(ctx, priceCacheKey)

	l.Infof("Invalidated cache for ASIN %s, product %s, user %s", asin, productID, userID)
}
