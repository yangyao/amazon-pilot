package logic

import (
	"context"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/cache"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type StopProductTrackingLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewStopProductTrackingLogic(ctx context.Context, svcCtx *svc.ServiceContext) *StopProductTrackingLogic {
	return &StopProductTrackingLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *StopProductTrackingLogic) StopProductTracking(req *types.StopTrackingRequest) (resp *types.StopTrackingResponse, err error) {
	// 从JWT context获取用户ID
	userID := l.ctx.Value("user_id")
	if userID == nil {
		return nil, errors.ErrUnauthorized
	}
	
	userIDStr, ok := userID.(string)
	if !ok {
		return nil, errors.ErrUnauthorized
	}

	// 查找追踪记录
	var trackedProduct models.TrackedProduct
	err = l.svcCtx.DB.Where("id = ? AND user_id = ?", req.ProductID, userIDStr).First(&trackedProduct).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.ErrNotFound
	} else if err != nil {
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 删除追踪记录
	if err = l.svcCtx.DB.Delete(&trackedProduct).Error; err != nil {
		l.Errorf("Failed to delete tracking record: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 清除与该产品相关的缓存（按产品缓存）
	productCacheKey := cache.ProductDataKey(trackedProduct.ProductID)
	if err := l.svcCtx.RedisClient.Del(l.ctx, productCacheKey).Err(); err != nil {
		l.Errorf("Failed to clear product data cache for product %s: %v", trackedProduct.ProductID, err)
		// 不影响主流程，继续执行
	} else {
		l.Infof("Cleared product data cache for product %s", trackedProduct.ProductID)
	}

	resp = &types.StopTrackingResponse{
		Message: "Product tracking stopped successfully",
	}

	l.Infof("User %s stopped tracking product %s", userIDStr, req.ProductID)
	return resp, nil
}
