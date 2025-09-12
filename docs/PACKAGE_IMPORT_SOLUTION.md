# 包导入问题解决方案

## 问题描述

当将 `main.go` 文件移动到 `cmd/` 目录后，遇到了 Go 包导入的问题：

```
use of internal package amazonpilot/internal/auth/internal/config not allowed
```

## 问题原因

Go 的包导入规则规定：
- `internal` 包只能被同一模块下的包导入
- 当 `main.go` 在 `cmd/` 目录时，它无法导入 `internal/` 目录下的包
- 这是因为 Go 认为 `cmd/` 和 `internal/` 是不同的模块边界

## 解决方案

### 方案 1: 将 cmd 放在 internal 下 (推荐)

**结构**:
```
internal/
├── cmd/              # 应用程序入口点
│   ├── auth/
│   │   ├── main.go
│   │   └── etc/
│   └── product/
├── auth/             # 业务逻辑 (保留用于 go-zero 代码生成)
│   └── internal/
└── pkg/              # 可导入的业务逻辑
    ├── auth/
    └── product/
```

**优势**:
- ✅ 符合 Go Monorepo 最佳实践
- ✅ 包导入无问题
- ✅ 清晰的模块边界
- ✅ 便于维护和扩展

### 方案 2: 使用 pkg 目录

**结构**:
```
cmd/                  # 应用程序入口点
├── auth/
│   ├── main.go
│   └── etc/
└── product/

internal/             # 私有代码 (保留用于 go-zero 代码生成)
├── auth/
│   └── internal/
└── product/

pkg/                  # 可导入的业务逻辑
├── auth/
└── product/
```

**优势**:
- ✅ 符合 Go 社区标准
- ✅ 包导入无问题
- ✅ 支持外部项目导入
- ✅ 清晰的职责分离

## 最终采用的方案

我们采用了 **方案 1**，将 `cmd` 放在 `internal` 下，并使用 `pkg` 目录存放可导入的业务逻辑。

### 目录结构

```
amazon-pilot/
├── internal/
│   ├── cmd/              # 应用程序入口点
│   │   ├── auth/
│   │   │   ├── main.go   # 导入 pkg/auth/*
│   │   │   └── etc/
│   │   ├── product/
│   │   ├── competitor/
│   │   ├── optimization/
│   │   ├── notification/
│   │   ├── worker/
│   │   ├── scheduler/
│   │   └── monitor/
│   ├── auth/             # 保留用于 go-zero 代码生成
│   │   ├── internal/
│   │   └── auth.api
│   ├── product/
│   ├── competitor/
│   ├── optimization/
│   ├── notification/
│   └── common/
├── pkg/                  # 可导入的业务逻辑
│   ├── auth/
│   │   ├── config/
│   │   ├── handler/
│   │   ├── logic/
│   │   ├── svc/
│   │   └── types/
│   ├── product/
│   ├── competitor/
│   ├── optimization/
│   └── notification/
└── ...
```

### 包导入示例

```go
// internal/cmd/auth/main.go
package main

import (
    "amazonpilot/pkg/auth/config"   // ✅ 可以导入
    "amazonpilot/pkg/auth/handler"  // ✅ 可以导入
    "amazonpilot/pkg/auth/svc"      // ✅ 可以导入
)
```

## 工作流程

### 开发新功能

1. **代码生成**: 在 `internal/{service}/` 目录下使用 go-zero 工具生成代码
2. **复制代码**: 将生成的代码复制到 `pkg/{service}/` 目录
3. **更新导入**: 更新包导入路径
4. **测试构建**: 确保所有服务都能正常构建

### 代码生成命令

```bash
# 生成认证服务代码
goctl api go -api internal/auth/auth.api -dir internal/auth/

# 复制到 pkg 目录
cp -r internal/auth/internal/* pkg/auth/

# 更新包导入路径
find pkg -name "*.go" -exec sed -i '' 's|amazonpilot/internal/\([^/]*\)/internal/|amazonpilot/pkg/\1/|g' {} \;
```

## 验证结果

✅ **所有服务都能正常构建**:
- Auth service builds successfully
- Product service builds successfully  
- Competitor service builds successfully
- Optimization service builds successfully
- Notification service builds successfully

✅ **包导入问题已解决**:
- 不再有 "Use of the internal package is not allowed" 错误
- 所有服务都可以正常导入所需的包

✅ **符合 Go 最佳实践**:
- 遵循 Go 社区推荐的 Monorepo 结构
- 清晰的模块边界和职责分离
- 便于维护和扩展

## 总结

通过将 `cmd` 目录放在 `internal` 下，并使用 `pkg` 目录存放可导入的业务逻辑，我们成功解决了 Go Monorepo 项目中的包导入问题。这种结构既符合 Go 的最佳实践，又便于项目的维护和扩展。
