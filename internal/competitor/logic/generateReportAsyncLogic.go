package logic

import (
	"context"
	"encoding/json"
	"time"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/tasks"
	"amazonpilot/internal/pkg/utils"

	"github.com/google/uuid"
	"github.com/hibiken/asynq"
	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GenerateReportAsyncLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGenerateReportAsyncLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GenerateReportAsyncLogic {
	return &GenerateReportAsyncLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GenerateReportAsyncLogic) GenerateReportAsync(req *types.GenerateReportAsyncRequest) (resp *types.GenerateReportAsyncResponse, err error) {
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

	// 检查是否已有正在运行的任务
	if !req.Force {
		var existingResult models.CompetitorAnalysisResult
		err = l.svcCtx.DB.Where("analysis_group_id = ? AND status IN (?)", analysisGroup.ID, []string{"processing", "queued"}).
			First(&existingResult).Error
		if err == nil {
			return &types.GenerateReportAsyncResponse{
				TaskID:    existingResult.TaskID,
				Status:    existingResult.Status,
				Message:   "报告生成任务已在进行中，如需重新生成请使用force=true",
				StartedAt: existingResult.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
			}, nil
		}
	}

	// 生成唯一任务ID
	taskID := uuid.New().String()

	// 创建新的分析报告记录
	analysisResult := models.CompetitorAnalysisResult{
		AnalysisGroupID: analysisGroup.ID,
		TaskID:          taskID,
		Status:          "queued",
	}

	if err := l.svcCtx.DB.Create(&analysisResult).Error; err != nil {
		utils.LogError(l.ctx, "Failed to create analysis result", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 准备异步任务载荷
	taskPayload := tasks.GenerateReportPayload{
		AnalysisID:  req.AnalysisID,
		UserID:      userIDStr,
		TaskID:      taskID,
		Force:       req.Force,
		RequestedAt: time.Now().Format("2006-01-02T15:04:05Z07:00"),
	}

	payloadBytes, err := json.Marshal(taskPayload)
	if err != nil {
		// 更新状态为失败
		l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": "Failed to marshal task payload: " + err.Error(),
		})
		return nil, errors.ErrInternalServer
	}

	// 发送异步任务到Redis队列
	task := asynq.NewTask(tasks.TypeGenerateReport, payloadBytes)
	info, err := l.svcCtx.AsynqClient.Enqueue(task)
	if err != nil {
		// 更新状态为失败
		l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
			"status":        "failed",
			"error_message": "Failed to enqueue task: " + err.Error(),
		})
		l.Errorf("Failed to enqueue generate report task: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 更新任务状态为已排队，记录队列ID
	l.svcCtx.DB.Model(&analysisResult).Updates(map[string]interface{}{
		"queue_id": info.ID,
	})

	l.Infof("Successfully enqueued generate report task, task_id: %s, queue_id: %s", taskID, info.ID)

	resp = &types.GenerateReportAsyncResponse{
		TaskID:    taskID,
		Status:    "queued",
		Message:   "竞争定位报告生成任务已提交，请稍后查询状态",
		StartedAt: analysisResult.StartedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// 记录业务日志
	serviceLogger := logger.NewServiceLogger("competitor")
	serviceLogger.LogBusinessOperation(l.ctx, "generate_report_async_submitted", "analysis_group", req.AnalysisID, "success",
		"task_id", taskID,
		"queue_id", info.ID,
		"force", req.Force,
	)

	return resp, nil
}
