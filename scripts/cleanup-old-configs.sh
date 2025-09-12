#!/bin/bash

# 清理旧的配置文件脚本

echo "清理旧的配置文件..."

# 删除 internal 目录下的 etc 目录
echo "删除 internal/auth/etc/"
rm -rf internal/auth/etc/

echo "删除 internal/product/etc/"
rm -rf internal/product/etc/

echo "删除 internal/competitor/etc/"
rm -rf internal/competitor/etc/

echo "删除 internal/optimization/etc/"
rm -rf internal/optimization/etc/

echo "删除 internal/notification/etc/"
rm -rf internal/notification/etc/

# 删除旧的 main 文件 (如果存在)
echo "删除旧的 main 文件..."
rm -f internal/auth/auth.go
rm -f internal/product/product.go
rm -f internal/competitor/competitor.go
rm -f internal/optimization/optimization.go
rm -f internal/notification/notification.go

echo "清理完成！"
echo ""
echo "新的配置文件位置："
echo "  cmd/auth/etc/auth-api.yaml"
echo "  cmd/product/etc/product-api.yaml"
echo "  cmd/competitor/etc/competitor-api.yaml"
echo "  cmd/optimization/etc/optimization-api.yaml"
echo "  cmd/notification/etc/notification-api.yaml"
