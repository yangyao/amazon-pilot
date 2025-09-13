package logic

import (
	"context"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type RestartServiceLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRestartServiceLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RestartServiceLogic {
	return &RestartServiceLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RestartServiceLogic) RestartService(req *types.RestartServiceRequest) (resp *types.RestartServiceResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
