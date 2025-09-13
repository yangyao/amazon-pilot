package logic

import (
	"context"
	"encoding/json"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetProductDetailsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetProductDetailsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetProductDetailsLogic {
	return &GetProductDetailsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetProductDetailsLogic) GetProductDetails(req *types.GetProductRequest) (resp *types.GetProductResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证用户是否有权限访问这个产品
	var trackedProduct models.TrackedProduct
	err = l.svcCtx.DB.Where("id = ? AND user_id = ?", req.ProductID, userIDStr).First(&trackedProduct).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.ErrNotFound
	} else if err != nil {
		utils.LogError(l.ctx, "Database error when checking product access", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 获取产品详细信息
	var product models.Product
	err = l.svcCtx.DB.Where("id = ?", trackedProduct.ProductID).First(&product).Error
	if err != nil {
		utils.LogError(l.ctx, "Database error when fetching product", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 解析JSON字段
	var images []string
	var bulletPoints []string
	
	if product.Images != nil {
		json.Unmarshal(product.Images, &images)
	}
	if product.BulletPoints != nil {
		json.Unmarshal(product.BulletPoints, &bulletPoints)
	}

	// 获取追踪历史统计
	var priceChanges, bsrChanges, ratingChanges int64
	l.svcCtx.DB.Model(&models.PriceHistory{}).Where("product_id = ?", product.ID).Count(&priceChanges)
	l.svcCtx.DB.Model(&models.RankingHistory{}).Where("product_id = ?", product.ID).Count(&bsrChanges)
	// ratingChanges暂时设为0，实际应该查询rating变化历史

	// 构建响应
	resp = &types.GetProductResponse{
		ID:           product.ID,
		ASIN:         product.ASIN,
		Title:        getStringValue(product.Title),
		Description:  getStringValue(product.Description),
		Brand:        getStringValue(product.Brand),
		Category:     getStringValue(product.Category),
		CurrentPrice: 0.0, // TODO: 从最新价格历史获取
		Currency:     "USD",
		BSR:          0,    // TODO: 从最新排名历史获取
		Rating:       0.0,  // TODO: 从最新排名历史获取
		ReviewCount:  0,    // TODO: 从最新排名历史获取
		Images:       images,
		BulletPoints: bulletPoints,
		TrackingHistory: types.TrackingHistorySummary{
			PriceChanges:  int(priceChanges),
			BSRChanges:    int(bsrChanges),
			RatingChanges: int(ratingChanges),
		},
		Alerts: []types.Alert{}, // TODO: 实现告警逻辑
	}

	// 记录业务日志
	serviceLogger := logger.NewServiceLogger("product")
	serviceLogger.LogBusinessOperation(l.ctx, "get_product_details", "product", product.ID, "success",
		"asin", product.ASIN,
		"tracking_id", trackedProduct.ID,
	)

	return resp, nil
}

// getStringValue 安全获取字符串指针的值
func getStringValue(s *string) string {
	if s != nil {
		return *s
	}
	return ""
}
