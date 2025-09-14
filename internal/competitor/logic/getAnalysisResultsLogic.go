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
	resp.MainProduct = types.CompetitorProduct{
		ID:          analysisGroup.MainProduct.ID,
		ASIN:        analysisGroup.MainProduct.ASIN,
		Title:       func() string { if analysisGroup.MainProduct.Title != nil { return *analysisGroup.MainProduct.Title }; return "" }(),
		Brand:       func() string { if analysisGroup.MainProduct.Brand != nil { return *analysisGroup.MainProduct.Brand }; return "" }(),
		Price:       0, // TODO: 从最新价格历史获取
		BSR:         0, // TODO: 从最新排名历史获取
		Rating:      0, // TODO: 从最新排名历史获取
		ReviewCount: 0,
	}

	// 构建竞品信息
	resp.Competitors = make([]types.CompetitorProduct, len(analysisGroup.Competitors))
	for i, comp := range analysisGroup.Competitors {
		resp.Competitors[i] = types.CompetitorProduct{
			ID:          comp.Product.ID,
			ASIN:        comp.Product.ASIN,
			Title:       func() string { if comp.Product.Title != nil { return *comp.Product.Title }; return "" }(),
			Brand:       func() string { if comp.Product.Brand != nil { return *comp.Product.Brand }; return "" }(),
			Price:       0, // TODO: 从最新价格历史获取
			BSR:         0, // TODO: 从最新排名历史获取
			Rating:      0, // TODO: 从最新排名历史获取
			ReviewCount: 0,
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