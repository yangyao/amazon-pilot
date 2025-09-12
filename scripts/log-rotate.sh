#!/bin/bash

# 日志轮转脚本
# 用于管理 Docker 容器日志和 Caddy 日志

LOG_DIR="/var/log/amazon-pilot"
DOCKER_LOG_DIR="/var/lib/docker/containers"
CADDY_LOG_DIR="/var/log/caddy"

# 创建日志目录
mkdir -p $LOG_DIR

# 清理超过 7 天的日志文件
find $LOG_DIR -name "*.log" -type f -mtime +7 -delete

# 清理 Docker 容器日志
docker system prune -f

# 清理 Caddy 日志
find $CADDY_LOG_DIR -name "*.log" -type f -mtime +7 -delete

# 压缩旧日志文件
find $LOG_DIR -name "*.log" -type f -mtime +1 -exec gzip {} \;

echo "$(date): Log rotation completed" >> $LOG_DIR/rotation.log
