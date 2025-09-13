# 🚀 Amazon Pilot 5分钟快速Demo

## 🎯 给面试官的一键演示指南

### ⚡ 超级快速启动 (30秒)

```bash
# 1. 设置API Token (使用questions.md提供的)
export APIFY_API_TOKEN='your_apify_token_here'
export OPENAI_API_KEY='sk-proj-Q1ftdObKMqKr6RQskjxc...'

# 2. 一键启动完整系统 (包含数据库设置、服务启动、Demo数据)
./scripts/one-click-demo.sh
```

**🎊 启动完成！系统运行在:**
- 🌐 **前端**: http://localhost:3000
- 🚪 **API Gateway**: http://localhost:8080  
- 🔧 **系统监控**: http://localhost:8080/api/ops/system/status

---

## 🎬 面试官演示流程 (10分钟)

### 第1分钟: 登录系统
1. 访问 http://localhost:3000
2. 使用Demo账户登录:
   - 📧 邮箱: `demo@amazon-pilot.com`
   - 🔒 密码: `demo123456`
3. 进入Dashboard，展示系统概览

### 第2-3分钟: 产品监控演示
1. 点击 **"Products"** 菜单
2. 展示8个真实Amazon产品 (无线蓝牙耳机类别):
   - Echo Buds (B08N5WRWNW) [主产品]
   - AirPods Pro (B0BFZB9Z2P)  
   - Sony WF-1000XM4 (B0BDRR8Z6G)
   - 等等...
3. 点击 **"Update All Products"** 按钮
4. **⚡ 观察实时数据更新** (Apify API调用)

### 第4分钟: 异常检测演示
1. 查看顶部 **通知图标** 🔔
2. 展示实时异常检测通知:
   - 💰 价格变动 >10% 警报
   - 📈 BSR变动 >30% 警报
3. 点击通知查看详细变化数据

### 第5-6分钟: 竞争分析演示  
1. 点击 **"Competitors"** 菜单
2. 查看预设分析组: "Wireless Earbuds Competition Analysis"
3. 展示Echo Buds vs 7个主要竞品的对比分析
4. 演示创建新的竞争分析组

### 第7-8分钟: AI优化建议演示
1. 点击 **"Optimization"** 菜单
2. 点击 **"Create Optimization Task"**
3. 选择产品和优化类型 (标题/价格/描述/图片)
4. 展示AI生成的优化建议和影响评分

### 第9-10分钟: 系统监控演示
1. 访问 http://localhost:8080/api/ops/system/status
2. 展示实时系统状态:
   - 🔧 各微服务健康状态
   - 🗄️ 数据库连接和表统计
   - 📊 Redis缓存状态
   - ⚡ 队列任务统计

---

## 🔧 技术架构讲解要点

### 1. 微服务架构 (1分钟)
```
📱 Next.js前端 → 🚪 API Gateway → 🔧 6个微服务
• Auth (JWT认证)        • Competitor (竞品分析)
• Product (产品管理)     • Optimization (AI优化)  
• Notification (通知)   • Ops (系统管理)
```

### 2. 异常检测架构 (2分钟) - **核心亮点**
```
📊 Apify API数据 → 💾 PostgreSQL → 🔧 轻量级触发器 (<5ms)
    ↓                              ↓
🗄️ 产品表更新 → 📡 pg_notify → 🎧 Go监听器 → 📨 Redis队列 → 👷 Worker → 📱 用户通知
```

**解释**:
- **实时性**: PostgreSQL触发器毫秒级检测
- **可靠性**: change_events审计表 + 补偿机制  
- **高性能**: 轻量级触发器避免数据库瓶颈
- **可扩展**: 支持水平扩展和海量数据

### 3. 数据设计亮点 (1分钟)
- **📊 分区表**: change_events按月分区，支持百万级记录
- **⚡ 智能索引**: 针对时间序列数据优化
- **🔄 自动维护**: 分区自动创建和清理

---

## 🧪 技术验证命令

### 验证真实数据获取
```bash
# 测试Apify API集成
go run scripts/test-apify-demo.go

# 期望输出: 
# ✅ 成功获取真实Amazon产品数据
# 📊 价格: $129.99, BSR: #1,234, 评分: 4.3⭐
```

### 验证异常检测
```bash
# 查看异常事件记录
psql "$SUPABASE_URL" -c "
SELECT event_type, change_percentage, old_value, new_value, created_at 
FROM change_events 
ORDER BY created_at DESC LIMIT 5;"

# 期望输出:
# price_change | 12.5 | 129.99 | 146.23 | 2025-01-15 10:30:00
```

### 验证队列系统
```bash
# 查看队列状态
curl http://localhost:8080/api/ops/system/status | jq '.queue'

# 期望输出:
# {
#   "critical": {"pending": 2, "active": 1, "completed": 100},
#   "default": {"pending": 5, "active": 2, "completed": 500}
# }
```

---

## 🎊 Demo成功标准

### ✅ 必须展示的功能
- [x] 用户认证和授权
- [x] 真实产品数据获取 (Apify API)
- [x] 实时异常检测 (价格>10%, BSR>30%)
- [x] 竞争对手分析
- [x] AI优化建议生成  
- [x] 系统监控面板

### ✅ 技术亮点证明
- [x] 微服务架构协同工作
- [x] PostgreSQL触发器实时检测
- [x] 分区表高性能设计
- [x] Redis队列异步处理
- [x] 企业级监控和日志

### ✅ 数据验证
- [x] 数据库表结构和记录
- [x] 异常事件追踪
- [x] 队列任务执行  
- [x] 实时通知生成

---

## 🚨 故障排除

### 如果Apify API失败
```bash
# 系统会自动降级为模拟数据，Demo仍然可以进行
# 查看日志确认降级
tail -f /var/log/amazon-pilot/worker.log
```

### 如果某个服务启动失败
```bash
# 查看端口占用
lsof -i :8888  # Auth服务

# 手动重启服务
./scripts/start-service.sh auth
```

### 如果数据库连接失败
```bash
# 检查PostgreSQL状态
psql "$SUPABASE_URL" -c "SELECT 1;"

# 检查.env文件中的SUPABASE_URL
cat .env
```

---

## 🎯 面试官问题准备

### Q: 系统如何处理高并发？
**A**: 微服务架构 + 异步队列 + PostgreSQL分区 + Redis缓存

### Q: 数据一致性如何保证？
**A**: PostgreSQL ACID事务 + 审计表 + 补偿机制

### Q: 如何监控系统健康？
**A**: Ops服务提供实时状态 + 结构化日志 + Prometheus指标

---

**🎊 Demo完成！这是一个生产级的企业Amazon监控工具！**