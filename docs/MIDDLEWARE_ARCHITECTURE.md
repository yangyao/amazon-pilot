# 中间件架构设计

## 🎯 设计目标

解决中间件在多服务环境中的共享问题，既保持go-zero的便利性，又实现代码复用。

## 🏗️ 架构设计

### 当前问题
- ❌ 中间件只在单个服务中生成 (`internal/auth/middleware/`)
- ❌ 其他服务无法复用限流逻辑
- ❌ 需要在每个服务中重复实现相同功能

### 解决方案：分层中间件架构

```
📦 内部共享包 (实现)
internal/pkg/middleware/
├── ratelimitMiddleware.go    # 🔧 真实的限流实现
├── jwt.go                   # 🔧 JWT认证工具  
└── common.go                # 🔧 通用工具函数

📦 服务专用包 (包装器)
internal/auth/middleware/
└── ratelimitMiddleware.go   # 🎭 包装器，调用共享实现

internal/product/middleware/
└── ratelimitMiddleware.go   # 🎭 包装器，调用共享实现

internal/competitor/middleware/
└── ratelimitMiddleware.go   # 🎭 包装器，调用共享实现
```

## ✅ 优势

### 1. **保持go-zero便利性**
- ✅ API文件中正常声明: `@server(middleware: RateLimitMiddleware)`
- ✅ 自动生成routes.go和导入
- ✅ ServiceContext自动配置

### 2. **实现代码复用**
- ✅ 限流逻辑统一在 `internal/pkg/middleware/`
- ✅ 所有服务共享相同的实现
- ✅ 统一的配置和策略

### 3. **便于维护升级**
- ✅ 修改限流策略只需更新一个地方
- ✅ 新服务自动获得最新实现
- ✅ 测试和调试更集中

## 🔄 开发工作流

### 1. 添加新中间件
```bash
# 1. 在共享包中实现
vim internal/pkg/middleware/newMiddleware.go

# 2. 在API文件中声明
@server(middleware: NewMiddleware)

# 3. 生成代码
./scripts/goctl-centralized.sh -s service_name

# 4. 生成的包装器自动调用共享实现
```

### 2. 跨服务使用
```bash
# 任何服务都可以使用相同的中间件
# product服务
@server(middleware: RateLimitMiddleware)

# competitor服务  
@server(middleware: RateLimitMiddleware)

# 它们都会使用相同的共享实现
```

## 🎭 包装器模式

### 生成的包装器代码
```go
package middleware

import (
    "net/http"
    sharedMiddleware "amazonpilot/internal/pkg/middleware"
)

type RateLimitMiddleware struct {
    shared *sharedMiddleware.RateLimitMiddleware
}

func NewRateLimitMiddleware() *RateLimitMiddleware {
    return &RateLimitMiddleware{
        shared: sharedMiddleware.NewRateLimitMiddleware(),
    }
}

func (m *RateLimitMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
    return m.shared.Handle(next)
}
```

### 共享实现特性
- 🔄 智能限流策略（基于用户计划）
- 📊 完整的限流头部
- 🔐 JWT context集成
- ⚡ 高性能内存实现

## 🚀 future扩展

### 可添加的通用中间件
- **CORS中间件** - 跨域请求处理
- **日志中间件** - 统一请求日志
- **监控中间件** - 性能指标收集
- **安全中间件** - 请求安全检查

### 配置化增强
- 从配置文件读取限流策略
- Redis分布式限流支持
- 动态限流策略调整

## 💡 最佳实践

1. **共享实现，本地包装** - 既复用又符合go-zero规范
2. **配置驱动** - 不同环境不同策略
3. **监控集成** - 限流指标可观测
4. **优雅降级** - 限流失败不影响核心功能

这种架构完美平衡了go-zero的便利性和企业级的代码复用需求！ 🎯