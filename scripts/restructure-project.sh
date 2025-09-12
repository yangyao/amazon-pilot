#!/bin/bash

# restructure-project.sh  
# 直接重构项目到 Go 最佳实践布局（开发阶段）
# 保持 go-zero 脚手架的便利性

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查环境
check_environment() {
    if [[ ! -f "go.mod" ]] || [[ ! -d "internal" ]]; then
        print_error "请在项目根目录执行此脚本"
        exit 1
    fi
    
    print_info "环境检查通过"
}

# 创建新的目录结构
create_new_structure() {
    print_info "创建新的目录结构..."
    
    # 1. 移动 cmd 到根目录（符合 Go 标准）
    if [[ -d "internal/cmd" ]]; then
        mv internal/cmd cmd
        print_success "✅ 移动 internal/cmd → cmd"
    fi
    
    # 2. 创建共享代码目录
    mkdir -p pkg/{client,types,utils}
    mkdir -p internal/pkg/{auth,database,queue,logger,config,middleware,errors}
    print_success "✅ 创建共享代码目录"
    
    # 3. 创建 API 集中管理目录  
    mkdir -p api/{openapi,proto,docs}
    print_success "✅ 创建 API 管理目录"
    
    # 4. 创建部署配置目录
    mkdir -p deployments/{compose,k8s,helm}
    if [[ -f "docker-compose.yml" ]]; then
        mv docker-compose.yml deployments/compose/
        print_success "✅ 移动 docker-compose.yml → deployments/compose/"
    fi
    
    print_success "目录结构创建完成"
}

# 复制 API 文件到集中位置（保留原文件给 go-zero 使用）
setup_api_management() {
    print_info "设置 API 集中管理..."
    
    # 复制 .api 文件到统一管理位置
    find internal -name "*.api" -type f | while read api_file; do
        service_name=$(basename $(dirname "$api_file"))
        cp "$api_file" "api/openapi/${service_name}.api"
        print_info "📋 复制 $api_file → api/openapi/${service_name}.api"
    done
    
    # 创建 API 管理文档
    cat > api/README.md << 'EOF'
# API Management

## 目录说明

- `openapi/` - 所有服务的 API 定义文件
- `proto/` - Protocol Buffer 定义（如果使用 gRPC）  
- `docs/` - 生成的 API 文档

## 开发流程

1. **修改 API 定义**: 在 `internal/{service}/{service}.api` 中修改
2. **生成代码**: 使用 `./scripts/goctl-monorepo.sh -a ./internal/{service}/{service}.api -s {service}`
3. **同步到集中管理**: API 文件会自动同步到 `api/openapi/`

这样既保持了 go-zero 的便利性，又实现了 API 的集中管理。
EOF
    
    print_success "API 管理设置完成"
}

# 创建共享代码包
create_shared_packages() {
    print_info "创建共享代码包..."
    
    # pkg/types - 公共类型定义
    cat > pkg/types/common.go << 'EOF'
package types

import "time"

// CommonResponse 统一响应结构
type CommonResponse struct {
    Code    int         `json:"code"`
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
    Timestamp int64     `json:"timestamp"`
}

// NewSuccessResponse 创建成功响应
func NewSuccessResponse(data interface{}) *CommonResponse {
    return &CommonResponse{
        Code:      200,
        Message:   "success",
        Data:      data,
        Timestamp: time.Now().Unix(),
    }
}

// NewErrorResponse 创建错误响应
func NewErrorResponse(code int, message string) *CommonResponse {
    return &CommonResponse{
        Code:      code,
        Message:   message,
        Timestamp: time.Now().Unix(),
    }
}

// PageRequest 分页请求
type PageRequest struct {
    Page     int `json:"page,default=1" form:"page"`
    PageSize int `json:"pageSize,default=10" form:"pageSize"`
}

// PageResponse 分页响应
type PageResponse struct {
    Total    int64       `json:"total"`
    Page     int         `json:"page"`
    PageSize int         `json:"pageSize"`
    Items    interface{} `json:"items"`
}
EOF

    # pkg/client - API 客户端
    cat > pkg/client/client.go << 'EOF'
package client

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

// HTTPClient HTTP 客户端接口
type HTTPClient interface {
    Get(url string) (*http.Response, error)
    Post(url string, body io.Reader) (*http.Response, error)
}

// DefaultClient 默认 HTTP 客户端
type DefaultClient struct {
    client  *http.Client
    baseURL string
}

// NewDefaultClient 创建默认客户端
func NewDefaultClient(baseURL string) *DefaultClient {
    return &DefaultClient{
        client: &http.Client{
            Timeout: 30 * time.Second,
        },
        baseURL: baseURL,
    }
}

func (c *DefaultClient) Get(url string) (*http.Response, error) {
    return c.client.Get(c.baseURL + url)
}

func (c *DefaultClient) Post(url string, body io.Reader) (*http.Response, error) {
    return c.client.Post(c.baseURL+url, "application/json", body)
}

// ParseResponse 解析响应
func ParseResponse(resp *http.Response, result interface{}) error {
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("HTTP %d", resp.StatusCode)
    }
    
    return json.NewDecoder(resp.Body).Decode(result)
}
EOF

    # internal/pkg/database - 数据库工具
    cat > internal/pkg/database/database.go << 'EOF'
package database

import (
    "fmt"
    "time"
    
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// Config 数据库配置
type Config struct {
    Host            string `json:"host"`
    Port            int    `json:"port"`
    User            string `json:"user"`
    Password        string `json:"password"`
    Database        string `json:"database"`
    SSLMode         string `json:"sslMode,default=disable"`
    MaxIdleConns    int    `json:"maxIdleConns,default=10"`
    MaxOpenConns    int    `json:"maxOpenConns,default=100"`
    ConnMaxLifetime int    `json:"connMaxLifetime,default=3600"` // seconds
}

// NewConnection 创建数据库连接
func NewConnection(config *Config) (*gorm.DB, error) {
    dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=%s",
        config.Host, config.User, config.Password, config.Database, config.Port, config.SSLMode)
    
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Info),
    })
    if err != nil {
        return nil, err
    }
    
    sqlDB, err := db.DB()
    if err != nil {
        return nil, err
    }
    
    sqlDB.SetMaxIdleConns(config.MaxIdleConns)
    sqlDB.SetMaxOpenConns(config.MaxOpenConns)
    sqlDB.SetConnMaxLifetime(time.Duration(config.ConnMaxLifetime) * time.Second)
    
    return db, nil
}
EOF

    # internal/pkg/logger - 日志工具
    cat > internal/pkg/logger/logger.go << 'EOF'
package logger

import (
    "context"
    
    "github.com/zeromicro/go-zero/core/logx"
)

// Logger 统一日志接口
type Logger interface {
    Info(v ...interface{})
    Infof(format string, v ...interface{})
    Error(v ...interface{})
    Errorf(format string, v ...interface{})
    Debug(v ...interface{})
    Debugf(format string, v ...interface{})
}

// ZeroLogger 基于 go-zero 的日志实现
type ZeroLogger struct {
    logger logx.Logger
}

// NewZeroLogger 创建基于 go-zero 的日志器
func NewZeroLogger(ctx context.Context) *ZeroLogger {
    return &ZeroLogger{
        logger: logx.WithContext(ctx),
    }
}

func (l *ZeroLogger) Info(v ...interface{}) {
    l.logger.Info(v...)
}

func (l *ZeroLogger) Infof(format string, v ...interface{}) {
    l.logger.Infof(format, v...)
}

func (l *ZeroLogger) Error(v ...interface{}) {
    l.logger.Error(v...)
}

func (l *ZeroLogger) Errorf(format string, v ...interface{}) {
    l.logger.Errorf(format, v...)
}

func (l *ZeroLogger) Debug(v ...interface{}) {
    l.logger.Info(v...) // go-zero 中 Debug 级别使用 Info
}

func (l *ZeroLogger) Debugf(format string, v ...interface{}) {
    l.logger.Infof(format, v...)
}
EOF

    # internal/pkg/config - 配置管理  
    cat > internal/pkg/config/base.go << 'EOF'
package config

import (
    "amazonpilot/internal/pkg/database"
    "github.com/zeromicro/go-zero/rest"
)

// BaseConfig 基础配置结构
type BaseConfig struct {
    rest.RestConf
    Database database.Config `json:"database"`
    Redis    RedisConfig     `json:"redis"`
}

// RedisConfig Redis 配置
type RedisConfig struct {
    Host     string `json:"host,default=localhost"`
    Port     int    `json:"port,default=6379"`
    Password string `json:"password,optional"`
    DB       int    `json:"db,default=0"`
}
EOF

    # internal/pkg/errors - 错误处理
    cat > internal/pkg/errors/errors.go << 'EOF'
package errors

import (
    "fmt"
    "net/http"
)

// AppError 应用错误
type AppError struct {
    Code    int         `json:"code"`
    Message string      `json:"message"`
    Details interface{} `json:"details,omitempty"`
}

func (e *AppError) Error() string {
    return fmt.Sprintf("AppError: code=%d, message=%s", e.Code, e.Message)
}

// 预定义错误
var (
    ErrInternalServer = &AppError{Code: http.StatusInternalServerError, Message: "Internal server error"}
    ErrBadRequest     = &AppError{Code: http.StatusBadRequest, Message: "Bad request"}
    ErrUnauthorized   = &AppError{Code: http.StatusUnauthorized, Message: "Unauthorized"}
    ErrForbidden      = &AppError{Code: http.StatusForbidden, Message: "Forbidden"}
    ErrNotFound       = &AppError{Code: http.StatusNotFound, Message: "Not found"}
)

// NewError 创建新错误
func NewError(code int, message string) *AppError {
    return &AppError{Code: code, Message: message}
}

// NewErrorWithDetails 创建带详情的错误
func NewErrorWithDetails(code int, message string, details interface{}) *AppError {
    return &AppError{Code: code, Message: message, Details: details}
}
EOF

    print_success "共享代码包创建完成"
}

# 更新 Dockerfile 路径
update_dockerfiles() {
    print_info "更新 Dockerfile 中的路径..."
    
    find docker -name "Dockerfile.*" -type f | while read dockerfile; do
        if grep -q "internal/cmd" "$dockerfile"; then
            sed -i.bak 's|internal/cmd|cmd|g' "$dockerfile"
            rm -f "$dockerfile.bak"
            print_info "📦 更新: $dockerfile"
        fi
    done
    
    print_success "Dockerfile 更新完成"
}

# 更新 goctl-monorepo.sh 脚本
update_goctl_script() {
    print_info "更新 goctl-monorepo.sh 脚本..."
    
    # 创建增强版的 goctl 脚本，自动同步 API 文件
    cat > scripts/goctl-monorepo-enhanced.sh << 'EOF'
#!/bin/bash

# goctl-monorepo-enhanced.sh
# 增强版 goctl monorepo 脚本，支持最佳实践布局

# 导入原始脚本的核心功能
source "$(dirname "$0")/goctl-monorepo.sh"

# 原始生成函数的增强版
generate_code_enhanced() {
    # 调用原始生成函数
    generate_code "$@"
    
    local SERVICE_NAME="$2"
    
    # 同步 API 文件到集中管理位置
    if [[ -f "./internal/$SERVICE_NAME/$SERVICE_NAME.api" && -d "./api/openapi" ]]; then
        cp "./internal/$SERVICE_NAME/$SERVICE_NAME.api" "./api/openapi/$SERVICE_NAME.api"
        print_info "📋 同步 API 文件到 api/openapi/$SERVICE_NAME.api"
    fi
    
    # 提示使用共享包
    cat << EOF

🎯 代码生成完成！建议在实现业务逻辑时使用共享包:

📦 公共类型:     pkg/types
🔧 工具函数:     pkg/utils  
🔌 API客户端:    pkg/client
🗄️  数据库:      internal/pkg/database
📝 日志:        internal/pkg/logger
⚙️  配置:        internal/pkg/config
❌ 错误处理:     internal/pkg/errors

EOF
}

# 使用增强版函数替换原始函数
generate_code() {
    generate_code_enhanced "$@"
}
EOF

    chmod +x scripts/goctl-monorepo-enhanced.sh
    
    print_success "增强版 goctl 脚本创建完成"
}

# 创建开发便利脚本
create_dev_scripts() {
    print_info "创建开发便利脚本..."
    
    # 服务启动脚本
    cat > scripts/start-service.sh << 'EOF'
#!/bin/bash

# start-service.sh - 快速启动指定服务

if [[ $# -eq 0 ]]; then
    echo "用法: $0 <service-name>"
    echo "可用服务: auth, product, competitor, optimization, notification"
    exit 1
fi

SERVICE=$1

if [[ ! -d "cmd/$SERVICE" ]]; then
    echo "❌ 服务 $SERVICE 不存在"
    exit 1
fi

echo "🚀 启动服务: $SERVICE"
go run "cmd/$SERVICE/main.go" -f "cmd/$SERVICE/etc/$SERVICE-api.yaml"
EOF

    # 构建脚本
    cat > scripts/build-all.sh << 'EOF'
#!/bin/bash

# build-all.sh - 构建所有服务

echo "🏗️  构建所有服务..."

mkdir -p bin

for service_dir in cmd/*; do
    if [[ -d "$service_dir" ]]; then
        service=$(basename "$service_dir")
        echo "📦 构建 $service..."
        go build -o "bin/$service-service" "./$service_dir"
    fi
done

echo "✅ 构建完成，二进制文件在 bin/ 目录"
ls -la bin/
EOF

    # Docker 构建脚本
    cat > scripts/docker-build-all.sh << 'EOF'
#!/bin/bash

# docker-build-all.sh - 构建所有服务的 Docker 镜像

echo "🐳 构建所有 Docker 镜像..."

for dockerfile in docker/Dockerfile.*; do
    if [[ -f "$dockerfile" ]]; then
        service=$(basename "$dockerfile" | sed 's/Dockerfile\.//')
        echo "📦 构建 $service 镜像..."
        docker build -t "$service-service:latest" -f "$dockerfile" .
    fi
done

echo "✅ Docker 镜像构建完成"
docker images | grep "service"
EOF

    chmod +x scripts/{start-service.sh,build-all.sh,docker-build-all.sh}
    
    print_success "开发便利脚本创建完成"
}

# 更新项目文档
update_documentation() {
    print_info "更新项目文档..."
    
    # 更新现有文档中的路径
    find docs -name "*.md" -type f | while read doc; do
        if grep -q "internal/cmd" "$doc"; then
            sed -i.bak 's|internal/cmd|cmd|g' "$doc"
            sed -i.bak 's|go run internal/cmd|go run cmd|g' "$doc"
            rm -f "$doc.bak"
            print_info "📝 更新: $doc"
        fi
    done
    
    # 创建新的项目结构说明
    cat > docs/PROJECT_STRUCTURE.md << 'EOF'
# 项目结构说明

## 目录布局

```
amazon-pilot/
├── cmd/                      # 🚀 应用程序入口点（符合Go标准）
│   ├── auth/                 # 认证服务
│   ├── product/              # 产品服务
│   ├── competitor/           # 竞品分析服务
│   ├── optimization/         # 优化建议服务
│   ├── notification/         # 通知服务
│   ├── worker/               # 后台任务执行器
│   └── scheduler/            # 任务调度器
├── internal/                 # 🔒 私有代码
│   ├── pkg/                  # 🧰 内部共享包
│   │   ├── auth/             # 认证相关工具
│   │   ├── database/         # 数据库工具
│   │   ├── logger/           # 日志工具
│   │   ├── config/           # 配置管理
│   │   ├── errors/           # 错误处理
│   │   └── middleware/       # 中间件
│   ├── auth/                 # 🔐 认证服务 (go-zero生成)
│   ├── product/              # 📦 产品服务 (go-zero生成)
│   ├── competitor/           # 📊 竞品服务 (go-zero生成)
│   ├── optimization/         # 🎯 优化服务 (go-zero生成)
│   └── notification/         # 📨 通知服务 (go-zero生成)
├── pkg/                      # 📚 可导出的公共库
│   ├── client/               # API客户端
│   ├── types/                # 公共类型定义
│   └── utils/                # 工具函数
├── api/                      # 📋 API定义管理
│   ├── openapi/              # go-zero API定义文件
│   ├── proto/                # Protocol Buffer定义
│   └── docs/                 # API文档
├── deployments/              # 🚀 部署配置
│   ├── compose/              # Docker Compose
│   ├── k8s/                  # Kubernetes配置
│   └── helm/                 # Helm Charts
├── docker/                   # 🐳 Docker配置
├── docs/                     # 📖 项目文档
└── scripts/                  # 🔧 工具脚本
```

## 开发流程

### 1. 新增API功能
```bash
# 修改API定义
vim internal/{service}/{service}.api

# 生成代码（保持go-zero便利性）
./scripts/goctl-monorepo-enhanced.sh -a ./internal/{service}/{service}.api -s {service}

# 实现业务逻辑（使用共享包）
vim internal/{service}/logic/{function}Logic.go
```

### 2. 使用共享代码
```go
import (
    "amazonpilot/pkg/types"              // 公共类型
    "amazonpilot/pkg/client"             // API客户端
    "amazonpilot/internal/pkg/database"  // 数据库工具
    "amazonpilot/internal/pkg/logger"    // 日志工具
    "amazonpilot/internal/pkg/errors"    // 错误处理
)
```

### 3. 启动服务
```bash
# 快速启动单个服务
./scripts/start-service.sh auth

# 或直接运行
go run cmd/auth/main.go -f cmd/auth/etc/auth-api.yaml
```

### 4. 构建和部署
```bash
# 构建所有服务
./scripts/build-all.sh

# 构建Docker镜像
./scripts/docker-build-all.sh

# 使用Docker Compose启动
cd deployments/compose && docker-compose up
```

## 设计原则

### ✅ 保持的便利性
- go-zero 脚手架完整功能
- API定义和代码生成流程不变
- 现有服务结构保持兼容

### ✅ 新增的最佳实践
- 符合Go标准项目布局
- 共享代码统一管理
- API集中管理和文档
- 清晰的部署配置结构

### ✅ 开发体验优化
- 便利的开发脚本
- 统一的日志和错误处理
- 可复用的工具包
- 清晰的代码组织

## 注意事项

1. **go-zero生成的代码**: 继续在 `internal/{service}/` 中生成
2. **共享代码**: 新功能尽量使用 `internal/pkg/` 和 `pkg/` 中的工具
3. **API管理**: 修改后会自动同步到 `api/openapi/`
4. **构建路径**: 所有构建脚本已更新为使用 `cmd/` 路径
EOF

    print_success "项目文档更新完成"
}

# 主函数
main() {
    print_info "🚀 开始重构项目结构到最佳实践布局"
    print_info "📋 保持 go-zero 脚手架的便利性"
    
    check_environment
    create_new_structure
    setup_api_management
    create_shared_packages
    update_dockerfiles
    update_goctl_script
    create_dev_scripts
    update_documentation
    
    print_success "🎉 项目重构完成！"
    
    echo ""
    print_info "📖 新的项目结构:"
    print_info "   ├── cmd/              # 应用入口（Go标准）"
    print_info "   ├── pkg/              # 可导出公共库"  
    print_info "   ├── internal/pkg/     # 内部共享包"
    print_info "   ├── internal/{svc}/   # go-zero生成的服务代码"
    print_info "   ├── api/              # API集中管理"
    print_info "   └── deployments/      # 部署配置"
    echo ""
    print_info "🔧 便利脚本:"
    print_info "   ./scripts/start-service.sh auth       # 快速启动服务"
    print_info "   ./scripts/build-all.sh                # 构建所有服务"
    print_info "   ./scripts/goctl-monorepo-enhanced.sh  # 增强版代码生成"
    echo ""
    print_info "📚 查看详细说明: docs/PROJECT_STRUCTURE.md"
}

main "$@"