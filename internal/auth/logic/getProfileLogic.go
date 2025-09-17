package logic

import (
	"amazonpilot/internal/pkg/constants"
	"amazonpilot/internal/pkg/logger"
	"context"
	"time"

	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetProfileLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetProfileLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetProfileLogic {
	return &GetProfileLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetProfileLogic) GetProfile() (resp *types.ProfileResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 查找用户
	var user models.User
	if err := l.svcCtx.DB.Where("id = ?", userIDStr).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, errors.ErrNotFound
		}
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 构建响应 - 简化版本，无用户设置（按questions.md要求）
	resp = &types.ProfileResponse{
		User: types.User{
			ID:    user.ID,
			Email: user.Email,
			CompanyName: func() string {
				if user.CompanyName != nil {
					return *user.CompanyName
				}
				return ""
			}(),
			Plan:      user.PlanType,
			IsActive:  user.IsActive,
			CreatedAt: user.CreatedAt.Format(time.RFC3339),
		},
	}

	// 使用结构化日志记录业务操作
	logger.GlobalLogger(constants.ServiceAuth).LogBusinessOperation(l.ctx, "get_profile", "user", userIDStr, "success")

	return resp, nil
}
