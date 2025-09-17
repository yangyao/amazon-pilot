package logic

import (
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"context"
	"time"

	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type CreateOptimizationTaskLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreateOptimizationTaskLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreateOptimizationTaskLogic {
	return &CreateOptimizationTaskLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreateOptimizationTaskLogic) CreateOptimizationTask(req *types.CreateOptimizationRequest) (resp *types.CreateOptimizationResponse, err error) {
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证产品是否存在
	var product models.Product
	err = l.svcCtx.DB.Where("id = ?", req.ProductID).First(&product).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.NewValidationError("Product not found", []errors.FieldError{
			{Field: "product_id", Message: "Product ID does not exist"},
		})
	} else if err != nil {
		utils.LogError(l.ctx, "Database error", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 创建优化分析记录
	analysis := models.OptimizationAnalysis{
		UserID:       userIDStr,
		ProductID:    req.ProductID,
		AnalysisType: req.OptimizationType,
		Status:       "pending",
	}

	if err = l.svcCtx.DB.Create(&analysis).Error; err != nil {
		utils.LogError(l.ctx, "Failed to create optimization analysis", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 创建初始建议 (模拟AI生成)
	suggestions := []models.OptimizationSuggestion{
		{
			AnalysisID:  analysis.ID,
			Category:    req.OptimizationType,
			Priority:    req.Priority,
			ImpactScore: 8,
			Title:       "AI-Generated: " + req.Title,
			Description: "Based on market analysis, we recommend optimizing this aspect of your product listing.",
		},
	}

	if len(suggestions) > 0 {
		if err = l.svcCtx.DB.Create(&suggestions).Error; err != nil {
			utils.LogError(l.ctx, "Failed to create optimization suggestions", "error", err)
		}
	}

	resp = &types.CreateOptimizationResponse{
		ID:        analysis.ID,
		Title:     req.Title,
		ProductID: req.ProductID,
		Status:    analysis.Status,
		CreatedAt: analysis.StartedAt.Format(time.RFC3339),
	}

	logger.GlobalLogger(constants.ServiceOptimization).LogBusinessOperation(l.ctx, "create_optimization_task", "optimization_task", analysis.ID, "success",
		"title", req.Title,
		"product_id", req.ProductID,
		"type", req.OptimizationType)

	return resp, nil
}
