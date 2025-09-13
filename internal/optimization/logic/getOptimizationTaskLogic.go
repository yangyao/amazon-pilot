package logic

import (
	"context"

	"amazonpilot/internal/optimization/svc"
	"amazonpilot/internal/optimization/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetOptimizationTaskLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetOptimizationTaskLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetOptimizationTaskLogic {
	return &GetOptimizationTaskLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetOptimizationTaskLogic) GetOptimizationTask(req *types.GetOptimizationRequest) (resp *types.GetOptimizationResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
