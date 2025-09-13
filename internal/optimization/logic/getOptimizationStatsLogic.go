package logic

import (
	"context"

	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetOptimizationStatsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetOptimizationStatsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetOptimizationStatsLogic {
	return &GetOptimizationStatsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetOptimizationStatsLogic) GetOptimizationStats() (resp *types.GetStatsResponse, err error) {
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 统计总任务数
	var totalTasks int64
	if err = l.svcCtx.DB.Model(&models.OptimizationAnalysis{}).Where("user_id = ?", userIDStr).Count(&totalTasks).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting total tasks", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 统计待处理任务数
	var pendingTasks int64
	if err = l.svcCtx.DB.Model(&models.OptimizationAnalysis{}).Where("user_id = ? AND status = ?", userIDStr, "pending").Count(&pendingTasks).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting pending tasks", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 统计已完成任务数
	var completedTasks int64
	if err = l.svcCtx.DB.Model(&models.OptimizationAnalysis{}).Where("user_id = ? AND status = ?", userIDStr, "completed").Count(&completedTasks).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting completed tasks", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 计算平均影响分数
	var avgImpactScore float64
	row := l.svcCtx.DB.Table("optimization_suggestions").
		Joins("JOIN optimization_analyses ON optimization_suggestions.analysis_id = optimization_analyses.id").
		Where("optimization_analyses.user_id = ?", userIDStr).
		Select("AVG(optimization_suggestions.impact_score) as avg_score").
		Row()
	
	if err = row.Scan(&avgImpactScore); err != nil {
		// 如果没有数据，默认为0
		avgImpactScore = 0
	}

	resp = &types.GetStatsResponse{
		TotalTasks:         int(totalTasks),
		PendingTasks:       int(pendingTasks),
		CompletedTasks:     int(completedTasks),
		AverageImpactScore: avgImpactScore,
	}

	serviceLogger := logger.NewServiceLogger("optimization")
	serviceLogger.LogBusinessOperation(l.ctx, "get_optimization_stats", "optimization_stats", "", "success",
		"total_tasks", totalTasks,
		"pending_tasks", pendingTasks,
		"completed_tasks", completedTasks,
	)

	return resp, nil
}
