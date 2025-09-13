package logic

import (
	"context"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type RunMaintenanceLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRunMaintenanceLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RunMaintenanceLogic {
	return &RunMaintenanceLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RunMaintenanceLogic) RunMaintenance(req *types.RunMaintenanceRequest) (resp *types.RunMaintenanceResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
