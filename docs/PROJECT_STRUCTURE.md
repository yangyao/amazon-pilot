# 项目结构说明

## Go 项目最佳实践

### 1. 标准 Go 项目布局

```
amazon-pilot/
├── cmd/                    # 应用程序入口点 (可执行程序)
│   ├── auth/              # 认证服务入口
│   ├── product/           # 产品服务入口
│   ├── competitor/        # 竞品服务入口
│   ├── optimization/      # 优化服务入口
│   ├── notification/      # 通知服务入口
│   ├── worker/            # 后台任务执行器
│   ├── scheduler/         # 任务调度器
│   └── monitor/           # 监控界面
├── internal/              # 私有应用代码 (不可被外部导入)
│   ├── auth/              # 认证服务实现
│   │   ├── internal/      # 服务内部代码
│   │   │   ├── config/    # 配置
│   │   │   ├── handler/   # HTTP 处理器
│   │   │   ├── logic/     # 业务逻辑
│   │   │   ├── svc/       # 服务上下文
│   │   │   └── types/     # 类型定义
│   │   ├── auth.api       # API 定义
│   │   └── etc/           # 配置文件
│   ├── product/           # 产品服务实现
│   ├── competitor/        # 竞品服务实现
│   ├── optimization/      # 优化服务实现
│   ├── notification/      # 通知服务实现
│   └── common/            # 共享代码
├── pkg/                   # 可被外部应用使用的库代码
├── docker/                # Docker 配置文件
├── docs/                  # 文档
├── frontend/              # 前端代码
├── monitoring/            # 监控配置
├── scripts/               # 脚本文件
└── go.mod                 # Go 模块定义
```

### 2. 目录职责说明

#### cmd/ 目录
**用途**: 存放所有可执行程序的入口点
**特点**: 
- 每个子目录包含一个 `main.go` 文件
- 每个子目录对应一个独立的可执行程序
- 不包含业务逻辑，只负责启动和配置

**为什么这样设计**:
- 清晰的入口点管理
- 便于构建和部署
- 符合 Go 社区标准

#### internal/ 目录
**用途**: 存放私有应用代码
**特点**:
- 不可被外部项目导入
- 包含具体的业务逻辑实现
- 按服务模块组织

**为什么这样设计**:
- 防止外部依赖
- 清晰的模块边界
- 便于维护和测试

### 3. 组件类型对比

| 组件类型 | 位置 | 用途 | 特点 |
|----------|------|------|------|
| **微服务** | `cmd/*/main.go` | HTTP API 服务 | 对外提供 REST API |
| **Worker** | `cmd/worker/main.go` | 后台任务执行 | 处理队列中的任务 |
| **Scheduler** | `cmd/scheduler/main.go` | 定时任务调度 | 按时间触发任务 |
| **Monitor** | `cmd/monitor/main.go` | 监控界面 | Web UI 管理界面 |

### 4. 为什么 Worker/Scheduler/Monitor 特殊？

#### 相同点
- 都是独立的可执行程序
- 都有 `main()` 函数作为入口点
- 都需要独立的配置和启动逻辑

#### 不同点
- **微服务**: 提供 HTTP API，处理用户请求
- **Worker**: 处理后台任务，不对外提供 API
- **Scheduler**: 定时调度任务，不对外提供 API
- **Monitor**: 提供 Web UI，用于监控和管理

### 5. 构建和部署

#### 构建命令
```bash
# 构建所有服务
go build -o bin/auth-service ./cmd/auth
go build -o bin/product-service ./cmd/product
go build -o bin/worker-service ./cmd/worker
go build -o bin/scheduler-service ./cmd/scheduler
go build -o bin/monitor-service ./cmd/monitor
```

#### Docker 构建
```dockerfile
# 每个服务都有独立的 Dockerfile
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o auth-service ./cmd/auth
```

### 6. 最佳实践总结

#### ✅ 正确的做法
- 所有 `main()` 函数放在 `cmd/` 目录
- 业务逻辑放在 `internal/` 目录
- 每个可执行程序有独立的目录
- 清晰的模块边界

#### ❌ 避免的做法
- 在 `internal/` 目录放置 `main()` 函数
- 混合业务逻辑和入口点
- 不清晰的模块划分

### 7. 迁移说明

**之前的结构**:
```
internal/
├── auth/
│   └── auth.go          # 包含 main() 函数
└── product/
    └── product.go       # 包含 main() 函数
```

**现在的结构**:
```
cmd/
├── auth/
│   └── main.go          # 只包含 main() 函数
└── product/
    └── main.go          # 只包含 main() 函数

internal/
├── auth/
│   └── internal/        # 只包含业务逻辑
└── product/
    └── internal/        # 只包含业务逻辑
```

这样的结构更符合 Go 社区的最佳实践，也更容易维护和扩展。
