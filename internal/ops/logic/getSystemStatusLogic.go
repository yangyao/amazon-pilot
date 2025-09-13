package logic

import (
	"context"
	"time"

	"amazonpilot/internal/ops/svc"
	"amazonpilot/internal/ops/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetSystemStatusLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetSystemStatusLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetSystemStatusLogic {
	return &GetSystemStatusLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetSystemStatusLogic) GetSystemStatus() (resp *types.SystemStatusResponse, err error) {
	// 通过HTTP调用检查各个微服务状态
	services := []types.ServiceStatus{
		{Name: "auth", Status: "running", Port: 8888, Health: l.checkServiceHealth("http://localhost:8888/auth/health")},
		{Name: "product", Status: "running", Port: 8889, Health: l.checkServiceHealth("http://localhost:8889/product/health")},
		{Name: "competitor", Status: "running", Port: 8890, Health: l.checkServiceHealth("http://localhost:8890/competitor/health")},
		{Name: "optimization", Status: "running", Port: 8891, Health: l.checkServiceHealth("http://localhost:8891/optimization/health")},
		{Name: "notification", Status: "running", Port: 8892, Health: l.checkServiceHealth("http://localhost:8892/notification/health")},
		{Name: "gateway", Status: "running", Port: 8080, Health: l.checkServiceHealth("http://localhost:8080/health")},
	}

	// 模拟数据库状态 (通过API调用获取，不直接连接数据库)
	dbStatus := types.DatabaseStatus{
		Status:       "healthy",
		Connections:  15,
		TotalTables:  12,
		TotalRecords: 256,
	}
	
	// 模拟Redis状态
	redisStatus := types.RedisStatus{
		Status:      "healthy",
		Memory:      "128MB",
		Keys:        1500,
		Connections: 8,
	}
	
	// 模拟队列状态
	queueStatus := types.QueueStatus{
		Critical: types.QueueInfo{Pending: 2, Active: 1, Completed: 120, Failed: 0},
		Default:  types.QueueInfo{Pending: 8, Active: 3, Completed: 580, Failed: 2},
		Low:      types.QueueInfo{Pending: 15, Active: 2, Completed: 340, Failed: 1},
	}

	resp = &types.SystemStatusResponse{
		Services: services,
		Database: dbStatus,
		Redis:    redisStatus,
		Queue:    queueStatus,
		Uptime:   time.Now().Unix(),
	}

	return resp, nil
}

func (l *GetSystemStatusLogic) checkServiceHealth(url string) string {
	resp, err := l.svcCtx.HTTPClient.Get(url)
	if err != nil {
		return "unhealthy"
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 200 {
		return "healthy"
	}
	return "unhealthy"
}
