package logic

import (
	"context"
	"time"

	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
)

type ListOptimizationTasksLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListOptimizationTasksLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListOptimizationTasksLogic {
	return &ListOptimizationTasksLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListOptimizationTasksLogic) ListOptimizationTasks(req *types.ListOptimizationRequest) (resp *types.ListOptimizationResponse, err error) {
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 分页参数
	offset := (req.Page - 1) * req.Limit
	
	// 构建查询
	query := l.svcCtx.DB.Where("user_id = ?", userIDStr)
	if req.Status != "" {
		query = query.Where("status = ?", req.Status)
	}
	if req.Priority != "" {
		query = query.Where("suggestions.priority = ?", req.Priority)
	}

	// 查询总数
	var total int64
	if err = query.Model(&models.OptimizationAnalysis{}).Count(&total).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting optimization tasks", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 查询优化任务列表
	var analyses []models.OptimizationAnalysis
	err = query.Preload("Product").
		Preload("Suggestions").
		Order("started_at DESC").
		Offset(offset).
		Limit(req.Limit).
		Find(&analyses).Error
	if err != nil {
		utils.LogError(l.ctx, "Database error when fetching optimization tasks", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 转换为响应格式
	optimizationTasks := make([]types.OptimizationTask, len(analyses))
	for i, analysis := range analyses {
		// 计算平均影响分数
		var avgImpactScore float64
		if len(analysis.Suggestions) > 0 {
			totalScore := 0
			for _, suggestion := range analysis.Suggestions {
				totalScore += suggestion.ImpactScore
			}
			avgImpactScore = float64(totalScore) / float64(len(analysis.Suggestions))
		}

		// 获取优先级
		priority := "medium"
		if len(analysis.Suggestions) > 0 {
			priority = analysis.Suggestions[0].Priority
		}

		updatedAt := ""
		if analysis.CompletedAt != nil {
			updatedAt = analysis.CompletedAt.Format(time.RFC3339)
		}

		optimizationTasks[i] = types.OptimizationTask{
			ID:               analysis.ID,
			Title:            "Optimization Task", // 这里应该从suggestion获取
			Description:      "AI-powered optimization analysis",
			ProductASIN:      analysis.Product.ASIN,
			OptimizationType: analysis.AnalysisType,
			Priority:         priority,
			Status:           analysis.Status,
			ImpactScore:      avgImpactScore,
			EstimatedHours:   2, // 固定估算值
			CreatedAt:        analysis.StartedAt.Format(time.RFC3339),
			UpdatedAt:        updatedAt,
		}
	}

	// 计算分页信息
	totalPages := int((total + int64(req.Limit) - 1) / int64(req.Limit))

	resp = &types.ListOptimizationResponse{
		Tasks: optimizationTasks,
		Pagination: types.Pagination{
			Page:       req.Page,
			Limit:      req.Limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	serviceLogger := logger.NewServiceLogger("optimization")
	serviceLogger.LogBusinessOperation(l.ctx, "list_optimization_tasks", "optimization_task", "", "success",
		"total_count", total,
		"page", req.Page,
	)

	return resp, nil
}
