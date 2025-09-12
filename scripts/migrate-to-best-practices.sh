#!/bin/bash

# migrate-to-best-practices.sh
# 将项目迁移到 Go 最佳实践结构的脚本

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

# 检查是否在项目根目录
check_project_root() {
    if [[ ! -f "go.mod" ]] || [[ ! -d "internal" ]]; then
        print_error "请在项目根目录执行此脚本"
        exit 1
    fi
    
    if ! grep -q "amazonpilot" go.mod; then
        print_error "这不是 amazon-pilot 项目"
        exit 1
    fi
}

# 创建备份
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="backup_${timestamp}"
    
    print_info "创建备份到 ${backup_dir}"
    
    # 创建备份目录
    mkdir -p "${backup_dir}"
    
    # 备份关键目录和文件
    cp -r internal "${backup_dir}/"
    cp -r docker "${backup_dir}/"
    [[ -f docker-compose.yml ]] && cp docker-compose.yml "${backup_dir}/"
    [[ -d scripts ]] && cp -r scripts "${backup_dir}/"
    
    print_success "备份完成: ${backup_dir}"
    echo "${backup_dir}" > .last_backup
}

# 阶段一：移动 cmd 目录到根目录
phase1_move_cmd() {
    print_info "阶段一：移动 cmd 目录到根目录"
    
    if [[ ! -d "internal/cmd" ]]; then
        print_warning "internal/cmd 目录不存在，跳过"
        return
    fi
    
    if [[ -d "cmd" ]]; then
        print_warning "cmd 目录已存在，跳过移动"
        return
    fi
    
    # 移动目录
    mv internal/cmd cmd
    print_success "已移动 internal/cmd 到 cmd"
    
    # 更新 Dockerfiles
    print_info "更新 Dockerfile 中的路径引用..."
    find docker -name "Dockerfile.*" -type f | while read dockerfile; do
        if grep -q "internal/cmd" "$dockerfile"; then
            sed -i.bak 's|internal/cmd|cmd|g' "$dockerfile"
            rm -f "$dockerfile.bak"
            print_info "已更新: $dockerfile"
        fi
    done
    
    print_success "阶段一完成"
}

# 阶段二：创建共享代码目录结构
phase2_create_shared_dirs() {
    print_info "阶段二：创建共享代码目录结构"
    
    # 创建 internal/pkg 目录
    mkdir -p internal/pkg/{auth,database,queue,logger,config,middleware,errors,utils}
    
    # 创建 pkg 目录 (可导出)
    mkdir -p pkg/{client,types}
    
    # 创建基础的共享代码文件
    
    # database 包
    cat > internal/pkg/database/database.go << 'EOF'
package database

import (
    "gorm.io/gorm"
)

// DB 数据库连接接口
type DB interface {
    GetDB() *gorm.DB
}

// Config 数据库配置
type Config struct {
    DSN             string
    MaxIdleConns    int
    MaxOpenConns    int
    ConnMaxLifetime int
}
EOF

    # logger 包  
    cat > internal/pkg/logger/logger.go << 'EOF'
package logger

import (
    "github.com/zeromicro/go-zero/core/logx"
)

// Logger 统一日志接口
type Logger interface {
    Info(args ...interface{})
    Error(args ...interface{})
    Debug(args ...interface{})
}

// DefaultLogger 默认日志实现
type DefaultLogger struct {
    logger logx.Logger
}

func NewDefaultLogger() *DefaultLogger {
    return &DefaultLogger{
        logger: logx.WithContext(nil),
    }
}

func (l *DefaultLogger) Info(args ...interface{}) {
    l.logger.Info(args...)
}

func (l *DefaultLogger) Error(args ...interface{}) {
    l.logger.Error(args...)
}

func (l *DefaultLogger) Debug(args ...interface{}) {
    l.logger.Info(args...) // go-zero 中使用 Info 作为 Debug
}
EOF

    # config 包
    cat > internal/pkg/config/base.go << 'EOF'
package config

import "github.com/zeromicro/go-zero/rest"

// BaseConfig 基础配置
type BaseConfig struct {
    rest.RestConf
    Database DatabaseConfig
    Redis    RedisConfig  
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
    DSN             string `json:"dsn"`
    MaxIdleConns    int    `json:"maxIdleConns,default=10"`
    MaxOpenConns    int    `json:"maxOpenConns,default=100"`
    ConnMaxLifetime int    `json:"connMaxLifetime,default=3600"`
}

// RedisConfig Redis配置  
type RedisConfig struct {
    Host     string `json:"host"`
    Port     int    `json:"port,default=6379"`
    Password string `json:"password,optional"`
    DB       int    `json:"db,default=0"`
}
EOF

    # errors 包
    cat > internal/pkg/errors/errors.go << 'EOF'
package errors

import (
    "fmt"
    "net/http"
)

// AppError 应用错误
type AppError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}

func (e *AppError) Error() string {
    return fmt.Sprintf("code: %d, message: %s", e.Code, e.Message)
}

// 常用错误
var (
    ErrInternalServer = &AppError{Code: http.StatusInternalServerError, Message: "内部服务器错误"}
    ErrBadRequest     = &AppError{Code: http.StatusBadRequest, Message: "请求参数错误"}
    ErrUnauthorized   = &AppError{Code: http.StatusUnauthorized, Message: "未授权"}
    ErrNotFound       = &AppError{Code: http.StatusNotFound, Message: "资源未找到"}
)

func NewError(code int, message string) *AppError {
    return &AppError{Code: code, Message: message}
}
EOF

    # 创建 pkg/types 的共享类型
    cat > pkg/types/common.go << 'EOF'
package types

// Response 统一响应结构
type Response struct {
    Code    int         `json:"code"`
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}

// PageRequest 分页请求
type PageRequest struct {
    Page     int `json:"page,default=1"`
    PageSize int `json:"pageSize,default=10"`
}

// PageResponse 分页响应
type PageResponse struct {
    Total    int64       `json:"total"`
    Page     int         `json:"page"`
    PageSize int         `json:"pageSize"`
    Data     interface{} `json:"data"`
}
EOF

    print_success "阶段二完成：共享代码目录创建完成"
}

# 阶段三：创建 API 目录
phase3_create_api_dir() {
    print_info "阶段三：创建 API 目录"
    
    # 创建 API 目录
    mkdir -p api/{openapi,proto,docs}
    
    # 移动 .api 文件到统一位置
    print_info "移动 API 定义文件..."
    find internal -name "*.api" -type f | while read api_file; do
        service_name=$(basename $(dirname "$api_file"))
        new_name="${service_name}.api"
        cp "$api_file" "api/openapi/$new_name"
        print_info "已复制 $api_file -> api/openapi/$new_name"
    done
    
    # 创建 API 文档索引
    cat > api/README.md << 'EOF'
# API Definitions

这个目录包含所有服务的 API 定义。

## 目录结构

- `openapi/` - go-zero API 定义文件 (.api)
- `proto/` - Protocol Buffer 定义文件 (如果使用 gRPC)
- `docs/` - 生成的 API 文档

## API 文件说明

- `auth.api` - 认证服务 API
- `product.api` - 产品服务 API  
- `competitor.api` - 竞品分析服务 API
- `optimization.api` - 优化建议服务 API
- `notification.api` - 通知服务 API

## 代码生成

使用项目提供的脚本生成代码：

```bash
./scripts/goctl-monorepo.sh -a api/openapi/auth.api -s auth
```
EOF

    print_success "阶段三完成：API 目录创建完成"
}

# 阶段四：创建部署目录
phase4_create_deployment_dir() {
    print_info "阶段四：创建部署目录"
    
    # 创建部署相关目录
    mkdir -p deployments/{compose,k8s,helm}
    
    # 移动 docker-compose.yml
    if [[ -f "docker-compose.yml" ]]; then
        mv docker-compose.yml deployments/compose/
        print_info "已移动 docker-compose.yml 到 deployments/compose/"
    fi
    
    # 创建 k8s 示例配置
    cat > deployments/k8s/auth-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: auth-service:latest
        ports:
        - containerPort: 8888
        env:
        - name: ENV
          value: "production"
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth-service
  ports:
  - port: 8888
    targetPort: 8888
  type: ClusterIP
EOF

    # 创建部署文档
    cat > deployments/README.md << 'EOF'
# Deployment Configurations

这个目录包含所有部署相关的配置文件。

## 目录结构

- `compose/` - Docker Compose 配置
- `k8s/` - Kubernetes 配置文件
- `helm/` - Helm Charts (如果使用)

## 部署方式

### Docker Compose
```bash
cd deployments/compose
docker-compose up -d
```

### Kubernetes
```bash
kubectl apply -f deployments/k8s/
```
EOF

    print_success "阶段四完成：部署目录创建完成"
}

# 更新构建脚本
update_build_scripts() {
    print_info "更新构建脚本..."
    
    # 更新 goctl-monorepo.sh 脚本以支持新的 API 目录
    if [[ -f "scripts/goctl-monorepo.sh" ]]; then
        # 创建新版本的脚本
        sed 's|internal/\([^/]*\)/\([^.]*\)\.api|api/openapi/\1.api|g' scripts/goctl-monorepo.sh > scripts/goctl-monorepo-new.sh
        mv scripts/goctl-monorepo-new.sh scripts/goctl-monorepo.sh
        chmod +x scripts/goctl-monorepo.sh
        print_info "已更新 goctl-monorepo.sh"
    fi
}

# 更新文档
update_documentation() {
    print_info "更新相关文档..."
    
    # 更新开发指南
    if [[ -f "docs/DEVELOPMENT_GUIDE.md" ]]; then
        sed -i.bak 's|internal/cmd|cmd|g' docs/DEVELOPMENT_GUIDE.md
        sed -i.bak 's|go run internal/cmd|go run cmd|g' docs/DEVELOPMENT_GUIDE.md  
        rm -f docs/DEVELOPMENT_GUIDE.md.bak
        print_info "已更新 DEVELOPMENT_GUIDE.md"
    fi
}

# 验证迁移结果
verify_migration() {
    print_info "验证迁移结果..."
    
    local errors=0
    
    # 检查必要目录是否存在
    local required_dirs=(
        "cmd"
        "internal/pkg" 
        "pkg/types"
        "api/openapi"
        "deployments"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_error "缺少目录: $dir"
            ((errors++))
        fi
    done
    
    # 检查 cmd 目录是否有内容
    if [[ -d "cmd" ]] && [[ -z "$(ls -A cmd)" ]]; then
        print_error "cmd 目录为空"
        ((errors++))
    fi
    
    # 尝试构建一个服务
    if [[ -d "cmd/auth" ]]; then
        print_info "尝试构建 auth 服务..."
        if go build -o /tmp/auth-test ./cmd/auth; then
            print_success "auth 服务构建成功"
            rm -f /tmp/auth-test
        else
            print_error "auth 服务构建失败"
            ((errors++))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "迁移验证通过！"
        return 0
    else
        print_error "迁移验证失败，发现 $errors 个错误"
        return 1
    fi
}

# 回滚函数
rollback() {
    print_warning "开始回滚..."
    
    if [[ ! -f ".last_backup" ]]; then
        print_error "未找到备份信息"
        return 1
    fi
    
    local backup_dir=$(cat .last_backup)
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "备份目录不存在: $backup_dir"
        return 1
    fi
    
    # 恢复备份
    [[ -d "cmd" ]] && rm -rf cmd
    [[ -d "internal" ]] && rm -rf internal
    [[ -d "docker" ]] && rm -rf docker
    [[ -d "api" ]] && rm -rf api
    [[ -d "pkg" ]] && rm -rf pkg  
    [[ -d "deployments" ]] && rm -rf deployments
    
    cp -r "$backup_dir"/* .
    
    print_success "回滚完成"
}

# 主函数
main() {
    local phase=""
    local skip_backup=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --phase)
                phase="$2"
                shift 2
                ;;
            --skip-backup)
                skip_backup=true
                shift
                ;;
            --rollback)
                rollback
                exit $?
                ;;
            --verify)
                verify_migration
                exit $?
                ;;
            -h|--help)
                cat << 'EOF'
使用方法: $0 [OPTIONS]

OPTIONS:
    --phase <1|2|3|4>    只执行指定阶段
    --skip-backup        跳过备份
    --rollback           回滚到最近的备份
    --verify             验证迁移结果
    -h, --help           显示帮助信息

阶段说明:
    1: 移动 cmd 目录到根目录
    2: 创建共享代码目录结构  
    3: 创建 API 目录
    4: 创建部署目录
EOF
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    print_info "开始项目结构迁移..."
    
    # 检查环境
    check_project_root
    
    # 创建备份
    if [[ "$skip_backup" != "true" ]]; then
        create_backup
    fi
    
    # 执行迁移阶段
    case "$phase" in
        "1")
            phase1_move_cmd
            ;;
        "2") 
            phase2_create_shared_dirs
            ;;
        "3")
            phase3_create_api_dir
            ;;
        "4")
            phase4_create_deployment_dir
            ;;
        "")
            # 执行所有阶段
            phase1_move_cmd
            phase2_create_shared_dirs  
            phase3_create_api_dir
            phase4_create_deployment_dir
            update_build_scripts
            update_documentation
            ;;
        *)
            print_error "无效的阶段: $phase"
            exit 1
            ;;
    esac
    
    print_success "迁移完成！"
    
    # 验证结果
    if verify_migration; then
        print_success "🎉 项目结构已成功迁移到最佳实践！"
        print_info "📖 请查看 docs/PROJECT_OPTIMIZATION_RECOMMENDATIONS.md 了解详细信息"
        print_info "🔄 如果遇到问题，可以使用 --rollback 回滚"
    else
        print_error "⚠️  验证失败，建议检查错误后重新运行"
        print_info "🔄 如需回滚，请运行: $0 --rollback"
    fi
}

# 执行主函数
main "$@"