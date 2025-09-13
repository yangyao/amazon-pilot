package logic

import (
	"context"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type AddCompetitorLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewAddCompetitorLogic(ctx context.Context, svcCtx *svc.ServiceContext) *AddCompetitorLogic {
	return &AddCompetitorLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *AddCompetitorLogic) AddCompetitor(req *types.AddCompetitorRequest) (resp *types.AddCompetitorResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
