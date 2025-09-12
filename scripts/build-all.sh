#!/bin/bash

# build-all.sh - 构建所有服务

echo "🏗️  构建所有服务..."

# 创建构建目录
mkdir -p bin

# 构建所有服务
failed_services=()

for service_dir in cmd/*; do
    if [[ -d "$service_dir" ]]; then
        service=$(basename "$service_dir")
        echo "📦 构建 $service..."
        
        # 构建服务
        if go build -o "bin/$service-service" "./$service_dir"; then
            echo "✅ $service 构建成功"
        else
            echo "⚠️  $service 构建失败，跳过"
            failed_services+=("$service")
        fi
    fi
done

echo ""
if [[ ${#failed_services[@]} -eq 0 ]]; then
    echo "🎉 所有服务构建完成！"
else
    echo "🎉 构建完成 (${#failed_services[@]} 个服务失败)"
    echo "⚠️  失败的服务: ${failed_services[*]}"
fi

echo "📂 二进制文件位置:"
ls -la bin/ | grep -v "^d" | awk '{print "  " $9 " (" $5 " bytes)"}'