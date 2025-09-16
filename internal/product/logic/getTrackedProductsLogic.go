package logic

import (
	"context"
	"encoding/json"
	"time"

	"amazonpilot/internal/pkg/cache"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"

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

	// 转换为响应格式，使用按产品缓存
	products := make([]types.TrackedProduct, 0, len(trackedProducts))
	for _, tp := range trackedProducts {
		status := "inactive"
		if tp.IsActive {
			status = "active"
		}

		productIDStr := tp.ProductID

		// 尝试从缓存获取产品完整数据
		productCacheKey := cache.ProductDataKey(productIDStr)
		cachedProductData, err := l.svcCtx.RedisClient.Get(l.ctx, productCacheKey).Result()

		var product types.TrackedProduct

		if err == nil && cachedProductData != "" && tp.Product.Title != nil {
			// 缓存命中，直接使用缓存数据
			if unmarshalErr := json.Unmarshal([]byte(cachedProductData), &product); unmarshalErr == nil {
				// 更新追踪相关字段
				product.ID = tp.ID
				if tp.Alias != nil {
					product.Alias = *tp.Alias
				}
				product.Status = status
				products = append(products, product)
				continue
			}
		}

		// 缓存未命中，从数据库获取数据
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

		// 安全获取产品的其他字段
		brand := ""
		if tp.Product.Brand != nil {
			brand = *tp.Product.Brand
		}

		category := ""
		if tp.Product.Category != nil {
			category = *tp.Product.Category
		}

		description := ""
		if tp.Product.Description != nil {
			description = *tp.Product.Description
		}

		// 解析 images 和 bullet_points JSON 字段
		var images []string
		if tp.Product.Images != nil {
			json.Unmarshal(tp.Product.Images, &images)
		}

		var bulletPoints []string
		if tp.Product.BulletPoints != nil {
			json.Unmarshal(tp.Product.BulletPoints, &bulletPoints)
		}

		product = types.TrackedProduct{
			ID:           tp.ID,
			ProductID:    tp.ProductID, // 添加product_id字段用于竞品分析
			ASIN:         tp.Product.ASIN,
			Title:        title,
			Brand:        brand,
			Category:     category,
			Alias:        alias,
			CurrentPrice: latestPrice.Price,
			Currency:     latestPrice.Currency,
			BSR:          0, // 默认值，从排名历史获取
			Rating:       0, // 默认值，从排名历史获取
			ReviewCount:  latestRanking.ReviewCount,
			BuyBoxPrice:  latestPrice.Price, // 使用当前价格作为BuyBox价格
			LastUpdated:  tp.Product.LastUpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
			Status:       status,
			Images:       images,
			Description:  description,
			BulletPoints: bulletPoints,
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

		// 将产品数据缓存到Redis (按产品缓存，TTL: 30分钟)
		if productData, marshalErr := json.Marshal(product); marshalErr == nil {
			l.svcCtx.RedisClient.Set(l.ctx, productCacheKey, productData, 30*time.Minute).Err()
			l.Infof("Cached product data for product %s, TTL: 30 minutes", productIDStr)
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

	l.Infof("Retrieved %d tracked products for user %s", len(products), userIDStr)
	return resp, nil
}
