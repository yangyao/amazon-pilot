#!/usr/bin/env bash
set -euo pipefail

# 支持环境参数：local（默认）或 prod
ENV=${1:-local}
shift || true

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
COMPOSE_DIR="$ROOT_DIR/deployments/compose"
BASE_COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
ENV_FILE="$ROOT_DIR/.env"

# 根据环境选择配置文件
case $ENV in
  local|dev)
    COMPOSE_FILES="-f $BASE_COMPOSE_FILE -f $COMPOSE_DIR/docker-compose.local.yml"
    echo "[compose-down] 环境: 本地开发"
    ;;
  prod|production)
    COMPOSE_FILES="-f $BASE_COMPOSE_FILE -f $COMPOSE_DIR/docker-compose.prod.yml"
    echo "[compose-down] 环境: 生产"
    ;;
  *)
    echo "[compose-down] 错误: 未知环境 '$ENV'"
    echo "使用方法: $0 [local|prod] [docker-compose down 参数]"
    exit 1
    ;;
esac

if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
elif docker-compose version >/dev/null 2>&1; then
  DC="docker-compose"
else
  echo "[compose-down] Neither 'docker compose' nor 'docker-compose' is available"
  exit 1
fi

FLAGS="${@:-}"

echo "[compose-down] Stopping stack (flags: '${FLAGS}')..."
$DC $COMPOSE_FILES --env-file "$ENV_FILE" down ${FLAGS}

echo "[compose-down] Done."

