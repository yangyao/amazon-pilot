# Goctl Monorepo 脚本

该脚本解决了 `goctl` 在 Monorepo 项目中总是创建额外 `internal` 目录的问题。

## 问题描述

当使用 `goctl api go --api some.api --dir ./ --style=goZero` 命令时，goctl 会在当前目录下创建一个新的 `internal` 目录，导致目录结构变成：
```
./internal/some(service)/internal/logic
./internal/some(service)/internal/handler
```

这在 Monorepo 环境中是不合适的，因为我们已经有了统一的 `internal` 目录结构。

## 解决方案

提供了一个 Shell 脚本来解决这个问题：

- **Shell 脚本**: `goctl-monorepo.sh` - Bash 实现，包含智能文件覆盖逻辑

## 使用方法

### Shell 脚本

```bash
# 基本用法
./scripts/goctl-monorepo.sh -a auth.api -s auth

# 指定模块名称
./scripts/goctl-monorepo.sh -a user.api -s user -m github.com/example/project

# 使用自定义模板
./scripts/goctl-monorepo.sh -a order.api -s order -t ./templates
```


## 参数说明

| 参数 | 简写 | 说明 | 必需 |
|------|------|------|------|
| `--api` | `-a` | API文件路径 | 是 |
| `--service` | `-s` | 服务名称 | 是 |
| `--module` | `-m` | Go模块名称 | 否* |
| `--template` | `-t` | 自定义模板目录 | 否 |
| `--help` | `-h` | 显示帮助信息 | - |

*如果不指定模块名称，脚本会自动从 `go.mod` 文件中读取。

## 工作流程

1. **创建临时目录**: 脚本在系统临时目录中创建一个工作目录
2. **执行 goctl**: 在临时目录中执行 `goctl api go` 命令生成代码
3. **复制代码**: 将生成的代码从 `临时目录/internal/` 复制到 `./internal/{服务名}/`
4. **修复导入路径**: 自动修复Go文件中的导入路径，将 `"./internal/"` 替换为正确的模块路径
5. **清理临时文件**: 删除临时目录

## 目录结构

脚本会将代码生成到以下结构：

```
./internal/{服务名}/
├── config/
├── etc/
├── handler/
├── logic/
├── svc/
├── types/
└── {服务名}.go
```

## 特性

- ✅ 自动处理目录结构问题，避免嵌套 `internal` 目录
- ✅ 自动修复Go导入路径，将临时路径替换为正确的模块路径
- ✅ 支持自定义模板
- ✅ 智能文件覆盖逻辑：
  - `types.go` 和 `routes.go` 总是覆盖（通常需要保持最新）
  - 其他已存在的文件会被跳过，保护自定义代码
- ✅ 彩色输出提示
- ✅ 错误处理和回滚
- ✅ 从go.mod自动读取模块名

## 示例

假设你有以下项目结构：
```
./
├── go.mod (module github.com/example/amazon-pilot)
├── internal/
│   ├── auth/
│   ├── user/
│   └── product/
└── scripts/
    ├── goctl-monorepo.sh
    └── goctl-monorepo.go
```

运行命令：
```bash
./scripts/goctl-monorepo.sh -a order.api -s order
```

将会生成：
```
./internal/order/
├── config/
├── etc/
├── handler/
├── logic/
├── svc/
├── types/
└── order.go
```

并且所有Go文件中的导入路径都会被正确设置为 `github.com/example/amazon-pilot/internal/order/...`

## 注意事项

1. 确保已安装 `goctl` 工具
2. 确保API文件存在且格式正确
3. 如果目标目录已存在文件，脚本会询问是否覆盖
4. 脚本会自动创建不存在的目录
5. 临时文件会在执行完成后自动清理

## 故障排除

### goctl 命令未找到
```bash
go install github.com/zeromicro/go-zero/tools/goctl@latest
```

### 权限问题 (Shell脚本)
```bash
chmod +x scripts/goctl-monorepo.sh
```

### 找不到 go.mod
确保在项目根目录执行脚本，或使用 `-m` 参数手动指定模块名称。