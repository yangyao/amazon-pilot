package logic

import (
	"context"
	"math"
	"time"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetTrackedProductsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetTrackedProductsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetTrackedProductsLogic {
	return &GetTrackedProductsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetTrackedProductsLogic) GetTrackedProducts(req *types.GetTrackedRequest) (resp *types.GetTrackedResponse, err error) {
	// 从JWT context获取用户ID
	userID := l.ctx.Value("user_id")
	if userID == nil {
		return nil, errors.ErrUnauthorized
	}
	
	userIDStr, ok := userID.(string)
	if !ok {
		return nil, errors.ErrUnauthorized
	}

	// 构建查询
	query := l.svcCtx.DB.Table("tracked_products").
		Select("tracked_products.*, products.asin, products.title, products.brand, products.category").
		Joins("LEFT JOIN products ON tracked_products.product_id = products.id").
		Where("tracked_products.user_id = ?", userIDStr)

	// 应用过滤条件
	if req.Category != "" {
		query = query.Where("products.category LIKE ?", "%"+req.Category+"%")
	}
	if req.Status != "" {
		if req.Status == "active" {
			query = query.Where("tracked_products.is_active = ?", true)
		} else if req.Status == "paused" {
			query = query.Where("tracked_products.is_active = ?", false)
		}
	}

	// 计算总数
	var total int64
	countQuery := query
	if err = countQuery.Count(&total).Error; err != nil {
		l.Errorf("Failed to count tracked products: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 分页参数
	page := req.Page
	if page < 1 {
		page = 1
	}
	limit := req.Limit
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	// 获取分页数据
	var trackedProducts []struct {
		models.TrackedProduct
		ASIN     string  `json:"asin"`
		Title    *string `json:"title"`
		Brand    *string `json:"brand"`
		Category *string `json:"category"`
	}

	err = query.Offset(offset).Limit(limit).Order("tracked_products.created_at DESC").Find(&trackedProducts).Error
	if err != nil {
		l.Errorf("Failed to get tracked products: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 转换为响应格式
	products := make([]types.TrackedProduct, len(trackedProducts))
	for i, tp := range trackedProducts {
		// 这里可以查询最新的价格和BSR数据
		// 暂时使用模拟数据
		products[i] = types.TrackedProduct{
			ID:           tp.ID,
			ASIN:         tp.ASIN,
			Title:        func() string { if tp.Title != nil { return *tp.Title }; return "" }(),
			Alias:        func() string { if tp.Alias != nil { return *tp.Alias }; return "" }(),
			CurrentPrice: 0.0, // TODO: 从最新价格历史获取
			Currency:     "USD",
			BSR:          0,       // TODO: 从最新排名历史获取
			Rating:       0.0,     // TODO: 从最新排名历史获取
			ReviewCount:  0,       // TODO: 从最新排名历史获取
			BuyBoxPrice:  0.0,     // TODO: 从最新价格历史获取
			LastUpdated:  tp.UpdatedAt.Format(time.RFC3339),
			Status:       func() string { if tp.IsActive { return "active" }; return "paused" }(),
		}
	}

	// 计算分页信息
	totalPages := int(math.Ceil(float64(total) / float64(limit)))

	resp = &types.GetTrackedResponse{
		Products: products,
		Pagination: types.Pagination{
			Page:       page,
			Limit:      limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	l.Infof("Retrieved %d tracked products for user %s", len(products), userIDStr)
	return resp, nil
}
