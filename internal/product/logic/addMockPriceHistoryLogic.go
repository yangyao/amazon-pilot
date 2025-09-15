package logic

import (
	"context"
	"fmt"
	"time"

	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type AddMockPriceHistoryLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewAddMockPriceHistoryLogic(ctx context.Context, svcCtx *svc.ServiceContext) *AddMockPriceHistoryLogic {
	return &AddMockPriceHistoryLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *AddMockPriceHistoryLogic) AddMockPriceHistory(req *types.AddMockPriceHistoryRequest) (resp *types.AddMockPriceHistoryResponse, err error) {
	// 获取 tracked_product 信息
	var trackedProduct models.TrackedProduct
	if err := l.svcCtx.DB.Where("id = ?", req.TrackedID).First(&trackedProduct).Error; err != nil {
		l.Logger.Error("Failed to find tracked product", logx.Field("tracked_id", req.TrackedID), logx.Field("error", err.Error()))
		return &types.AddMockPriceHistoryResponse{
			Success: false,
			Message: "Tracked product not found",
		}, nil
	}

	// 设置默认货币
	currency := req.Currency
	if currency == "" {
		currency = "USD"
	}

	// 创建模拟价格历史记录
	now := time.Now()
	priceHistory := models.PriceHistory{
		ProductID:   trackedProduct.ProductID,
		Price:       req.Price,
		Currency:    currency,
		BuyBoxPrice: &req.Price,
		RecordedAt:  now,
		DataSource:  "mock", // 标记为模拟数据
	}

	if err := l.svcCtx.DB.Create(&priceHistory).Error; err != nil {
		l.Logger.Error("Failed to create mock price history",
			logx.Field("tracked_id", req.TrackedID),
			logx.Field("product_id", trackedProduct.ProductID),
			logx.Field("price", req.Price),
			logx.Field("error", err.Error()))
		return &types.AddMockPriceHistoryResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to create price history: %v", err),
		}, nil
	}

	l.Logger.Info("Mock price history created successfully",
		logx.Field("tracked_id", req.TrackedID),
		logx.Field("product_id", trackedProduct.ProductID),
		logx.Field("history_id", priceHistory.ID),
		logx.Field("price", req.Price),
		logx.Field("currency", currency))

	return &types.AddMockPriceHistoryResponse{
		Success:   true,
		Message:   "Mock price history added successfully",
		HistoryID: priceHistory.ID,
	}, nil
}
