# API 管理重新设计方案

## 🤔 当前问题

之前的设计存在以下问题：
- API 文件存在两个地方：`internal/${service}/${service}.api` 和 `api/openapi/${service}.api`
- goctl 脚本仍从 `internal/${service}/${service}.api` 读取
- 需要手动保持两处文件同步
- 违反了"单一数据源"原则

## ✅ 新的设计方案

### 目录结构
```
amazon-pilot/
├── api/
│   ├── openapi/              # 🎯 唯一的 API 定义源
│   │   ├── auth.api          # 认证服务 API 定义
│   │   ├── product.api       # 产品服务 API 定义
│   │   ├── competitor.api    # 竞品分析 API 定义
│   │   ├── optimization.api  # 优化建议 API 定义
│   │   └── notification.api  # 通知服务 API 定义
│   ├── docs/                 # 生成的 API 文档
│   └── clients/              # 生成的客户端 SDK (未来)
├── internal/
│   ├── auth/                 # 🔧 go-zero 生成的代码
│   │   ├── config/           # (无 .api 文件)
│   │   ├── handler/
│   │   ├── logic/
│   │   ├── svc/
│   │   └── types/
│   └── ...
```

### 开发工作流
```bash
# 1. 修改 API 定义 (统一位置)
vim api/openapi/auth.api

# 2. 生成代码 (新的脚本)
./scripts/goctl-monorepo.sh -a api/openapi/auth.api -s auth

# 3. 实现业务逻辑
vim internal/auth/logic/pingLogic.go
```

## 🚀 优势

1. **单一数据源**: API 定义只存在一个地方
2. **真正集中管理**: 所有 API 定义集中在 api/openapi/
3. **便于维护**: 不需要同步多处文件
4. **便于扩展**: 
   - 统一生成 API 文档
   - 统一生成各语言客户端
   - 跨服务 API 一致性检查
5. **保持 go-zero 便利性**: 代码生成流程基本不变

## 🔄 迁移步骤

1. **移动 API 文件**: 将 internal/${service}/${service}.api 移动到 api/openapi/
2. **修改 goctl 脚本**: 支持从 api/openapi/ 读取 API 定义
3. **清理重复文件**: 删除 internal/ 下的 .api 文件
4. **测试验证**: 确保代码生成和服务启动正常

## 📋 实施计划

- [ ] 重新组织 API 文件
- [ ] 修改 goctl-monorepo.sh 脚本
- [ ] 更新开发文档  
- [ ] 验证所有服务正常工作