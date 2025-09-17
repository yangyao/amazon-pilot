package logic

import (
	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/utils"
	"context"

	"github.com/zeromicro/go-zero/core/logx"
)

type LogoutLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewLogoutLogic(ctx context.Context, svcCtx *svc.ServiceContext) *LogoutLogic {
	return &LogoutLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *LogoutLogic) Logout() (resp *types.LogoutResponse, err error) {
	// 获取用户ID用于日志记录（可选）
	userIDStr, _ := utils.GetUserIDFromContext(l.ctx)

	// 对于无状态JWT，登出主要是客户端删除token
	// 这里主要记录登出事件
	resp = &types.LogoutResponse{
		Message: "Successfully logged out",
	}

	// 记录登出日志
	logger.GlobalLogger(constants.ServiceAuth).LogBusinessOperation(l.ctx, "logout", "user", userIDStr, "success")

	return resp, nil
}
