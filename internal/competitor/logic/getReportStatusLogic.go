package logic

import (
	"context"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetReportStatusLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetReportStatusLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetReportStatusLogic {
	return &GetReportStatusLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetReportStatusLogic) GetReportStatus(req *types.GetReportStatusRequest) (resp *types.GetReportStatusResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证分析组是否存在且属于当前用户
	var analysisGroup models.CompetitorAnalysisGroup
	err = l.svcCtx.DB.Where("id = ? AND user_id = ?", req.AnalysisID, userIDStr).
		First(&analysisGroup).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.ErrNotFound
	} else if err != nil {
		utils.LogError(l.ctx, "Database error when fetching analysis group", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 查询最新的分析结果
	var analysisResult models.CompetitorAnalysisResult
	query := l.svcCtx.DB.Where("analysis_group_id = ?", analysisGroup.ID)

	// 如果指定了TaskID，按TaskID查询
	if req.TaskID != "" {
		query = query.Where("task_id = ?", req.TaskID)
	}

	err = query.Order("started_at DESC").First(&analysisResult).Error
	if err == gorm.ErrRecordNotFound {
		return &types.GetReportStatusResponse{
			Status:  "not_found",
			Message: "未找到报告生成记录",
		}, nil
	} else if err != nil {
		utils.LogError(l.ctx, "Database error when fetching analysis result", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 构建响应
	resp = &types.GetReportStatusResponse{
		Status:    analysisResult.Status,
		StartedAt: analysisResult.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// 设置TaskID和ReportID
	if analysisResult.TaskID != "" {
		resp.TaskID = analysisResult.TaskID
	}
	if analysisResult.ID != "" {
		resp.ReportID = analysisResult.ID
	}

	// 根据状态设置不同的信息
	switch analysisResult.Status {
	case "queued":
		resp.Message = "报告生成任务已排队等待处理"
		resp.Progress = 0
	case "processing":
		resp.Message = "正在生成竞争定位报告"
		resp.Progress = 50
	case "completed":
		resp.Message = "竞争定位报告生成完成"
		resp.Progress = 100
		if analysisResult.CompletedAt != nil {
			resp.CompletedAt = analysisResult.CompletedAt.Format("2006-01-02T15:04:05Z07:00")
		}
	case "failed":
		resp.Message = "报告生成失败"
		resp.Progress = 0
		if analysisResult.ErrorMessage != nil {
			resp.ErrorMsg = *analysisResult.ErrorMessage
		}
	default:
		resp.Message = "未知状态"
	}

	l.Infof("Retrieved report status for analysis %s: %s", req.AnalysisID, analysisResult.Status)

	return resp, nil
}
