package logic

import (
	"context"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetAnalysisResultsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetAnalysisResultsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetAnalysisResultsLogic {
	return &GetAnalysisResultsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetAnalysisResultsLogic) GetAnalysisResults(req *types.GetAnalysisRequest) (resp *types.GetAnalysisResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
