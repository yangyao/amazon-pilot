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

	// 创建分析组 (固定daily更新)
	nextAnalysis := time.Now().Add(24 * time.Hour)
	analysisGroup := models.CompetitorAnalysisGroup{
		UserID:         userIDStr,
		Name:           req.Name,
		MainProductID:  req.MainProductID,
		IsActive:       true,
		NextAnalysisAt: &nextAnalysis,
	}

	if req.Description != "" {
		analysisGroup.Description = &req.Description
	}

	// 使用事务创建分析组和竞品关联
	tx := l.svcCtx.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 创建分析组
	if err = tx.Create(&analysisGroup).Error; err != nil {
		tx.Rollback()
		utils.LogError(l.ctx, "Failed to create analysis group", "error", err)
		return nil, errors.ErrInternalServer
	}

	// 创建竞品产品关联记录
	if len(req.CompetitorProductIDs) > 0 {
		competitorProducts := make([]models.CompetitorProduct, len(req.CompetitorProductIDs))
		for i, productID := range req.CompetitorProductIDs {
			// 验证竞品产品是否存在
			var product models.Product
			if err := tx.Where("id = ?", productID).First(&product).Error; err != nil {
				tx.Rollback()
				return nil, errors.NewValidationError("Competitor product not found", []errors.FieldError{
					{Field: "competitor_product_ids", Message: "Product ID " + productID + " does not exist"},
				})
			}

			competitorProducts[i] = models.CompetitorProduct{
				AnalysisGroupID: analysisGroup.ID,
				ProductID:       productID,
			}
		}

		// 批量创建竞品关联
		if err = tx.Create(&competitorProducts).Error; err != nil {
			tx.Rollback()
			utils.LogError(l.ctx, "Failed to create competitor products", "error", err)
			return nil, errors.ErrInternalServer
		}
	}

	// 提交事务
	if err = tx.Commit().Error; err != nil {
		utils.LogError(l.ctx, "Failed to commit transaction", "error", err)
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
