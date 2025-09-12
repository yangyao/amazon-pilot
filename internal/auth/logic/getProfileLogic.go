package logic

import (
	"context"
	"time"

	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"

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
	// 从go-zero JWT context获取用户ID
	userID := l.ctx.Value("user_id")
	if userID == nil {
		return nil, errors.ErrUnauthorized
	}
	
	userIDStr, ok := userID.(string)
	if !ok {
		return nil, errors.ErrUnauthorized
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

	// 查找用户设置
	var settings models.UserSettings
	if err := l.svcCtx.DB.Where("user_id = ?", userIDStr).First(&settings).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// 如果没有设置，创建默认设置
			settings = models.UserSettings{
				UserID:                   userIDStr,
				NotificationEmail:        true,
				NotificationPush:         false,
				Timezone:                 "UTC",
				Currency:                 "USD",
				DefaultTrackingFrequency: "daily",
			}
			l.svcCtx.DB.Create(&settings)
		} else {
			l.Errorf("Database error when fetching settings: %v", err)
			return nil, errors.ErrInternalServer
		}
	}

	// 构建响应
	resp = &types.ProfileResponse{
		User: types.User{
			ID:          user.ID,
			Email:       user.Email,
			CompanyName: func() string { if user.CompanyName != nil { return *user.CompanyName }; return "" }(),
			Plan:        user.PlanType,
			IsActive:    user.IsActive,
			CreatedAt:   user.CreatedAt.Format(time.RFC3339),
		},
		Settings: types.UserSettings{
			NotificationEmail: settings.NotificationEmail,
			NotificationPush:  settings.NotificationPush,
			Timezone:          settings.Timezone,
			Currency:          settings.Currency,
			TrackingFrequency: settings.DefaultTrackingFrequency,
		},
	}

	l.Infof("User %s profile retrieved successfully", user.Email)
	return resp, nil
}
