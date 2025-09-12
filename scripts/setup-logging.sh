#!/bin/bash

# 设置日志记录环境

set -e

echo "设置 Amazon Pilot 日志记录环境..."

# 创建日志目录
sudo mkdir -p /var/log/amazon-pilot
sudo mkdir -p /var/log/caddy

# 设置权限
sudo chown -R $USER:$USER /var/log/amazon-pilot
sudo chown -R caddy:caddy /var/log/caddy

# 创建日志轮转配置
sudo tee /etc/logrotate.d/amazon-pilot > /dev/null <<EOF
/var/log/amazon-pilot/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose restart
    endscript
}

/var/log/caddy/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 caddy caddy
    postrotate
        systemctl reload caddy
    endscript
}
EOF

# 设置脚本权限
chmod +x scripts/log-rotate.sh
chmod +x scripts/log-viewer.sh

# 创建定时任务
(crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/scripts/log-rotate.sh") | crontab -

echo "日志记录环境设置完成！"
echo ""
echo "使用方法："
echo "1. 查看日志: ./scripts/log-viewer.sh"
echo "2. 手动轮转日志: ./scripts/log-rotate.sh"
echo "3. 日志文件位置: /var/log/amazon-pilot/"
echo "4. Caddy 日志位置: /var/log/caddy/"
