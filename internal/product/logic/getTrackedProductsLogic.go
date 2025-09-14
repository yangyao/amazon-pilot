package logic

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

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
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 根据设计文档，先尝试从Redis缓存获取追踪产品列表
	cacheKey := fmt.Sprintf("amazon_pilot:tracked:%s", userIDStr)
	cachedData, err := l.svcCtx.RedisClient.Get(l.ctx, cacheKey).Result()
	if err == nil && cachedData != "" {
		var cachedResp types.GetTrackedResponse
		if err := json.Unmarshal([]byte(cachedData), &cachedResp); err == nil {
			l.Infof("Retrieved tracked products from cache for user %s", userIDStr)
			return &cachedResp, nil
		}
	}

	// 缓存未命中，从数据库查询
	// 设置分页参数
	offset := (req.Page - 1) * req.Limit

	// 查询用户追踪的产品总数
	var total int64
	if err := l.svcCtx.DB.Table("tracked_products").
		Where("user_id = ?", userIDStr).
		Count(&total).Error; err != nil {
		l.Errorf("Failed to count tracked products: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 查询用户追踪的产品列表，包含最新价格和排名数据
	var trackedProducts []models.TrackedProduct

	if err := l.svcCtx.DB.Where("user_id = ?", userIDStr).
		Preload("Product").
		Offset(offset).
		Limit(req.Limit).
		Order("created_at DESC").
		Find(&trackedProducts).Error; err != nil {
		l.Errorf("Failed to query tracked products: %v", err)
		return nil, errors.ErrInternalServer
	}

	l.Infof("Query result: found %d tracked records for user %s", len(trackedProducts), userIDStr)

	// 转换为响应格式
	products := make([]types.TrackedProduct, 0, len(trackedProducts))
	for _, tp := range trackedProducts {
		status := "inactive"
		if tp.IsActive {
			status = "active"
		}
		
		// 获取最新价格数据
		var latestPrice models.PriceHistory
		l.svcCtx.DB.Where("product_id = ?", tp.ProductID).
			Order("recorded_at DESC").
			First(&latestPrice)
			
		// 获取最新排名数据  
		var latestRanking models.RankingHistory
		l.svcCtx.DB.Where("product_id = ?", tp.ProductID).
			Order("recorded_at DESC").
			First(&latestRanking)
		
		// 安全获取指针字段的值
		title := ""
		if tp.Product.Title != nil {
			title = *tp.Product.Title
		}
		
		alias := ""
		if tp.Alias != nil {
			alias = *tp.Alias
		}
		
		product := types.TrackedProduct{
			ID:           tp.ID,
			ProductID:    tp.ProductID, // 添加product_id字段用于竞品分析
			ASIN:         tp.Product.ASIN,
			Title:        title,
			Alias:        alias,
			CurrentPrice: latestPrice.Price,
			Currency:     latestPrice.Currency,
			BSR:          0, // 默认值，从排名历史获取
			Rating:       0, // 默认值，从排名历史获取
			ReviewCount:  latestRanking.ReviewCount,
			BuyBoxPrice:  latestPrice.Price, // 使用当前价格作为BuyBox价格
			LastUpdated:  tp.Product.LastUpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
			Status:       status,
		}
		
		// 安全设置BSR和Rating
		if latestRanking.BSRRank != nil {
			product.BSR = *latestRanking.BSRRank
		}
		if latestRanking.Rating != nil {
			product.Rating = *latestRanking.Rating
		}
		if latestPrice.BuyBoxPrice != nil {
			product.BuyBoxPrice = *latestPrice.BuyBoxPrice
		}
		
		products = append(products, product)
	}

	// 计算总页数
	totalPages := int((total + int64(req.Limit) - 1) / int64(req.Limit))

	resp = &types.GetTrackedResponse{
		Tracked: products,
		Pagination: types.Pagination{
			Page:       req.Page,
			Limit:      req.Limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	// 根据设计文档将结果缓存到Redis (TTL: 1小时)
	if cacheData, err := json.Marshal(resp); err == nil {
		l.svcCtx.RedisClient.Set(l.ctx, cacheKey, cacheData, time.Hour).Err()
		l.Infof("Cached tracked products for user %s, TTL: 1 hour", userIDStr)
	}

	l.Infof("Retrieved %d real tracked products for user %s", len(products), userIDStr)
	return resp, nil
}
