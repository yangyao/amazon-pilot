package logic

import (
	"context"
	"time"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type HealthLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewHealthLogic(ctx context.Context, svcCtx *svc.ServiceContext) *HealthLogic {
	return &HealthLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *HealthLogic) Health() (resp *types.HealthResponse, err error) {
	resp = &types.HealthResponse{
		Service: "ops-api",
		Status:  "healthy", 
		Version: "v1.0.0",
		Uptime:  time.Now().Unix(),
	}
	return resp, nil
}
