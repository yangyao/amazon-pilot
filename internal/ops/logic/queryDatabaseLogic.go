package logic

import (
	"context"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type QueryDatabaseLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewQueryDatabaseLogic(ctx context.Context, svcCtx *svc.ServiceContext) *QueryDatabaseLogic {
	return &QueryDatabaseLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *QueryDatabaseLogic) QueryDatabase(req *types.DatabaseQueryRequest) (resp *types.DatabaseQueryResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
