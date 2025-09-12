# Amazon Pilot 项目结构优化建议

## 当前结构分析

### 现状评估

**✅ 现在做得好的地方:**
- 使用了 `internal/cmd/` 作为应用程序入口点 (符合业界实践)
- 每个服务都有独立的 Dockerfile (符合微服务架构)
- 单一 `go.mod` 文件管理依赖 (避免了多模块复杂性)
- 完整的文档和配置管理

**❌ 可以改进的地方:**
- 缺少共享代码目录 (`pkg/` 或 `internal/pkg/`)
- 没有明确的依赖分层结构
- go-zero 生成的代码结构与标准 Go 项目布局不够融合
- 缺少明确的模块边界和接口定义

### 当前目录结构
```
amazon-pilot/
├── internal/
│   ├── cmd/              # ✅ 应用程序入口 (符合标准)
│   ├── auth/             # ❌ go-zero 生成，但缺少清晰分层
│   ├── product/          # ❌ 同上
│   ├── competitor/       # ❌ 同上
│   ├── optimization/     # ❌ 同上
│   └── notification/     # ❌ 同上
├── docker/               # ✅ 统一 Docker 配置
├── docs/                 # ✅ 完整文档
├── scripts/              # ✅ 工具脚本
└── go.mod                # ✅ 单一依赖管理
```

## 业界最佳实践对比

### 1. Go 标准项目布局 (golang-standards/project-layout)

```
project/
├── cmd/              # 应用程序入口
├── internal/         # 私有代码
├── pkg/              # 可导出的库代码
├── api/              # API 定义
├── web/              # Web 资产
├── scripts/          # 脚本
├── build/            # 构建相关
└── deployments/      # 部署配置
```

### 2. Kubernetes 大型项目结构

```
kubernetes/
├── cmd/              # 各个组件入口
├── pkg/              # 核心功能包 (8000+ files)
├── staging/          # 可发布的模块
├── api/              # API 定义
└── vendor/           # 依赖
```

### 3. Go Monorepo 最佳实践

```
monorepo/
├── services/         # 或 cmd/
├── pkg/              # 共享库
├── internal/         # 私有共享代码
└── api/              # API 定义
```

## 优化建议

### 方案一：渐进式优化 (推荐)

保持现有结构，逐步添加缺失的组件：

```
amazon-pilot/
├── cmd/                    # 🆕 移动 internal/cmd 到根目录 (更标准)
│   ├── auth/
│   ├── product/
│   ├── competitor/
│   ├── optimization/
│   ├── notification/
│   ├── worker/
│   └── scheduler/
├── internal/
│   ├── pkg/                # 🆕 内部共享代码
│   │   ├── auth/          # 认证相关工具
│   │   ├── database/      # 数据库工具
│   │   ├── queue/         # 队列工具
│   │   ├── logger/        # 日志工具
│   │   └── config/        # 配置管理
│   ├── auth/              # 保留 go-zero 生成的代码
│   ├── product/
│   ├── competitor/
│   ├── optimization/
│   └── notification/
├── pkg/                    # 🆕 可导出的公共库
│   ├── client/            # API 客户端
│   └── types/             # 共享类型定义
├── api/                    # 🆕 API 定义集中管理
│   ├── auth.proto         # gRPC 定义
│   ├── product.proto
│   └── openapi/           # REST API 定义
├── web/                    # 🆕 Web 资产 (如果需要)
├── deployments/            # 🆕 部署配置
│   ├── k8s/
│   └── helm/
├── docker/                 # 保留现有
├── docs/                   # 保留现有
├── scripts/                # 保留现有
└── go.mod                  # 保留现有
```

### 方案二：完全重构 (激进)

采用多模块 monorepo 结构：

```
amazon-pilot/
├── services/               # 各个服务
│   ├── auth/
│   │   ├── go.mod         # 独立模块
│   │   ├── cmd/
│   │   └── internal/
│   ├── product/
│   └── ...
├── libs/                   # 共享库
│   ├── database/
│   │   ├── go.mod
│   │   └── ...
│   ├── queue/
│   └── ...
├── tools/                  # 工具链
└── scripts/
```

## 具体优化建议

### 1. 🔥 高优先级 - 添加共享代码管理

**问题**: 每个服务都可能重复实现相同的功能 (数据库连接、日志、认证等)

**解决方案**:
```bash
# 创建内部共享代码目录
mkdir -p internal/pkg/{auth,database,queue,logger,config,middleware}

# 创建可导出的公共库
mkdir -p pkg/{client,types}
```

**收益**:
- 减少代码重复
- 统一基础设施代码
- 便于维护和升级

### 2. 🔥 高优先级 - 移动 cmd 目录到根目录

**问题**: `internal/cmd` 不是标准 Go 项目布局

**解决方案**:
```bash
# 移动命令目录到根目录
mv internal/cmd cmd

# 更新所有 Dockerfile 中的路径
# 更新所有文档中的路径
```

**收益**:
- 符合 Go 标准项目布局
- 更直观的项目结构
- 更好的工具支持

### 3. 🔶 中优先级 - 集中 API 定义管理

**问题**: API 定义分散在各个服务中

**解决方案**:
```bash
# 创建 API 定义目录
mkdir -p api/{openapi,proto}

# 移动所有 .api 文件到统一位置
mv internal/*/*.api api/openapi/

# 如果使用 gRPC，添加 proto 定义
```

**收益**:
- API 定义集中管理
- 便于生成多语言客户端
- 更好的 API 文档生成

### 4. 🔶 中优先级 - 添加部署配置目录

**问题**: 部署配置分散，难以管理

**解决方案**:
```bash
# 创建部署配置目录
mkdir -p deployments/{k8s,helm,compose}

# 移动 docker-compose.yml
mv docker-compose.yml deployments/compose/

# 如果有 k8s 配置，也移动到对应目录
```

**收益**:
- 部署配置集中管理
- 支持多种部署方式
- 环境特定配置隔离

### 5. 🔷 低优先级 - 考虑多模块结构

**仅在以下情况考虑**:
- 团队规模 > 10 人
- 需要独立发布某些模块
- 需要严格的依赖边界

## 迁移策略

### 阶段一：基础优化 (1-2 天)

1. **移动 cmd 目录**
```bash
mv internal/cmd cmd
# 更新所有相关配置文件
```

2. **创建共享代码目录**
```bash
mkdir -p internal/pkg/{database,logger,config}
mkdir -p pkg/{client,types}
```

3. **更新构建脚本和文档**

### 阶段二：共享代码提取 (3-5 天)

1. **识别重复代码**
   - 数据库连接逻辑
   - 日志配置
   - 认证中间件
   - 错误处理

2. **提取到 internal/pkg**
   - 创建共享包
   - 重构各服务使用共享包
   - 确保测试通过

### 阶段三：API 管理优化 (2-3 天)

1. **集中 API 定义**
```bash
mkdir -p api/openapi
mv internal/*/*.api api/openapi/
```

2. **更新代码生成脚本**
   - 修改 goctl-monorepo.sh
   - 支持新的目录结构

### 阶段四：部署配置优化 (1-2 天)

1. **创建部署目录**
2. **移动相关配置文件**
3. **更新部署脚本**

## 预期收益

### 短期收益 (1-2 周内)
- ✅ 符合 Go 标准项目布局
- ✅ 更清晰的项目结构
- ✅ 更好的 IDE 支持

### 中期收益 (1-2 月内)
- ✅ 减少代码重复
- ✅ 提高开发效率
- ✅ 便于新人上手

### 长期收益 (3+ 月)
- ✅ 更好的可维护性
- ✅ 更容易扩展新服务
- ✅ 更好的测试覆盖

## 风险评估

### 低风险
- 移动 cmd 目录 (只需要更新路径)
- 创建新的目录结构

### 中风险  
- 提取共享代码 (可能影响现有功能)
- 修改构建脚本

### 建议
1. **逐步迁移**: 不要一次性修改所有内容
2. **充分测试**: 每个阶段都要确保所有功能正常
3. **保留备份**: 使用 git 分支进行迁移
4. **文档更新**: 及时更新相关文档

## 总结

当前项目结构已经相对合理，主要缺失的是：
1. **共享代码管理** (最重要)
2. **标准目录布局** (cmd 目录位置)
3. **API 集中管理** (可选)

建议采用**渐进式优化**方案，先解决最关键的共享代码问题，再逐步优化其他方面。这样既能获得最佳实践的收益，又能最小化迁移风险。