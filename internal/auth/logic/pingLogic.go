package logic

import (
	"context"
	"time"

	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type PingLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewPingLogic(ctx context.Context, svcCtx *svc.ServiceContext) *PingLogic {
	return &PingLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *PingLogic) Ping() (resp *types.PingResponse, err error) {
	resp = &types.PingResponse{
		Status:    "ok",
		Message:   "auth service is running",
		Timestamp: time.Now().Unix(),
	}
	return
}
