package logic

import (
	"context"
	"time"

	"amazonpilot/internal/competitor/svc"
	"amazonpilot/internal/competitor/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type CreateAnalysisGroupLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreateAnalysisGroupLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreateAnalysisGroupLogic {
	return &CreateAnalysisGroupLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreateAnalysisGroupLogic) CreateAnalysisGroup(req *types.CreateAnalysisRequest) (resp *types.CreateAnalysisResponse, err error) {
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 验证主产品是否存在
	var mainProduct models.Product
	err = l.svcCtx.DB.Where("id = ?", req.MainProductID).First(&mainProduct).Error
	if err == gorm.ErrRecordNotFound {
		return nil, errors.NewValidationError("Main product not found", []errors.FieldError{
			{Field: "main_product_id", Message: "Product ID does not exist"},
		})
	} else if err != nil {
		utils.LogError(l.ctx, "Database error", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 创建分析组
	analysisGroup := models.CompetitorAnalysisGroup{
		UserID:          userIDStr,
		Name:            req.Name,
		MainProductID:   req.MainProductID,
		UpdateFrequency: req.UpdateFrequency,
		IsActive:        true,
	}

	if req.Description != "" {
		analysisGroup.Description = &req.Description
	}

	if err = l.svcCtx.DB.Create(&analysisGroup).Error; err != nil {
		utils.LogError(l.ctx, "Failed to create analysis group", "error", err)
		return nil, errors.ErrInternalServer
	}

	resp = &types.CreateAnalysisResponse{
		ID:            analysisGroup.ID,
		Name:          analysisGroup.Name,
		MainProductID: analysisGroup.MainProductID,
		Status:        "active",
		CreatedAt:     analysisGroup.CreatedAt.Format(time.RFC3339),
	}

	serviceLogger := logger.NewServiceLogger("competitor")
	serviceLogger.LogBusinessOperation(l.ctx, "create_analysis_group", "competitor_group", analysisGroup.ID, "success",
		"name", req.Name,
		"main_product_id", req.MainProductID,
	)

	return resp, nil
}
