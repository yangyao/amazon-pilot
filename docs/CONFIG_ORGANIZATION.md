# 配置文件组织说明

## 配置文件迁移

### 1. 迁移原因

**之前的结构**:
```
internal/
├── auth/
│   ├── auth.go          # main() 函数
│   └── etc/
│       └── auth-api.yaml
└── product/
    ├── product.go       # main() 函数
    └── etc/
        └── product-api.yaml
```

**问题**:
- `main()` 函数在 `internal/` 目录
- 配置文件也在 `internal/` 目录
- 不符合 Go 项目最佳实践

**现在的结构**:
```
cmd/
├── auth/
│   ├── main.go          # main() 函数
│   └── etc/
│       └── auth-api.yaml
└── product/
    ├── main.go          # main() 函数
    └── etc/
        └── product-api.yaml
```

### 2. 配置文件组织原则

#### 原则 1: 配置文件跟随服务
- 每个服务的配置文件放在对应的 `cmd/{service}/etc/` 目录
- 便于独立部署和管理
- 符合微服务设计理念

#### 原则 2: 清晰的职责分离
- `cmd/` - 可执行程序和配置
- `internal/` - 业务逻辑实现
- `pkg/` - 可复用的库代码

### 3. 新的目录结构

```
amazon-pilot/
├── cmd/                    # 可执行程序和配置
│   ├── auth/
│   │   ├── main.go        # 认证服务入口
│   │   └── etc/
│   │       └── auth-api.yaml
│   ├── product/
│   │   ├── main.go        # 产品服务入口
│   │   └── etc/
│   │       └── product-api.yaml
│   ├── competitor/
│   │   ├── main.go        # 竞品服务入口
│   │   └── etc/
│   │       └── competitor-api.yaml
│   ├── optimization/
│   │   ├── main.go        # 优化服务入口
│   │   └── etc/
│   │       └── optimization-api.yaml
│   ├── notification/
│   │   ├── main.go        # 通知服务入口
│   │   └── etc/
│   │       └── notification-api.yaml
│   ├── worker/
│   │   └── main.go        # 后台任务执行器
│   ├── scheduler/
│   │   └── main.go        # 任务调度器
│   └── monitor/
│       └── main.go        # 监控界面
├── internal/              # 业务逻辑实现
│   ├── auth/internal/     # 认证服务逻辑
│   ├── product/internal/  # 产品服务逻辑
│   └── ...
└── ...
```

### 4. 配置文件类型

#### 服务配置文件
- **位置**: `cmd/{service}/etc/{service}-api.yaml`
- **用途**: 服务启动配置
- **内容**: 端口、数据库连接、Redis 配置等

#### 环境配置文件
- **位置**: 项目根目录
- **文件**: `.env`, `env.example`
- **用途**: 环境变量配置
- **内容**: 数据库 URL、API 密钥等

#### 监控配置文件
- **位置**: `monitoring/`
- **文件**: `prometheus.yml`, `alert_rules.yml`
- **用途**: 监控系统配置

### 5. Docker 构建更新

#### 之前的 Dockerfile
```dockerfile
COPY --from=builder /app/internal/auth/etc /app/etc
```

#### 现在的 Dockerfile
```dockerfile
COPY --from=builder /app/cmd/auth/etc /app/etc
```

### 6. 配置文件访问路径

#### 开发环境
```bash
# 启动认证服务
go run cmd/auth/main.go -f cmd/auth/etc/auth-api.yaml

# 启动产品服务
go run cmd/product/main.go -f cmd/product/etc/product-api.yaml
```

#### 生产环境 (Docker)
```bash
# 配置文件在容器中的路径
/app/etc/auth-api.yaml
/app/etc/product-api.yaml
```

### 7. 优势

#### ✅ 清晰的职责分离
- 可执行程序在 `cmd/`
- 业务逻辑在 `internal/`
- 配置文件跟随服务

#### ✅ 便于独立部署
- 每个服务有独立的配置
- 可以独立构建和部署
- 符合微服务架构

#### ✅ 符合 Go 标准
- 遵循 Go 社区最佳实践
- 便于维护和扩展
- 清晰的模块边界

### 8. 迁移步骤

1. ✅ 创建 `cmd/{service}/etc/` 目录
2. ✅ 复制配置文件到新位置
3. ✅ 更新 Dockerfile 中的路径
4. ✅ 更新 main.go 中的配置文件路径
5. 🔄 删除旧的配置文件 (可选)

### 9. 注意事项

- 配置文件路径在 `main.go` 中已经正确设置
- Docker 构建路径已更新
- 开发和生产环境都能正常工作
- 保持了配置文件的相对路径结构

这样的组织方式更符合 Go 项目的最佳实践，也便于后续的维护和扩展。
