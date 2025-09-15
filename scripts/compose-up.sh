#!/usr/bin/env bash
set -euo pipefail

# 支持环境参数：local（默认）或 prod
ENV=${1:-local}
shift || true

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
COMPOSE_DIR="$ROOT_DIR/deployments/compose"
BASE_COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
ENV_FILE="$COMPOSE_DIR/.env"

# 根据环境选择配置文件
case $ENV in
  local|dev)
    COMPOSE_FILES="-f $BASE_COMPOSE_FILE -f $COMPOSE_DIR/docker-compose.local.yml"
    echo "[compose-up] 环境: 本地开发（包含 Caddy）"
    ;;
  prod|production)
    COMPOSE_FILES="-f $BASE_COMPOSE_FILE -f $COMPOSE_DIR/docker-compose.prod.yml"
    echo "[compose-up] 环境: 生产（不包含 Caddy，使用物理机 Caddy）"
    ;;
  *)
    echo "[compose-up] 错误: 未知环境 '$ENV'"
    echo "使用方法: $0 [local|prod] [docker-compose 参数]"
    echo "示例:"
    echo "  $0 local          # 启动本地环境"
    echo "  $0 prod           # 启动生产环境"
    echo "  $0 local --build  # 重新构建并启动"
    exit 1
    ;;
esac

echo "[compose-up] Using compose files: $COMPOSE_FILES"
echo "[compose-up] Using env file     : $ENV_FILE"

command -v docker >/dev/null 2>&1 || { echo "[compose-up] Docker is not installed or not in PATH"; exit 1; }

if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif docker-compose version >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "[compose-up] Neither 'docker compose' nor 'docker-compose' is available"
  exit 1
fi

echo "[compose-up] Building images..."
bash "$ROOT_DIR/scripts/build-docker-images.sh"

echo "[compose-up] Starting stack..."
$DC $COMPOSE_FILES --env-file "$ENV_FILE" up -d "$@"

echo "[compose-up] Stack is starting. Current status:"
$DC $COMPOSE_FILES --env-file "$ENV_FILE" ps

# 根据环境显示不同的访问信息
if [ "$ENV" = "local" ] || [ "$ENV" = "dev" ]; then
  echo ""
  echo "[compose-up] 本地访问地址:"
  echo "  前端: http://localhost/"
  echo "  API:  http://localhost/api/"
else
  echo ""
  echo "[compose-up] 生产服务端口:"
  echo "  前端: :4000 (需要物理机 Caddy 代理)"
  echo "  网关: :8080 (需要物理机 Caddy 代理)"
fi

echo ""
echo "[compose-up] Tip: tail logs with:"
echo "  $DC $COMPOSE_FILES --env-file $ENV_FILE logs -f"

