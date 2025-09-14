package logic

import (
	"context"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"
	"amazonpilot/internal/pkg/errors"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/utils"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetAnomalyEventsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetAnomalyEventsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetAnomalyEventsLogic {
	return &GetAnomalyEventsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetAnomalyEventsLogic) GetAnomalyEvents(req *types.GetAnomalyEventsRequest) (resp *types.GetAnomalyEventsResponse, err error) {
	// 从JWT context获取用户ID
	userIDStr, err := utils.GetUserIDFromContext(l.ctx)
	if err != nil {
		return nil, err
	}

	// 设置分页参数
	offset := (req.Page - 1) * req.Limit

	// 构建查询条件 - 更新表名为 product_anomaly_events
	query := l.svcCtx.DB.Table("product_anomaly_events ae").
		Select("ae.*, p.title as product_title").
		Joins("INNER JOIN tracked_products tp ON ae.product_id = tp.product_id").
		Joins("INNER JOIN products p ON tp.product_id = p.id").
		Where("tp.user_id = ?", userIDStr)

	// 添加筛选条件
	if req.EventType != "" {
		query = query.Where("ae.event_type = ?", req.EventType)
	}
	if req.Severity != "" {
		query = query.Where("ae.severity = ?", req.Severity)
	}
	if req.ASIN != "" {
		query = query.Where("ae.asin = ?", req.ASIN)
	}

	// 查询总数
	var total int64
	if err := query.Count(&total).Error; err != nil {
		l.Errorf("Failed to count anomaly events: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 查询异常事件列表
	var anomalyEvents []struct {
		models.AnomalyEvent
		ProductTitle string `json:"product_title"`
	}

	if err := query.Order("ae.created_at DESC").
		Offset(offset).
		Limit(req.Limit).
		Scan(&anomalyEvents).Error; err != nil {
		l.Errorf("Failed to query anomaly events: %v", err)
		return nil, errors.ErrInternalServer
	}

	// 转换为响应格式
	events := make([]types.AnomalyEvent, 0, len(anomalyEvents))
	for _, ae := range anomalyEvents {
		event := types.AnomalyEvent{
			ID:               ae.ID,
			ProductID:        ae.ProductID,
			ASIN:             ae.ASIN,
			EventType:        ae.EventType,
			Severity:         ae.Severity,
			CreatedAt:        ae.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			ProductTitle:     ae.ProductTitle,
		}

		// 安全处理指针字段
		if ae.OldValue != nil {
			event.OldValue = *ae.OldValue
		}
		if ae.NewValue != nil {
			event.NewValue = *ae.NewValue
		}
		if ae.ChangePercentage != nil {
			event.ChangePercentage = *ae.ChangePercentage
		}
		if ae.Threshold != nil {
			event.Threshold = *ae.Threshold
		}

		events = append(events, event)
	}

	// 计算总页数
	totalPages := int((total + int64(req.Limit) - 1) / int64(req.Limit))

	resp = &types.GetAnomalyEventsResponse{
		Events: events,
		Pagination: types.Pagination{
			Page:       req.Page,
			Limit:      req.Limit,
			Total:      int(total),
			TotalPages: totalPages,
		},
	}

	l.Infof("Retrieved %d anomaly events for user %s", len(events), userIDStr)
	return resp, nil
}