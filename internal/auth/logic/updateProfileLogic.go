package logic

import (
	"context"

	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type UpdateProfileLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewUpdateProfileLogic(ctx context.Context, svcCtx *svc.ServiceContext) *UpdateProfileLogic {
	return &UpdateProfileLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *UpdateProfileLogic) UpdateProfile(req *types.ProfileUpdateRequest) (resp *types.ProfileUpdateResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
