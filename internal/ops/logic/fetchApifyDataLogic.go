package logic

import (
	"context"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type FetchApifyDataLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewFetchApifyDataLogic(ctx context.Context, svcCtx *svc.ServiceContext) *FetchApifyDataLogic {
	return &FetchApifyDataLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *FetchApifyDataLogic) FetchApifyData(req *types.ApifyFetchRequest) (resp *types.ApifyFetchResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
