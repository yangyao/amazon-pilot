package logic

import (
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"context"
	"encoding/json"
	"os"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/llm"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GenerateReportLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGenerateReportLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GenerateReportLogic {
	return &GenerateReportLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GenerateReportLogic) GenerateReport(req *types.GenerateReportRequest) (resp *types.GenerateReportResponse, err error) {
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

	// 检查是否需要生成新报告
	if !req.Force {
		var existingReport models.CompetitorAnalysisResult
		err = l.svcCtx.DB.Where("analysis_group_id = ? AND status = ?", analysisGroup.ID, "completed").
			Order("completed_at DESC").
			First(&existingReport).Error
		if err == nil {
			// 已有完成的报告
			return &types.GenerateReportResponse{
				ReportID:  existingReport.ID,
				Status:    "already_exists",
				Message:   "分析报告已存在，如需重新生成请使用force=true",
				StartedAt: existingReport.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
			}, nil
		}
	}

	// 创建新的分析报告记录
	analysisResult := models.CompetitorAnalysisResult{
		AnalysisGroupID: analysisGroup.ID,
		Status:          "processing",
	}

	if err := l.svcCtx.DB.Create(&analysisResult).Error; err != nil {
		utils.LogError(l.ctx, "Failed to create analysis result", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 强制从环境变量获取OpenAI API Key
	openaiKey := os.Getenv("OPENAI_API_KEY")
	if openaiKey == "" {
		// 更新状态为失败
		l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": "OpenAI API key not configured",
		})
		return nil, errors.NewValidationError("OpenAI API key not configured", []errors.FieldError{
			{Field: "openai_key", Message: "OpenAI API key not configured in service config"},
		})
	}

	// 获取主产品的最新数据
	mainProductData, err := l.getLatestProductData(analysisGroup.MainProduct.ID)
	if err != nil {
		l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": "Failed to fetch main product data: " + err.Error(),
		})
		return nil, errors.ErrInternalServer
	}

	// 准备分析数据
	analysisData := llm.CompetitorAnalysisData{
		MainProduct: llm.ProductData{
			ASIN: analysisGroup.MainProduct.ASIN,
			Title: func() string {
				if analysisGroup.MainProduct.Title != nil {
					return *analysisGroup.MainProduct.Title
				}
				return ""
			}(),
			Price:       mainProductData.Price,
			Currency:    mainProductData.Currency,
			BSR:         mainProductData.BSR,
			Rating:      mainProductData.Rating,
			ReviewCount: mainProductData.ReviewCount,
		},
		Competitors:     make([]llm.ProductData, len(analysisGroup.Competitors)),
		AnalysisMetrics: []string{"price", "bsr", "rating", "features"},
	}

	// 获取竞品数据
	for i, comp := range analysisGroup.Competitors {
		competitorData, err := l.getLatestProductData(comp.Product.ID)
		if err != nil {
			l.Errorf("Failed to get competitor data for %s: %v", comp.Product.ASIN, err)
			// 使用默认数据继续处理
			competitorData = &ProductData{
				Price: 0, Currency: "USD", BSR: 0, Rating: 0, ReviewCount: 0,
			}
		}

		analysisData.Competitors[i] = llm.ProductData{
			ASIN: comp.Product.ASIN,
			Title: func() string {
				if comp.Product.Title != nil {
					return *comp.Product.Title
				}
				return ""
			}(),
			Price:       competitorData.Price,
			Currency:    competitorData.Currency,
			BSR:         competitorData.BSR,
			Rating:      competitorData.Rating,
			ReviewCount: competitorData.ReviewCount,
		}
	}

	// 同步调用DeepSeek生成报告
	client := llm.NewDeepSeekClient(openaiKey)
	report, err := client.GenerateCompetitorReport(l.ctx, analysisData)
	if err != nil {
		// 更新状态为失败
		l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": "Failed to generate LLM report: " + err.Error(),
		})
		return nil, errors.ErrInternalServer
	}

	// 保存分析结果
	analysisDataJSON, _ := json.Marshal(analysisData)
	insightsJSON, _ := json.Marshal(report)
	recommendationsJSON, _ := json.Marshal(report.Recommendations)

	err = l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
		"status":          "completed",
		"analysis_data":   analysisDataJSON,
		"insights":        insightsJSON,
		"recommendations": recommendationsJSON,
		"completed_at":    "NOW()",
	}).Error

	if err != nil {
		utils.LogError(l.ctx, "Failed to save analysis result", "error", err)
		return nil, errors.ErrInternalServer
	}

	resp = &types.GenerateReportResponse{
		ReportID:  analysisResult.ID,
		Status:    "completed",
		Message:   "竞争定位报告生成完成",
		StartedAt: analysisResult.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// 记录业务日志
	logger.GlobalLogger(constants.ServiceCompetitor).LogBusinessOperation(l.ctx, "generate_report_completed", "analysis_group", req.AnalysisID, "success",
		"report_id", analysisResult.ID,
		"competitor_count", len(analysisGroup.Competitors),
		"has_recommendations", len(report.Recommendations))

	return resp, nil
}

// ProductData 产品数据结构
type ProductData struct {
	Price       float64
	Currency    string
	BSR         int
	Rating      float64
	ReviewCount int
}

// getLatestProductData 获取产品的最新数据（价格、BSR、评分等）
func (l *GenerateReportLogic) getLatestProductData(productID string) (*ProductData, error) {
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

	data := &ProductData{
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
