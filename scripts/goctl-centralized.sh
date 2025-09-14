#!/bin/bash

# goctl-centralized.sh
# 支持集中化 API 管理的 goctl monorepo 脚本
# API 定义集中在 api/openapi/ 目录，生成代码到 internal/ 目录

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示使用说明
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -s, --service <name>    服务名称 (必需)
    -a, --api <file>        API文件路径 (可选，默认从 api/openapi/{service}.api)
    -m, --module <name>     Go模块名称 (可选，默认从go.mod读取)
    -t, --template <dir>    自定义模板目录 (可选)
    -h, --help              显示帮助信息

Examples:
    $0 -s auth                                    # 使用 api/openapi/auth.api
    $0 -s product                                 # 使用 api/openapi/product.api  
    $0 -s auth -a api/openapi/auth-v2.api         # 指定API文件
    $0 -s user -m github.com/example/project     # 指定模块名

New Centralized API Management:
    📍 API定义位置: api/openapi/{service}.api (单一数据源)
    📦 生成代码位置: internal/{service}/
    
    开发流程:
    1. 修改 API: vim api/openapi/auth.api
    2. 生成代码: $0 -s auth  
    3. 实现逻辑: vim internal/auth/logic/...
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                SERVICE_NAME="$2"
                shift 2
                ;;
            -a|--api)
                API_FILE="$2"
                shift 2
                ;;
            -m|--module)
                MODULE_NAME="$2"
                shift 2
                ;;
            -t|--template)
                TEMPLATE_DIR="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# 验证参数
validate_args() {
    if [[ -z "$SERVICE_NAME" ]]; then
        print_error "服务名称参数是必需的 (-s|--service)"
        show_usage
        exit 1
    fi

    # 如果没有指定API文件，使用默认路径
    if [[ -z "$API_FILE" ]]; then
        API_FILE="api/openapi/${SERVICE_NAME}.api"
    fi

    if [[ ! -f "$API_FILE" ]]; then
        print_error "API文件不存在: $API_FILE"
        print_info "提示：请确保API定义文件存在于 api/openapi/ 目录"
        exit 1
    fi
}

# 获取Go模块名称
get_module_name() {
    if [[ -z "$MODULE_NAME" ]]; then
        if [[ -f "go.mod" ]]; then
            MODULE_NAME=$(grep '^module ' go.mod | awk '{print $2}')
            print_info "从 go.mod 获取模块名称: $MODULE_NAME"
        else
            print_error "未找到 go.mod 文件，请手动指定模块名称 (-m|--module)"
            exit 1
        fi
    fi
}

# 检查必要的命令
check_dependencies() {
    if ! command -v goctl &> /dev/null; then
        print_error "goctl 命令未找到，请先安装 go-zero"
        print_info "安装命令: go install github.com/zeromicro/go-zero/tools/goctl@latest"
        exit 1
    fi
}

# 检查文件是否应该覆盖
should_override_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # types.go 和 routes.go 总是覆盖
    if [[ "$filename" == "types.go" ]] || [[ "$filename" == "routes.go" ]]; then
        return 0  # 覆盖
    fi
    
    # 其他文件如果存在则跳过
    if [[ -e "$file_path" ]]; then
        return 1  # 跳过
    fi
    
    return 0  # 不存在的文件，可以创建
}

# 复制单个文件或目录
copy_item() {
    local source="$1"
    local target="$2"
    
    if [[ -d "$source" ]]; then
        # 处理目录
        mkdir -p "$target"
        for item in "$source"/*; do
            if [[ -e "$item" ]]; then
                local item_basename=$(basename "$item")
                copy_item "$item" "$target/$item_basename"
            fi
        done
    else
        # 处理文件
        if should_override_file "$target"; then
            cp "$source" "$target"
            print_info "📄 复制: $target"
        else
            print_info "⏭️  跳过: $target (已存在)"
        fi
    fi
}

# 生成代码
generate_code() {
    local temp_dir=$(mktemp -d)
    local target_dir="./internal/$SERVICE_NAME"
    
    print_info "🎯 API文件: $API_FILE"
    print_info "📂 临时目录: $temp_dir"
    print_info "📁 目标目录: $target_dir"
    
    # 构建 goctl 命令
    local goctl_cmd="goctl api go --api $API_FILE --dir $temp_dir --style=goZero"
    
    # 如果有自定义模板目录，添加模板参数
    if [[ -n "$TEMPLATE_DIR" ]]; then
        goctl_cmd="$goctl_cmd --home $TEMPLATE_DIR"
    fi
    
    print_info "🔧 执行: $goctl_cmd"
    
    # 执行 goctl 生成代码
    if ! $goctl_cmd; then
        print_error "goctl 命令执行失败"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 查找生成的代码目录
    local generated_internal="$temp_dir/internal"
    
    if [[ ! -d "$generated_internal" ]]; then
        print_error "未找到生成的internal目录"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 创建目标目录
    mkdir -p "$target_dir"
    
    print_info "📦 复制生成的代码到目标目录..."
    
    # 复制生成的内容到目标位置
    for item in "$generated_internal"/*; do
        if [[ -e "$item" ]]; then
            local basename=$(basename "$item")
            local target_path="$target_dir/$basename"
            copy_item "$item" "$target_path"
        fi
    done
    
    # 修改包导入路径，传递临时目录基名用于替换
    local temp_basename=$(basename "$temp_dir")
    fix_imports "$target_dir" "$temp_basename"
    
    # 修复生成的handler错误处理
    fix_error_handling "$target_dir"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    print_success "🎉 代码生成完成！"
    print_info "📍 API定义: $API_FILE"
    print_info "📦 生成位置: $target_dir"
}

# 修复导入路径
fix_imports() {
    local target_dir="$1"
    local temp_dir_name="$2"
    
    print_info "🔧 修复导入路径..."
    
    # 查找所有Go文件并替换导入路径
    find "$target_dir" -name "*.go" -type f | while read -r file; do
        # 先处理临时目录路径引用，如 "tmp.xxx/internal/xxx"
        if [[ -n "$temp_dir_name" ]]; then
            sed -i.bak "s|\"$temp_dir_name/internal/|\"$MODULE_NAME/internal/$SERVICE_NAME/|g" "$file"
        fi
        
        # 再处理相对路径引用，如 "./internal/xxx"  
        sed -i.bak "s|\"\\./internal/|\"$MODULE_NAME/internal/$SERVICE_NAME/|g" "$file"
        
        # 删除备份文件
        rm -f "$file.bak"
        print_info "✅ 修复: $file"
    done
}

# 修复生成的handler错误处理
fix_error_handling() {
    local target_dir="$1"
    local handler_dir="$target_dir/handler"
    
    if [[ ! -d "$handler_dir" ]]; then
        print_warning "Handler目录不存在: $handler_dir"
        return
    fi
    
    print_info "🔧 修复handler错误处理..."
    
    # 查找所有handler文件
    find "$handler_dir" -name "*Handler.go" -type f | while read -r file; do
        # 检查文件是否包含httpx.ErrorCtx
        if grep -q "httpx.ErrorCtx" "$file"; then
            print_info "🛠️  修复: $file"
            
            # 添加utils导入
            if ! grep -q "amazonpilot/internal/pkg/utils" "$file"; then
                sed -i.bak '/^import (/,/^)/ {
                    /^)/ i\
	"amazonpilot/internal/pkg/utils"
                }' "$file"
            fi
            
            # 替换错误处理
            sed -i.bak 's/httpx\.ErrorCtx(r\.Context(), w, err)/utils.HandleError(w, err)/g' "$file"
            
            # 删除备份文件
            rm -f "$file.bak"
            
            print_info "✅ 修复完成: $file"
        fi
    done
    
    print_success "🎉 Handler错误处理修复完成！"
}

# 主函数
main() {
    print_info "🚀 开始使用集中化 API 管理生成代码..."
    
    parse_args "$@"
    validate_args
    get_module_name
    check_dependencies
    generate_code
    
    print_success "✨ 代码生成完成！"
    
    # 显示使用提示
    cat << EOF

🎯 下一步开发建议:

📝 实现业务逻辑:
   vim internal/$SERVICE_NAME/logic/

🧰 使用共享工具包:
   • pkg/types          # 公共类型
   • internal/pkg/logger # 日志工具
   • internal/pkg/database # 数据库工具
   • internal/pkg/errors # 错误处理

🚀 启动服务:
   ./scripts/start-service.sh $SERVICE_NAME

EOF
}

# 执行主函数
main "$@"