# Claude 开发规范 - Amazon Pilot 项目

## 🚨 重要：必须严格遵循的开发规范

## 📁 项目目录结构 (必须熟记)

```
/Users/jiao/www/amazon-pilot/              # 项目根目录 (工作目录)
├── api/openapi/                           # API 定义文件 (source of truth)
│   ├── auth.api                           # 认证服务 API 定义
│   ├── product.api                        # 产品服务 API 定义  
│   ├── competitor.api                     # 竞争对手服务 API 定义
│   ├── optimization.api                   # 优化服务 API 定义
│   └── notification.api                   # 通知服务 API 定义
├── cmd/                                  # 服务启动入口
│   ├── auth/main.go                      # 认证服务启动文件
│   ├── product/main.go                   # 产品服务启动文件
│   ├── gateway/main.go                   # 网关服务启动文件
│   ├── competitor/main.go                # 竞争对手服务启动文件
│   ├── optimization/main.go              # 优化服务启动文件
│   ├── notification/main.go              # 通知服务启动文件
│   └── worker/main.go                    # 异步任务处理服务 ⭐
├── internal/                             # 内部代码 (自动生成 + 手动实现)
│   ├── auth/                            # 认证服务内部代码
│   │   ├── handler/                     # HTTP 处理器 (自动生成)
│   │   ├── logic/                       # 业务逻辑 (手动实现)
│   │   ├── svc/                         # 服务上下文 (手动配置)
│   │   └── types/                       # 类型定义 (自动生成)
│   ├── product/                         # 产品服务内部代码
│   ├── competitor/                      # 竞争对手服务内部代码
│   ├── optimization/                    # 优化服务内部代码
│   ├── notification/                    # 通知服务内部代码
│   └── pkg/                             # 共享工具包
│       ├── logger/                      # 结构化日志工具
│       ├── database/                    # 数据库工具
│       ├── apify/                       # Apify API 客户端
│       ├── errors/                      # 错误处理工具 (统一API错误格式)
│       └── utils/                       # 响应处理工具 (统一错误响应)
├── scripts/                             # 脚手架脚本 (必须使用)
│   ├── goctl-centralized.sh             # API 代码生成脚本 (自动修复错误处理)
│   ├── service-manager.sh               # 统一服务管理脚本 ⭐️ (唯一推荐)
│   ├── run-migrations.sh                # 数据库迁移脚本 (新增表)
│   └── start-service.sh                 # 单服务启动脚本 (被service-manager调用)
├── docs/                                # 架构文档 (source of truth)
│   ├── ARCHITECTURE.md                  # 系统架构设计
│   ├── API_DESIGN.md                    # API 设计规范 (完整版)
│   ├── DATABASE_DESIGN.md               # 数据库设计 (完整版)
│   ├── api/                             # 按服务拆分的API设计 (新增)
│   │   ├── INDEX.md                     # API设计索引导航
│   │   ├── OVERVIEW.md                  # API架构概览
│   │   ├── AUTH.md                      # Auth服务API设计
│   │   └── PRODUCT.md                   # Product服务API设计 ⭐
│   ├── database/                        # 按服务拆分的数据库设计 (新增)
│   │   ├── INDEX.md                     # 数据库设计索引导航
│   │   ├── OVERVIEW.md                  # 数据库架构概览
│   │   ├── USERS.md                     # Auth服务表设计
│   │   ├── PRODUCTS.md                  # Product服务表设计 ⭐
│   │   ├── COMPETITORS.md               # Competitor服务表设计
│   │   ├── OPTIMIZATION.md              # Optimization服务表设计
│   │   ├── NOTIFICATIONS.md             # Notification服务表设计
│   │   ├── INDEXING.md                  # 索引策略设计
│   │   ├── CACHING.md                   # Redis缓存策略
│   │   ├── PARTITIONING.md              # 时间序列分区
│   │   └── MIGRATIONS.md                # 数据库迁移管理
│   └── questions.md                     # 项目需求文档
├── frontend/                            # 前端代码
│   └── src/app/                         # Next.js 页面
├── deployments/                         # 部署相关文件
├── .env                                 # 环境变量
└── CLAUDE.md                           # 本开发规范文件
```

## 🎯 重要目录说明

### 📝 **API 定义目录** (最重要)
- **位置**: `/api/openapi/`  
- **作用**: 所有 API 的 source of truth
- **修改后必须**: 执行 `./scripts/goctl-centralized.sh -s <service>`

### 🔧 **脚本目录** 
- **位置**: `/scripts/`
- **作用**: 所有开发工具脚本
- **必须使用**: 不能绕过这些脚本

### 🏗️ **服务内部代码**
- **位置**: `/internal/<service>/`
- **自动生成**: `handler/`, `types/` (不要手动修改)
- **手动实现**: `logic/` (业务逻辑实现)
- **手动配置**: `svc/` (服务上下文配置)

### 📖 **架构文档**
- **位置**: `/docs/`
- **作用**: 所有技术决策的 source of truth
- **必须先看**: 任何代码修改前都要参考

## 🗺️ 重要文件位置清单

### 🔗 **API 定义文件** (必须记住)
- Auth API: `/Users/jiao/www/amazon-pilot/api/openapi/auth.api`
- Product API: `/Users/jiao/www/amazon-pilot/api/openapi/product.api`
- Competitor API: `/Users/jiao/www/amazon-pilot/api/openapi/competitor.api`
- Optimization API: `/Users/jiao/www/amazon-pilot/api/openapi/optimization.api`
- Notification API: `/Users/jiao/www/amazon-pilot/api/openapi/notification.api`

### 🛠️ **核心脚手架脚本** (必须使用)
- **代码生成**: `/Users/jiao/www/amazon-pilot/scripts/goctl-centralized.sh`
- **统一服务管理**: `/Users/jiao/www/amazon-pilot/scripts/service-manager.sh` ⭐️ **唯一推荐**
- 单服务启动: `/Users/jiao/www/amazon-pilot/scripts/start-service.sh` (被 service-manager.sh 调用)

### 📋 开发流程 (必须按顺序执行)

#### 1. 修改 API 定义后的必要步骤
```bash
# 修改 API 文件后，必须重新生成代码
./scripts/goctl-centralized.sh -s <service_name>

# 例如：
./scripts/goctl-centralized.sh -s product
./scripts/goctl-centralized.sh -s auth  
./scripts/goctl-centralized.sh -s competitor
```

#### 2. 统一服务管理 (唯一推荐方式)
```bash
# ⭐️ 唯一服务管理脚本
./scripts/service-manager.sh start                # 启动所有服务
./scripts/service-manager.sh stop                 # 停止所有服务
./scripts/service-manager.sh restart              # 重启所有服务
./scripts/service-manager.sh status               # 查看所有服务状态

# 管理单个服务
./scripts/service-manager.sh start auth           # 启动认证服务
./scripts/service-manager.sh stop product         # 停止产品服务
./scripts/service-manager.sh restart competitor   # 重启竞争对手服务
./scripts/service-manager.sh status gateway       # 查看网关状态

# 列出所有可用服务
./scripts/service-manager.sh list

# 显示帮助
./scripts/service-manager.sh help

# 监控栈管理
./scripts/service-manager.sh monitor             # 启动监控栈 (Prometheus + Loki + Grafana)
./scripts/service-manager.sh stop-monitor       # 停止监控栈

# 禁止使用：go run cmd/xxx/main.go
# 禁止使用：go run internal/xxx/xxx.go
# 禁止直接使用其他启动脚本
```

#### 3. 数据库迁移管理 (新增)
```bash
# 执行数据库迁移 (添加新表)
./scripts/run-migrations.sh

# 迁移功能：
# - 自动创建 schema_migrations 追踪表
# - 检查已应用的迁移，避免重复执行
# - 创建 product_review_history 表 (评论变化追踪)
# - 创建 product_buybox_history 表 (Buy Box变化追踪)
# - 验证表创建结果

# 迁移文件位置：deployments/migrations/
# 当前迁移：
# - 003_add_history_tables.sql (添加历史表)
# - 004_remove_triggers_add_async_detection.sql (优化异常检测)
```

#### 3. 日志记录 (必须使用结构化日志)
```go
// 使用项目的结构化日志包
import "amazonpilot/internal/pkg/logger"

// 在 ServiceContext 中使用
logger := logger.NewServiceLogger("service-name")
logger.Info("message", "key", "value")
logger.Error("error occurred", "error", err)
```

### 📁 架构文档 (必须参考)

在编写任何代码前，必须先查看：

1. **`docs/ARCHITECTURE.md`** - 系统架构图和设计原则
2. **`docs/API_DESIGN.md`** - API 设计规范
3. **`docs/DATABASE_DESIGN.md`** - 数据库设计规范
4. **`docs/CACHING.md`** - 缓存设计规范和Redis策略 ⭐ **新增**
5. **`docs/MONITORING.md`** - 监控和可观测性设计
6. **`docs/*.md`** - 所有设计文档都是 source of truth

### 🛠 开发规范

#### API 开发流程
1. 修改 `api/openapi/<service>.api` 文件
2. 执行 `./scripts/goctl-centralized.sh -s <service>`
3. 实现 `internal/<service>/logic/` 中的业务逻辑
4. 使用 `./scripts/start-service.sh <service>` 启动服务
5. 测试 API 端点

#### 数据库连接
- 所有服务必须使用 DSN 方式连接数据库
- 统一在 ServiceContext 中配置

#### 微服务通信
- Ops 服务通过 JWT 调用其他服务，不直接操作数据库
- 所有服务间调用通过 Gateway 进行

#### 错误处理
- 使用 `internal/pkg/errors` 包
- 返回结构化错误信息
- 记录详细错误日志

### ⚠️ 禁止事项

1. **🚫 绝对禁止硬编码配置** (最高优先级)
   - **任何情况下都不允许硬编码**：IP地址、端口、数据库DSN、API Token等
   - **包括但不限于**：开发环境、测试环境、演示代码、临时调试
   - **必须使用配置文件**：每个服务都有对应的 `.yaml` 配置文件
   - **违反此规则将要求完全重做**

2. **🔍 强制编译验证** (最高优先级)
   - **修改任何Go代码后必须确保编译通过**
   - **执行步骤**：
     ```bash
     go build ./cmd/<service>/main.go  # 验证服务可编译
     go mod tidy                       # 清理依赖
     ```
   - **编译失败时必须立即修复，不能声称任务完成**

3. **📋 强制结构化JSON日志** (最高优先级)
   - **所有日志输出必须是JSON格式**，包括GORM SQL日志
   - **禁止非JSON格式日志**：`fmt.Println`, 标准`log`包, GORM默认日志
   - **必须使用**：`slog`结构化日志 + 自定义GORM JSON Logger

4. **🚨 严禁手动修改自动生成文件** (最高优先级)
   - **绝对禁止手动编辑**：
     - `internal/<service>/types/types.go` (自动生成)
     - `internal/<service>/handler/routes.go` (自动生成)
     - `internal/<service>/handler/*Handler.go` (自动生成)
   - **正确工作流程**：
     1. 修改 `api/openapi/<service>.api` 文件
     2. 执行 `./scripts/goctl-centralized.sh -s <service>`
     3. 实现 `internal/<service>/logic/` 中的业务逻辑
   - **违反后果**：代码会在下次生成时被覆盖，造成工作丢失

5. **🌐 API路由前缀强制规范** (最高优先级)
   - **所有API文件必须使用标准前缀**：`/api/${service}`
   - **示例**：
     - `auth.api` → `prefix: /api/auth`
     - `product.api` → `prefix: /api/product`
     - `competitor.api` → `prefix: /api/competitor`
   - **违反后果**：Gateway路由无法正确匹配，导致404错误

6. **🚫 严禁Fallback和Mock逻辑** (最高优先级)
   - **永远不要使用fallback、mock、默认数据**
   - **错了就是错了，直接报错**
   - **禁止任何形式的**：容错处理、默认数据、示例数据、mock响应
   - **正确做法**：API调用失败时直接返回错误，让用户知道真实情况
   - **违反后果**：隐藏真实问题，用户看到假数据，调试困难

4. **🗃️ 数据库变更强制流程** (最高优先级)
   - **表名必须有服务前缀**：`product_xxx`, `user_xxx`, `auth_xxx`
   - **禁止直接执行SQL创建表**，必须通过迁移流程：
     ```bash
     # 1. 创建迁移文件: deployments/migrations/XXX_description.sql
     # 2. 运行迁移脚本: ./scripts/run-migrations.sh
     # 3. 更新数据库设计文档
     ```
   - **每个数据变更必须更新文档**：`docs/DATABASE_DESIGN.md`

5. **🌐 前端API调用规范** (最高优先级)
   - **统一通过productAPI调用**，禁止直接fetch
   - **所有API请求必须经过网关**：`api.get('/product/xxx')`
   - **禁止绕过API客户端**：不能直接调用`fetch('/api/xxx')`

4. **禁止绕过脚手架**
   - 不能直接使用 `goctl` 命令
   - 不能直接使用 `go run` 启动服务

5. **禁止忽略设计文档**
   - 任何架构决策前必须查看 `docs/*.md`
   - 技术方案必须符合已有设计

6. **禁止跳过代码生成步骤**
   - 修改 `.api` 文件后必须重新生成代码
   - 不能手动修改生成的文件

## 🚨 **Claude 工作流规范**

### ⚡ **当前工作目录必须是**
```bash
/Users/jiao/www/amazon-pilot/
```

### 🎯 **Claude 工作检查清单** (每次任务前必须)

在开始任何任务前，问自己：

- [ ] 我是否在正确的工作目录？(`/Users/jiao/www/amazon-pilot/`)
- [ ] 🔍 **我是否先查看了相关的 `docs/*.md` 设计文档？** ⭐ **最重要**
- [ ] 我是否使用了正确的脚手架脚本？
- [ ] 我是否使用了结构化日志？
- [ ] 我是否遵循了现有的架构设计？
- [ ] 我是否使用了项目的工具包和中间件？

### 📖 **强制设计文档优先原则**

**🚨 任何代码修改前必须先查看设计文档：**

1. **技术方案前** → 查看 `docs/ARCHITECTURE.md`
2. **数据库修改前** → 查看 `docs/DATABASE_DESIGN.md`
3. **API设计前** → 查看 `docs/API_DESIGN.md`
4. **缓存设计前** → 查看 `docs/CACHING.md` 了解缓存策略 ⭐ **新增**
5. **功能实现前** → 查看 `docs/questions.md` 了解需求

**设计文档是 source of truth，必须总是参考它之后再做技术方案的决定！**

### 🔍 **Claude 任务完成检查清单** (任务结束前必须)

完成任何代码修改后，必须验证：

- [ ] **编译验证**：`go build ./cmd/<service>/main.go` 成功编译
- [ ] **依赖清理**：`go mod tidy` 清理无用依赖
- [ ] **配置文件使用**：所有配置均来自 `.yaml` 文件，无任何硬编码
- [ ] **结构化日志**：所有日志输出均为JSON格式
- [ ] **服务启动测试**：使用 `./scripts/service-manager.sh start <service>` 能正常启动

### 🚨 **强制开发工作流** (违反将要求重做)

#### 步骤1: 编码前检查
```bash
pwd  # 确保在 /Users/jiao/www/amazon-pilot/
```

#### 步骤2: 修改代码
- 查看相关文档：`docs/*.md`
- 修改配置/API/代码

#### 步骤3: 强制编译验证 (最重要)
```bash
# 编译验证 - 必须成功
go build ./cmd/<service>/main.go

# 依赖清理
go mod tidy

# 如果编译失败，必须立即修复，不能跳过此步骤
```

#### 步骤4: 数据库变更检查
```bash
# 如果涉及数据库变更，必须：
# 1. 检查表名是否有服务前缀
grep -r "TableName.*return" internal/  # 检查所有表名
# 2. 创建迁移文件，不能直接执行SQL
ls deployments/migrations/
# 3. 运行迁移脚本
./scripts/run-migrations.sh
```

#### 步骤5: 配置检查
```bash
# 检查是否使用了配置文件而非硬编码
grep -r "localhost" cmd/     # 应该没有输出
grep -r "5432" cmd/         # 应该没有输出
grep -r "amazon123" cmd/    # 应该没有输出
```

#### 步骤6: 前端API调用检查
```bash
# 检查前端是否统一使用API客户端
grep -r "fetch('/api" frontend/src/  # 应该没有输出，应该用productAPI
```

#### 步骤7: 日志格式验证
```bash
# 启动服务检查日志格式
./scripts/service-manager.sh start <service>

# 检查日志是否为JSON格式，不能有非JSON输出
```

## 🚀 **快速启动演示** (已测试)

```bash
# 1. 确保在项目根目录
cd /Users/jiao/www/amazon-pilot/

# 2. 启动监控栈 (可选)
./scripts/service-manager.sh monitor

# 3. 一键启动所有服务
./scripts/service-manager.sh start

# 4. 访问演示页面
# Frontend: http://localhost:3000
# Products Demo: http://localhost:3000/products

# 5. 查看服务状态
./scripts/service-manager.sh status

# 6. 访问监控面板 (如果启动了监控栈)
# Grafana: http://localhost:3001 (admin/admin123)
# Prometheus: http://localhost:9090
# pgAdmin: http://localhost:8082

# 7. 停止系统
./scripts/service-manager.sh stop

# 8. 停止监控栈 (如果需要)
./scripts/service-manager.sh stop-monitor
```

### 🔄 **典型开发工作流**

#### 场景1: 修改 API 定义
```bash
# 1. 确认工作目录
pwd  # 应该是 /Users/jiao/www/amazon-pilot/

# 2. 修改 API 文件
vim api/openapi/product.api

# 3. 重新生成代码 (必须!)
./scripts/goctl-centralized.sh -s product

# 4. 实现业务逻辑
vim internal/product/logic/xxxLogic.go

# 5. 重启服务
./scripts/service-manager.sh restart product
```

#### 场景3: 启动Worker系统 (异步任务处理)
```bash
# 启动Worker服务 (处理Redis队列任务)
go run cmd/worker/main.go

# Worker功能:
# - 处理Apify数据刷新任务
# - 异常检测消息处理
# - 通知发送任务
# - 数据清理和批量任务

# Worker配置文件: cmd/worker/etc/worker.yaml
```

#### 场景2: 添加新功能
```bash
# 1. 查看架构文档
cat docs/ARCHITECTURE.md
cat docs/API_DESIGN.md

# 2. 修改 API 定义
vim api/openapi/<service>.api

# 3. 生成代码
./scripts/goctl-centralized.sh -s <service>

# 4. 实现逻辑 (使用结构化日志)
vim internal/<service>/logic/
```

### 📞 重要提醒

**设计文档是 source of truth，必须总是参考它之后再做技术方案的决定！**

## 🚫 **Claude 常犯错误** (必须避免)

### 🔥 **最严重错误 (立即重做)**

#### ❌ **硬编码配置错误**
- 在代码中直接写入 `localhost:5432`, `amazon123`, API Token
- 跳过配置文件，直接硬编码连接参数
- 声称"临时"或"测试"就可以硬编码

#### ❌ **编译验证错误**
- 修改代码后不运行编译检查
- 声称任务完成但代码无法编译
- 忽略 `go build` 失败的错误

#### ❌ **日志格式错误**
- 使用 `fmt.Println` 或标准 `log` 包
- 忽略 GORM 输出非JSON格式日志
- 不使用结构化 JSON 日志

### ⚠️ **其他错误**

#### ❌ **目录错误**
- 运行脚本时不在项目根目录
- 编辑文件时路径错误
- 前端和后端目录混淆

#### ❌ **脚手架错误**
- 修改 API 后不重新生成代码
- 直接使用 `go run` 而不是脚本
- 跳过必要的代码生成步骤

#### ❌ **架构文档错误**
- 不查看 `docs/*.md` 就开始编码
- 自己发明架构而不遵循现有设计
- 忽略项目约定和规范

### 🚨 **错误后果**
- **硬编码 → 完全重做**
- **编译失败 → 立即修复**
- **非JSON日志 → 重新实现**

## ✅ **正确的 Claude 行为**

### 1. **始终确认位置**
```bash
pwd  # 必须显示 /Users/jiao/www/amazon-pilot/
```

### 2. **API 修改流程**
```bash
# 编辑 API 定义
vim api/openapi/product.api

# 立即生成代码  
./scripts/goctl-centralized.sh -s product

# 实现逻辑
vim internal/product/logic/xxxLogic.go

# 使用统一管理器重启服务
./scripts/service-manager.sh restart product
```

### 3. **架构决策流程**
```bash
# 先查看文档
cat docs/ARCHITECTURE.md
cat docs/API_DESIGN.md
cat docs/CACHING.md        # 缓存相关开发必看

# 然后再编码
```

如果 Claude 没有遵循这些规范，用户应该直接指出并要求重做。

## 🌐 **端口配置清单** (必须记住)

### **微服务端口**
```
amazon-pilot-auth-service        → 容器内:8001  映射:8001
amazon-pilot-product-service     → 容器内:8002  映射:8002
amazon-pilot-competitor-service  → 容器内:8003  映射:8003
amazon-pilot-optimization-service → 容器内:8004  映射:8004
amazon-pilot-gateway            → 容器内:8080  映射:8080 ⭐ (API统一入口)
amazon-pilot-frontend-service   → 容器内:3000  映射:4000 ⭐ (Web应用入口)
```

### **数据存储端口**
```
amazon-pilot-postgres           → 容器内:5432  映射:5432
amazon-pilot-redis              → 容器内:6379  映射:6379
```

### **监控管理端口**
```
amazon-pilot-dashboard-service  → 容器内:5555  映射:5555 (任务队列监控)
amazon-pilot-grafana           → 容器内:3000  映射:3001 (数据可视化)
amazon-pilot-prometheus        → 容器内:9090  映射:9090 (指标收集)
amazon-pilot-node-exporter     → 容器内:9100  映射:9100 (系统监控)
amazon-pilot-redis-exporter    → 容器内:9121  映射:9121 (Redis监控)
```

### **Caddy反向代理端口**
```
amazon-pilot-caddy             → 容器内:80/443  映射:80/443 (HTTPS入口)
```

### **🎯 重要端口说明**

#### **用户访问入口**
- **直接访问**: `http://localhost:4000` (Frontend)
- **域名访问**: `http://amazon-pilot.phpman.top` (通过Caddy)
- **API网关**: `http://localhost:8080/api/*`

#### **管理监控入口**
- **任务监控**: `http://localhost:5555` 或 `http://monitor.amazon-pilot.phpman.top`
- **数据监控**: `http://localhost:3001` 或 `http://grafana.amazon-pilot.phpman.top`
- **系统监控**: `http://localhost:9090`

#### **开发调试端口**
- **各服务直接访问**: `8001-8004`
- **数据库直接连接**: `5432`
- **Redis直接连接**: `6379`

### **📋 端口占用检查命令**
```bash
# 检查所有服务端口
lsof -i:80,443,3001,4000,5432,5555,6379,8001,8002,8003,8004,8080,9090,9100,9121

# 检查Docker服务状态
docker-compose -f deployments/compose/docker-compose.yml ps
```

---

**最后更新**: 2025-09-14
**版本**: v3.2 - 添加端口配置清单和Caddy反向代理支持