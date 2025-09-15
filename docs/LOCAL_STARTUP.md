# 本地启动与数据库还原指南

本文档覆盖两种启动方式，并给出丢失 PostgreSQL 容器后的数据库还原步骤：

- 方式A：本地（非 Docker）启动全部服务
- 方式B：Docker Compose 一键启动全栈
- 数据库丢失后，基于 Go 代码（GORM 模型）重建表结构与初始化数据

建议先通读 docs/README.md、docs/ARCHITECTURE.md 与 docs/DATABASE_DESIGN*.md 以了解整体架构与数据设计。

## 前置要求

- Go 1.21+
- Node.js 18+ 与 pnpm（前端：Next.js 14 + TS）
- Docker 24+ 与 docker-compose v2（用于方式B或本地起 Postgres/Redis）

## 环境变量

可参考根目录 `.env` 与 `env.example`，关键项：

- `DATABASE_DSN`：例如 `postgresql://postgres:amazon123@localhost:5432/amazon_pilot`
- `REDIS_HOST`/`REDIS_PORT`
- `APIFY_API_TOKEN`、`OPENAI_API_KEY`（如需抓数/生成报告）

## 方式A：本地（非 Docker）启动

1) 启动本地 PostgreSQL 与 Redis（任选其一）
- 使用 Docker 起 Postgres/Redis（推荐）：
  - Postgres: `docker run -d --name local-pg -e POSTGRES_PASSWORD=amazon123 -e POSTGRES_DB=amazon_pilot -p 5432:5432 postgres:15-alpine`
  - Redis: `docker run -d --name local-redis -p 6379:6379 redis:7-alpine --appendonly yes`
- 或使用系统服务（brew/apt）安装并启动。

2) 初始化数据库（单文件版本，已合并）
- 仅需执行一个 SQL：
  - `deployments/compose/init-db/000_init.sql`
- 手动执行示例：
  - `psql -h localhost -U postgres -d amazon_pilot -f deployments/compose/init-db/000_init.sql`

说明：历史表已在 000_init.sql 中使用 PostgreSQL 原生分区（按 recorded_at 按月分区），并包含自动创建未来12个月分区的函数；已移除 Supabase RLS 和 user_settings 相关表。

3) 构建与启动后端服务
- 一次性构建：`bash scripts/build-all.sh` （产物位于 `bin/`）
- 使用服务管理脚本：`bash scripts/service-manager.sh start`（支持 `status|stop|restart|list|monitor`）
  - 避免手动 `go run`，统一用管理脚本。

4) 启动前端
- `cd frontend && pnpm install && pnpm dev`（默认端口 4000）

## 方式B：Docker Compose 全栈启动

1) 一次性构建镜像
- `bash scripts/build-all.sh`

2) 启动全栈
- `docker-compose -f deployments/compose/docker-compose.yml up -d`

说明：Docker Compose 已将 `deployments/compose/init-db` 挂载到 Postgres 容器 `/docker-entrypoint-initdb.d`，首次启动（数据目录为空时）会自动执行目录内所有 `.sql`，现仅有 `000_init.sql`，会一次性建表（含分区与函数）并写入演示用户。

3) 访问
- 网关（API Gateway）：`http://localhost:8080`
- 各服务端口：auth(8001)、product(8002)、competitor(8003)、optimization(8004)
- 前端：`http://localhost:4000`
- Redis Dashboard（如有）：`http://localhost:5555`

## 数据库还原（你不小心删除了 pgsql 容器）

若之前的 PostgreSQL 容器和数据卷都丢失，请按以下步骤重新初始化：

方式B（Docker Compose）建议：
- 停止并清理旧资源：
  - `docker-compose -f deployments/compose/docker-compose.yml down -v`（包含删除数据卷）
- 重新启动：
  - `docker-compose -f deployments/compose/docker-compose.yml up -d`
- 首次启动会自动执行 `init-db` 文件夹内 SQL，重建与当前 Go 代码一致的表结构，并插入演示用户。

方式A（本地）建议：
- 重新创建数据库并执行 `deployments/compose/init-db/000_init.sql`。
- 如需覆盖已有库，可先：
  - `psql -h localhost -U postgres -c "DROP DATABASE IF EXISTS amazon_pilot;"`
  - `psql -h localhost -U postgres -c "CREATE DATABASE amazon_pilot;"`

## 模型与表结构对齐说明（关键点）

-- 所有表以 `internal/pkg/models` 下的 GORM 标签为准：
  - `users`
  - `products`、`tracked_products`
  - 历史表：`product_price_history`、`product_ranking_history`、`product_review_history`、`product_buybox_history`
  - 异常事件：`product_anomaly_events`（通知不落库）
  - 竞品分析：`competitor_analysis_groups`、`competitor_products`、`competitor_analysis_results`
  - 优化：`optimization_analyses`、`optimization_suggestions`
- 新增或修正：
  - 取消 notifications 表（不落库）
  - 新增 `product_review_history`、`product_buybox_history`、`product_anomaly_events`
  - 已在 `000_init.sql` 中启用 `pgcrypto`，使用 `gen_random_uuid()`

## 验证检查

初始化完成后，可用以下 SQL 快速检查：

```sql
SELECT tablename FROM pg_tables 
WHERE schemaname='public' AND tablename IN (
  'users','products','tracked_products',
  'product_price_history','product_ranking_history','product_review_history','product_buybox_history',
  'product_anomaly_events',
  'competitor_analysis_groups','competitor_products','competitor_analysis_results',
  'optimization_analyses','optimization_suggestions'
);
```

如需我帮你自动执行上述初始化或验证，请告知你当前采用的启动方式（本地或 Docker），以及数据库连接信息/容器可用性。 
