#!/bin/bash

# Amazon Pilot 部署脚本
set -e

echo "开始部署 Amazon Pilot..."

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 检查环境变量文件
if [ ! -f .env ]; then
    echo "环境变量文件 .env 不存在，请复制 env.example 并配置"
    cp env.example .env
    echo "请编辑 .env 文件并重新运行部署脚本"
    exit 1
fi

# 创建必要的目录
mkdir -p /opt/amazon-pilot
mkdir -p /var/log/caddy
mkdir -p /var/log/amazon-pilot

# 复制配置文件
cp docker-compose.yml /opt/amazon-pilot/
cp .env /opt/amazon-pilot/
cp Caddyfile /opt/amazon-pilot/
cp -r monitoring /opt/amazon-pilot/
cp -r scripts /opt/amazon-pilot/

# 进入部署目录
cd /opt/amazon-pilot

# 设置日志记录
chmod +x scripts/setup-logging.sh
./scripts/setup-logging.sh

# 停止现有服务
echo "停止现有服务..."
docker-compose down || true

# 清理旧镜像
echo "清理旧镜像..."
docker image prune -f

# 构建并启动服务
echo "构建并启动服务..."
docker-compose up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 30

# 健康检查
echo "执行健康检查..."
for i in {1..10}; do
    if curl -f http://localhost/health; then
        echo "服务启动成功！"
        break
    else
        echo "等待服务启动... ($i/10)"
        sleep 10
    fi
done

# 显示服务状态
echo "服务状态："
docker-compose ps

echo ""
echo "部署完成！"
echo "主站地址: https://amazon-pilot.phpman.top"
echo "监控界面: https://monitor.amazon-pilot.phpman.top"
echo "Grafana: https://grafana.amazon-pilot.phpman.top"
echo ""
echo "日志查看: ./scripts/log-viewer.sh"
echo "日志轮转: ./scripts/log-rotate.sh"
