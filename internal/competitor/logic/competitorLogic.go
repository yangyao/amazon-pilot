package logic

import (
	"context"

	"amazonpilot/internal/competitor/internal/svc"
	"amazonpilot/internal/competitor/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type CompetitorLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCompetitorLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CompetitorLogic {
	return &CompetitorLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CompetitorLogic) Competitor(req *types.Request) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
