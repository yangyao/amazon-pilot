package logic

import (
	"context"

	"amazonpilot/internal/notification/svc"
	"amazonpilot/internal/notification/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type NotificationLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewNotificationLogic(ctx context.Context, svcCtx *svc.ServiceContext) *NotificationLogic {
	return &NotificationLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *NotificationLogic) Notification(req *types.Request) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
