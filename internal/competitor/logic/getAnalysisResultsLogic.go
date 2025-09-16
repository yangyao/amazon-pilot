package logic

import (
	"context"
	"encoding/json"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetAnalysisResultsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetAnalysisResultsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetAnalysisResultsLogic {
	return &GetAnalysisResultsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetAnalysisResultsLogic) GetAnalysisResults(req *types.GetAnalysisRequest) (resp *types.GetAnalysisResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证分析组是否存在且属于当前用户
	var analysisGroup models.CompetitorAnalysisGroup
	err = l.svcCtx.DB.Where("id = ? AND user_id = ?", req.AnalysisID, userIDStr).
		Preload("MainProduct").
		Preload("Competitors.Product").
		First(&analysisGroup).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.ErrNotFound
	} else if err != nil {
		utils.LogError(l.ctx, "Database error when fetching analysis group", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 获取最新的分析报告
	var latestReport models.CompetitorAnalysisResult
	err = l.svcCtx.DB.Where("analysis_group_id = ?", analysisGroup.ID).
		Order("started_at DESC").
		First(&latestReport).Error

	reportStatus := "no_report"
	if err == nil {
		reportStatus = latestReport.Status
	}

	// 构建响应
	resp = &types.GetAnalysisResponse{
		ID:          analysisGroup.ID,
		Name:        analysisGroup.Name,
		Description: func() string { if analysisGroup.Description != nil { return *analysisGroup.Description }; return "" }(),
		Status:      reportStatus,
		LastUpdated: analysisGroup.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// 构建主产品信息
	mainProductData, err := l.getLatestProductData(analysisGroup.MainProduct.ID)
	if err != nil {
		utils.LogError(l.ctx, "Failed to get main product data", "product_id", analysisGroup.MainProduct.ID, "error", err)
		// 使用默认值
		mainProductData = &productData{Price: 0, Currency: "USD", BSR: 0, Rating: 0, ReviewCount: 0}
	}

	resp.MainProduct = types.CompetitorProduct{
		ID:          analysisGroup.MainProduct.ID,
		ASIN:        analysisGroup.MainProduct.ASIN,
		Title:       func() string { if analysisGroup.MainProduct.Title != nil { return *analysisGroup.MainProduct.Title }; return "" }(),
		Brand:       func() string { if analysisGroup.MainProduct.Brand != nil { return *analysisGroup.MainProduct.Brand }; return "" }(),
		Price:       mainProductData.Price,
		BSR:         mainProductData.BSR,
		Rating:      mainProductData.Rating,
		ReviewCount: mainProductData.ReviewCount,
	}

	// 构建竞品信息
	resp.Competitors = make([]types.CompetitorProduct, len(analysisGroup.Competitors))
	for i, comp := range analysisGroup.Competitors {
		competitorData, err := l.getLatestProductData(comp.Product.ID)
		if err != nil {
			utils.LogError(l.ctx, "Failed to get competitor data", "product_id", comp.Product.ID, "asin", comp.Product.ASIN, "error", err)
			// 使用默认值
			competitorData = &productData{Price: 0, Currency: "USD", BSR: 0, Rating: 0, ReviewCount: 0}
		}

		resp.Competitors[i] = types.CompetitorProduct{
			ID:          comp.Product.ID,
			ASIN:        comp.Product.ASIN,
			Title:       func() string { if comp.Product.Title != nil { return *comp.Product.Title }; return "" }(),
			Brand:       func() string { if comp.Product.Brand != nil { return *comp.Product.Brand }; return "" }(),
			Price:       competitorData.Price,
			BSR:         competitorData.BSR,
			Rating:      competitorData.Rating,
			ReviewCount: competitorData.ReviewCount,
		}
	}

	// 如果有完成的报告，添加分析和建议
	if err == nil && latestReport.Status == "completed" {
		// 解析建议
		if latestReport.Recommendations != nil {
			var recommendations []types.Recommendation
			if err := json.Unmarshal(latestReport.Recommendations, &recommendations); err == nil {
				resp.Recommendations = recommendations
			}
		}

		// 更新最后分析时间
		if latestReport.CompletedAt != nil {
			resp.LastUpdated = latestReport.CompletedAt.Format("2006-01-02T15:04:05Z07:00")
		}
	}

	// 记录业务日志
	serviceLogger := logger.NewServiceLogger("competitor")
	serviceLogger.LogBusinessOperation(l.ctx, "get_analysis_results", "analysis_group", req.AnalysisID, "success",
		"status", reportStatus,
		"competitor_count", len(analysisGroup.Competitors),
	)

	return resp, nil
}

// productData 产品数据结构（本地定义）
type productData struct {
	Price       float64
	Currency    string
	BSR         int
	Rating      float64
	ReviewCount int
}

// getLatestProductData 获取产品的最新数据（价格、BSR、评分等）
func (l *GetAnalysisResultsLogic) getLatestProductData(productID string) (*productData, error) {
	// 获取最新价格数据
	var latestPrice models.PriceHistory
	err := l.svcCtx.DB.Where("product_id = ?", productID).
		Order("recorded_at DESC").
		First(&latestPrice).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	// 获取最新排名数据
	var latestRanking models.RankingHistory
	err = l.svcCtx.DB.Where("product_id = ?", productID).
		Order("recorded_at DESC").
		First(&latestRanking).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	data := &productData{
		Price:       latestPrice.Price,
		Currency:    latestPrice.Currency,
		ReviewCount: latestRanking.ReviewCount,
	}

	// 安全设置BSR和Rating
	if latestRanking.BSRRank != nil {
		data.BSR = *latestRanking.BSRRank
	}
	if latestRanking.Rating != nil {
		data.Rating = *latestRanking.Rating
	}

	return data, nil
}