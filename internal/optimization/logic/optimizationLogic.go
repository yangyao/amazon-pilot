package logic

import (
	"context"

	"amazonpilot/internal/optimization/internal/svc"
	"amazonpilot/internal/optimization/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type OptimizationLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewOptimizationLogic(ctx context.Context, svcCtx *svc.ServiceContext) *OptimizationLogic {
	return &OptimizationLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *OptimizationLogic) Optimization(req *types.Request) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
