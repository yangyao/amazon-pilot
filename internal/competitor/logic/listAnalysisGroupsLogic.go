package logic

import (
	"context"
	"time"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
)

type ListAnalysisGroupsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListAnalysisGroupsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListAnalysisGroupsLogic {
	return &ListAnalysisGroupsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListAnalysisGroupsLogic) ListAnalysisGroups(req *types.ListAnalysisRequest) (resp *types.ListAnalysisResponse, err error) {
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

	// 查询总数
	var total int64
	if err = query.Model(&models.CompetitorAnalysisGroup{}).Count(&total).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting analysis groups", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 查询分析组列表
	var groups []models.CompetitorAnalysisGroup
	err = query.Preload("MainProduct").
		Preload("Competitors").
		Order("created_at DESC").
		Offset(offset).
		Limit(req.Limit).
		Find(&groups).Error
	if err != nil {
		utils.LogError(l.ctx, "Database error when fetching analysis groups", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 转换为响应格式
	analysisGroups := make([]types.AnalysisGroup, len(groups))
	for i, group := range groups {
		status := "active"
		if !group.IsActive {
			status = "inactive"
		}

		lastAnalysis := ""
		if group.LastAnalysisAt != nil {
			lastAnalysis = group.LastAnalysisAt.Format(time.RFC3339)
		}

		analysisGroups[i] = types.AnalysisGroup{
			ID:              group.ID,
			Name:            group.Name,
			Description:     getStringValue(group.Description),
			MainProductASIN: group.MainProduct.ASIN,
			CompetitorCount: len(group.Competitors),
			Status:          status,
			LastAnalysis:    lastAnalysis,
			CreatedAt:       group.CreatedAt.Format(time.RFC3339),
		}
	}

	// 计算分页信息
	totalPages := int((total + int64(req.Limit) - 1) / int64(req.Limit))

	resp = &types.ListAnalysisResponse{
		Groups: analysisGroups,
		Pagination: types.Pagination{
			Page:       req.Page,
			Limit:      req.Limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	serviceLogger := logger.NewServiceLogger("competitor")
	serviceLogger.LogBusinessOperation(l.ctx, "list_analysis_groups", "competitor_group", "", "success",
		"total_count", total,
		"page", req.Page,
	)

	return resp, nil
}

// getStringValue 安全获取字符串指针值
func getStringValue(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
