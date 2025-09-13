package logic

import (
	"context"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetLogsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetLogsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetLogsLogic {
	return &GetLogsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetLogsLogic) GetLogs(req *types.GetLogsRequest) (resp *types.GetLogsResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
