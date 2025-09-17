package constants

// ServiceName 定义所有服务名称常量
type ServiceName string

const (
	// ServiceAuth 认证服务
	ServiceAuth ServiceName = "auth"
	
	// ServiceProduct 产品服务
	ServiceProduct ServiceName = "product"
	
	// ServiceCompetitor 竞争对手服务
	ServiceCompetitor ServiceName = "competitor"
	
	// ServiceOptimization 优化服务
	ServiceOptimization ServiceName = "optimization"
	
	// ServiceNotification 通知服务
	ServiceNotification ServiceName = "notification"
	
	// ServiceGateway 网关服务
	ServiceGateway ServiceName = "gateway"
	
	// ServiceWorker 异步任务处理服务
	ServiceWorker ServiceName = "worker"
	
	// ServiceScheduler 调度服务
	ServiceScheduler ServiceName = "scheduler"
	
	// ServiceDashboard 监控面板服务
	ServiceDashboard ServiceName = "dashboard"
)

// String 返回服务名称字符串
func (s ServiceName) String() string {
	return string(s)
}
