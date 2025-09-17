package logic

import (
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"context"
	"time"

	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"
	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetProductHistoryLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetProductHistoryLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetProductHistoryLogic {
	return &GetProductHistoryLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetProductHistoryLogic) GetProductHistory(req *types.GetHistoryRequest) (resp *types.GetHistoryResponse, err error) {
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

	// 设置默认参数
	metric := req.Metric
	if metric == "" {
		metric = "price"
	}
	period := req.Period
	if period == "" {
		period = "30d"
	}

	// 计算时间范围
	var startTime time.Time
	switch period {
	case "7d":
		startTime = time.Now().AddDate(0, 0, -7)
	case "30d":
		startTime = time.Now().AddDate(0, 0, -30)
	case "90d":
		startTime = time.Now().AddDate(0, 0, -90)
	default:
		startTime = time.Now().AddDate(0, 0, -30)
	}

	var historyData []types.HistoryData

	// 根据指标类型查询不同的历史数据
	switch metric {
	case "price":
		var priceHistory []models.PriceHistory
		err = l.svcCtx.DB.Where("product_id = ? AND recorded_at >= ?", trackedProduct.ProductID, startTime).
			Order("recorded_at ASC").Find(&priceHistory).Error
		if err != nil {
			utils.LogError(l.ctx, "Failed to get price history", "error", err)
			return nil, errors.ErrInternalServer
		}

		historyData = make([]types.HistoryData, len(priceHistory))
		for i, ph := range priceHistory {
			historyData[i] = types.HistoryData{
				Date:     ph.RecordedAt.Format("2006-01-02"),
				Value:    ph.Price,
				Currency: ph.Currency,
			}
		}

	case "bsr":
		var rankingHistory []models.RankingHistory
		err = l.svcCtx.DB.Where("product_id = ? AND recorded_at >= ? AND bsr_rank IS NOT NULL", trackedProduct.ProductID, startTime).
			Order("recorded_at ASC").Find(&rankingHistory).Error
		if err != nil {
			utils.LogError(l.ctx, "Failed to get BSR history", "error", err)
			return nil, errors.ErrInternalServer
		}

		historyData = make([]types.HistoryData, len(rankingHistory))
		for i, rh := range rankingHistory {
			historyData[i] = types.HistoryData{
				Date:  rh.RecordedAt.Format("2006-01-02"),
				Value: float64(*rh.BSRRank),
			}
		}

	case "rating":
		var rankingHistory []models.RankingHistory
		err = l.svcCtx.DB.Where("product_id = ? AND recorded_at >= ? AND rating IS NOT NULL", trackedProduct.ProductID, startTime).
			Order("recorded_at ASC").Find(&rankingHistory).Error
		if err != nil {
			utils.LogError(l.ctx, "Failed to get rating history", "error", err)
			return nil, errors.ErrInternalServer
		}

		historyData = make([]types.HistoryData, len(rankingHistory))
		for i, rh := range rankingHistory {
			historyData[i] = types.HistoryData{
				Date:  rh.RecordedAt.Format("2006-01-02"),
				Value: *rh.Rating,
			}
		}

	case "review_count":
		var rankingHistory []models.RankingHistory
		err = l.svcCtx.DB.Where("product_id = ? AND recorded_at >= ?", trackedProduct.ProductID, startTime).
			Order("recorded_at ASC").Find(&rankingHistory).Error
		if err != nil {
			utils.LogError(l.ctx, "Failed to get review count history", "error", err)
			return nil, errors.ErrInternalServer
		}

		historyData = make([]types.HistoryData, len(rankingHistory))
		for i, rh := range rankingHistory {
			historyData[i] = types.HistoryData{
				Date:  rh.RecordedAt.Format("2006-01-02"),
				Value: float64(rh.ReviewCount),
			}
		}

	case "buybox":
		var buyboxHistory []models.BuyBoxHistory
		err = l.svcCtx.DB.Where("product_id = ? AND recorded_at >= ? AND winner_price IS NOT NULL", trackedProduct.ProductID, startTime).
			Order("recorded_at ASC").Find(&buyboxHistory).Error
		if err != nil {
			utils.LogError(l.ctx, "Failed to get Buy Box history", "error", err)
			return nil, errors.ErrInternalServer
		}

		historyData = make([]types.HistoryData, len(buyboxHistory))
		for i, bh := range buyboxHistory {
			historyData[i] = types.HistoryData{
				Date:     bh.RecordedAt.Format("2006-01-02"),
				Value:    *bh.WinnerPrice,
				Currency: bh.Currency,
			}
		}

	default:
		return nil, errors.NewValidationError("Invalid metric", []errors.FieldError{
			{Field: "metric", Message: "Metric must be one of: price, bsr, rating, review_count, buybox"},
		})
	}

	resp = &types.GetHistoryResponse{
		ProductID: req.ProductID,
		Metric:    metric,
		Period:    period,
		Data:      historyData,
	}

	// 记录业务日志
	logger.GlobalLogger(constants.ServiceProduct).LogBusinessOperation(l.ctx, "get_product_history", "product", req.ProductID, "success",
		"metric", metric,
		"period", period,
		"data_points", len(historyData))

	return resp, nil
}
