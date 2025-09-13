package logic

import (
	"context"
	"time"

	"amazonpilot/internal/notification/svc"
	"amazonpilot/internal/notification/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetNotificationsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetNotificationsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetNotificationsLogic {
	return &GetNotificationsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetNotificationsLogic) GetNotifications(req *types.GetNotificationsRequest) (resp *types.GetNotificationsResponse, err error) {
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 分页参数
	offset := (req.Page - 1) * req.Limit
	
	// 构建查询
	query := l.svcCtx.DB.Where("user_id = ?", userIDStr)
	if req.Type != "" {
		query = query.Where("type = ?", req.Type)
	}
	if req.IsRead != "" {
		isRead := req.IsRead == "true"
		query = query.Where("is_read = ?", isRead)
	}

	// 查询总数
	var total int64
	if err = query.Model(&models.Notification{}).Count(&total).Error; err != nil {
		utils.LogError(l.ctx, "Database error when counting notifications", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 查询通知列表
	var notifications []models.Notification
	err = query.Order("created_at DESC").
		Offset(offset).
		Limit(req.Limit).
		Find(&notifications).Error
	if err != nil {
		utils.LogError(l.ctx, "Database error when fetching notifications", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 转换为响应格式
	notificationList := make([]types.Notification, len(notifications))
	for i, notification := range notifications {
		notificationList[i] = types.Notification{
			ID:        notification.ID,
			Type:      notification.Type,
			Title:     notification.Title,
			Message:   notification.Message,
			Severity:  notification.Severity,
			IsRead:    notification.IsRead,
			CreatedAt: notification.CreatedAt.Format(time.RFC3339),
		}
	}

	// 计算分页信息
	totalPages := int((total + int64(req.Limit) - 1) / int64(req.Limit))

	resp = &types.GetNotificationsResponse{
		Notifications: notificationList,
		Pagination: types.Pagination{
			Page:       req.Page,
			Limit:      req.Limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	serviceLogger := logger.NewServiceLogger("notification")
	serviceLogger.LogBusinessOperation(l.ctx, "get_notifications", "notification", "", "success",
		"total_count", total,
		"page", req.Page,
	)

	return resp, nil
}
