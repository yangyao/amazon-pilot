# Go Monorepo 项目结构

## 最佳实践结构

### 1. 标准 Go Monorepo 布局

```
amazon-pilot/
├── internal/              # 私有应用代码
│   ├── cmd/              # 应用程序入口点 (在 internal 下)
│   │   ├── auth/         # 认证服务入口
│   │   │   ├── main.go   # 认证服务 main 函数
│   │   │   └── etc/      # 配置文件
│   │   │       └── auth-api.yaml
│   │   ├── product/      # 产品服务入口
│   │   │   ├── main.go
│   │   │   └── etc/
│   │   │       └── product-api.yaml
│   │   ├── competitor/   # 竞品服务入口
│   │   ├── optimization/ # 优化服务入口
│   │   ├── notification/ # 通知服务入口
│   │   ├── worker/       # 后台任务执行器
│   │   ├── scheduler/    # 任务调度器
│   │   └── monitor/      # 监控界面
│   ├── auth/             # 认证服务业务逻辑 (保留用于 go-zero 代码生成)
│   │   ├── internal/     # 服务内部实现 (保留用于 go-zero 代码生成)
│   │   │   ├── config/   # 配置结构
│   │   │   ├── handler/  # HTTP 处理器
│   │   │   ├── logic/    # 业务逻辑
│   │   │   ├── svc/      # 服务上下文
│   │   │   └── types/    # 类型定义
│   │   └── auth.api      # API 定义
│   ├── product/          # 产品服务业务逻辑 (保留用于 go-zero 代码生成)
│   ├── competitor/       # 竞品服务业务逻辑 (保留用于 go-zero 代码生成)
│   ├── optimization/     # 优化服务业务逻辑 (保留用于 go-zero 代码生成)
│   ├── notification/     # 通知服务业务逻辑 (保留用于 go-zero 代码生成)
│   └── common/           # 共享代码
├── pkg/                  # 可被外部应用使用的库代码
│   ├── auth/             # 认证服务共享代码
│   │   ├── config/       # 配置结构
│   │   ├── handler/      # HTTP 处理器
│   │   ├── logic/        # 业务逻辑
│   │   ├── svc/          # 服务上下文
│   │   └── types/        # 类型定义
│   ├── product/          # 产品服务共享代码
│   ├── competitor/       # 竞品服务共享代码
│   ├── optimization/     # 优化服务共享代码
│   └── notification/     # 通知服务共享代码
├── docker/               # Docker 配置文件
├── docs/                 # 文档
├── frontend/             # 前端代码
├── monitoring/           # 监控配置
├── scripts/              # 脚本文件
└── go.mod                # Go 模块定义
```

### 2. 为什么使用 pkg 目录？

#### 优势
- **包导入无问题**: `internal/cmd/auth/main.go` 可以导入 `pkg/auth/config`
- **符合 Go 最佳实践**: pkg 目录是 Go 社区推荐的可导入包位置
- **清晰的边界**: 可导入代码在 pkg 下，私有代码在 internal 下
- **避免循环依赖**: 防止包导入的复杂性

#### 包导入规则
```go
// internal/cmd/auth/main.go 可以导入:
import (
    "amazonpilot/pkg/auth/config"   // ✅ 可以
    "amazonpilot/pkg/auth/handler"  // ✅ 可以
    "amazonpilot/pkg/auth/svc"      // ✅ 可以
)

// 外部项目也可以导入 pkg 下的包
// 但无法导入 internal 下的任何包
```

### 3. 目录职责说明

#### internal/cmd/ 目录
**用途**: 存放所有可执行程序的入口点
**特点**:
- 每个子目录包含一个 `main.go` 文件
- 每个子目录对应一个独立的可执行程序
- 可以导入同项目下的 internal 包
- 配置文件跟随服务

#### internal/{service}/ 目录
**用途**: 保留 go-zero 代码生成的结构
**特点**:
- 包含 go-zero 生成的代码
- 按服务模块组织
- 主要用于代码生成，不直接使用

#### pkg/{service}/ 目录
**用途**: 存放各服务的可导入业务逻辑
**特点**:
- 包含具体的业务逻辑实现
- 可以被 cmd 目录导入
- 可以被外部项目导入
- 按服务模块组织

### 4. 构建和部署

#### 构建命令
```bash
# 构建所有服务
go build -o bin/auth-service ./internal/cmd/auth
go build -o bin/product-service ./internal/cmd/product
go build -o bin/worker-service ./internal/cmd/worker
go build -o bin/scheduler-service ./internal/cmd/scheduler
go build -o bin/monitor-service ./internal/cmd/monitor
```

#### Docker 构建
```dockerfile
# 每个服务都有独立的 Dockerfile
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o auth-service ./internal/cmd/auth
```

#### 开发环境运行
```bash
# 启动认证服务
go run internal/cmd/auth/main.go -f internal/cmd/auth/etc/auth-api.yaml

# 启动产品服务
go run internal/cmd/product/main.go -f internal/cmd/product/etc/product-api.yaml
```

### 5. 配置文件组织

#### 服务配置文件
- **位置**: `internal/cmd/{service}/etc/{service}-api.yaml`
- **用途**: 服务启动配置
- **内容**: 端口、数据库连接、Redis 配置等

#### 环境配置文件
- **位置**: 项目根目录
- **文件**: `.env`, `env.example`
- **用途**: 环境变量配置

### 6. 与标准 Go 项目的区别

| 方面 | 标准 Go 项目 | Go Monorepo |
|------|-------------|-------------|
| **cmd 位置** | `cmd/` | `internal/cmd/` |
| **包导入** | 可能有问题 | 无问题 |
| **适用场景** | 单一应用 | 多服务应用 |
| **复杂度** | 简单 | 中等 |

### 7. 优势总结

#### ✅ 包导入无问题
- `internal/cmd/auth/main.go` 可以正常导入 `internal/auth/internal/config`
- 避免了 "Use of the internal package is not allowed" 错误

#### ✅ 符合 Monorepo 实践
- 大型项目通常采用这种结构
- 便于管理多个相关服务

#### ✅ 清晰的模块边界
- 所有应用代码在 `internal/` 下
- 可复用代码在 `pkg/` 下
- 配置文件跟随服务

#### ✅ 便于维护和扩展
- 新增服务只需在 `internal/cmd/` 和 `internal/{service}/` 下添加
- 清晰的目录结构便于理解

### 8. 迁移完成

✅ **目录结构已更新**:
- `cmd/` → `internal/cmd/`
- 业务逻辑代码复制到 `pkg/` 目录
- 所有配置文件路径已更新
- 所有 Dockerfile 已更新

✅ **包导入问题已解决**:
- `internal/cmd/auth/main.go` 可以正常导入 `pkg/auth/config`
- 不再有 "Use of the internal package is not allowed" 错误
- 所有服务都可以正常构建

✅ **符合 Go Monorepo 最佳实践**:
- 遵循 Go 社区推荐的 pkg 目录使用方式
- 便于维护和扩展
- 支持外部项目导入

### 9. 工作流程

#### 开发新功能
1. 在 `internal/{service}/` 目录下使用 go-zero 工具生成代码
2. 将生成的代码复制到 `pkg/{service}/` 目录
3. 在 `internal/cmd/{service}/main.go` 中导入 `pkg/{service}/` 包
4. 测试构建和运行

#### 代码生成
```bash
# 生成认证服务代码
goctl api go -api internal/auth/auth.api -dir internal/auth/

# 复制到 pkg 目录
cp -r internal/auth/internal/* pkg/auth/

# 更新包导入路径
find pkg -name "*.go" -exec sed -i '' 's|amazonpilot/internal/\([^/]*\)/internal/|amazonpilot/pkg/\1/|g' {} \;
```

这样的结构更适合你的 Monorepo 项目，解决了包导入的问题，同时保持了清晰的模块边界。
