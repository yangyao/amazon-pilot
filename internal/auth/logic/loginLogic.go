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

type LoginLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewLoginLogic(ctx context.Context, svcCtx *svc.ServiceContext) *LoginLogic {
	return &LoginLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *LoginLogic) Login(req *types.LoginRequest) (resp *types.LoginResponse, err error) {
	// 查找用户
	var user models.User
	if err := l.svcCtx.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, errors.NewError(401, "Invalid email or password")
		}
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 验证密码
	if !user.CheckPassword(req.Password) {
		return nil, errors.NewError(401, "Invalid email or password")
	}

	// 检查用户是否激活
	if !user.IsActive {
		return nil, errors.NewError(403, "Account is deactivated")
	}

	// 生成JWT令牌
	token, err := l.svcCtx.JWTAuth.GenerateToken(user.ID, user.Email, user.PlanType)
	if err != nil {
		l.Errorf("Failed to generate token: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 更新最后登录时间
	now := time.Now()
	user.LastLoginAt = &now
	l.svcCtx.DB.Save(&user)

	// 构建响应
	resp = &types.LoginResponse{
		AccessToken: token,
		TokenType:   "bearer",
		ExpiresIn:   l.svcCtx.Config.Auth.AccessExpire,
		User: types.User{
			ID:          user.ID,
			Email:       user.Email,
			CompanyName: func() string { if user.CompanyName != nil { return *user.CompanyName }; return "" }(),
			Plan:        user.PlanType,
			IsActive:    user.IsActive,
			CreatedAt:   user.CreatedAt.Format(time.RFC3339),
		},
	}

	l.Infof("User %s logged in successfully", user.Email)
	return resp, nil
}
