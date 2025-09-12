package logic

import (
	"context"
	"regexp"

	"amazonpilot/internal/auth/svc"
	"amazonpilot/internal/auth/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type RegisterLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRegisterLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RegisterLogic {
	return &RegisterLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RegisterLogic) Register(req *types.RegisterRequest) (resp *types.RegisterResponse, err error) {
	// 验证邮箱格式
	if !isValidEmail(req.Email) {
		return nil, errors.NewError(400, "Invalid email format")
	}

	// 验证密码强度
	if len(req.Password) < 6 {
		return nil, errors.NewError(400, "Password must be at least 6 characters")
	}

	// 验证计划类型
	if req.Plan != "" && req.Plan != "basic" && req.Plan != "premium" && req.Plan != "enterprise" {
		return nil, errors.NewError(400, "Invalid plan type")
	}

	// 检查用户是否已存在
	var existingUser models.User
	err = l.svcCtx.DB.Where("email = ?", req.Email).First(&existingUser).Error
	if err == nil {
		return nil, errors.NewError(409, "User already exists")
	} else if err != gorm.ErrRecordNotFound {
		l.Errorf("Database error: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 创建新用户
	user := models.User{
		Email:         req.Email,
		PlanType:      req.Plan,
		IsActive:      true,
		EmailVerified: false,
	}

	// 设置公司名称
	if req.CompanyName != "" {
		user.CompanyName = &req.CompanyName
	}

	// 设置密码
	if err := user.SetPassword(req.Password); err != nil {
		l.Errorf("Failed to hash password: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 保存用户
	if err := l.svcCtx.DB.Create(&user).Error; err != nil {
		l.Errorf("Failed to create user: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 创建默认用户设置
	userSettings := models.UserSettings{
		UserID:                   user.ID,
		NotificationEmail:        true,
		NotificationPush:         false,
		Timezone:                 "UTC",
		Currency:                 "USD",
		DefaultTrackingFrequency: "daily",
	}

	if err := l.svcCtx.DB.Create(&userSettings).Error; err != nil {
		l.Errorf("Failed to create user settings: %v", err)
		// 不返回错误，因为用户已创建成功
	}

	resp = &types.RegisterResponse{
		Message: "User created successfully",
		UserID:  user.ID,
	}

	l.Infof("User %s registered successfully", user.Email)
	return resp, nil
}

// isValidEmail 验证邮箱格式
func isValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}
