#!/bin/bash

# goctl-monorepo.sh
# 在 Monorepo 环境中使用 goctl 生成代码的脚本
# 解决 goctl 总是创建额外 internal 目录的问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -a, --api <file>        API文件路径 (必需)
    -s, --service <name>    服务名称 (必需)
    -m, --module <name>     Go模块名称 (可选，默认从go.mod读取)
    -t, --template <dir>    自定义模板目录 (可选)
    -h, --help              显示帮助信息

Examples:
    $0 -a auth.api -s auth
    $0 --api user.api --service user --module github.com/example/project

Description:
    此脚本解决了 goctl 在 Monorepo 项目中总是创建额外 internal 目录的问题。
    它会先在临时目录生成代码，然后将代码复制到正确的位置：./internal/<service>/
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--api)
                API_FILE="$2"
                shift 2
                ;;
            -s|--service)
                SERVICE_NAME="$2"
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
    if [[ -z "$API_FILE" ]]; then
        print_error "API文件参数是必需的 (-a|--api)"
        show_usage
        exit 1
    fi

    if [[ -z "$SERVICE_NAME" ]]; then
        print_error "服务名称参数是必需的 (-s|--service)"
        show_usage
        exit 1
    fi

    if [[ ! -f "$API_FILE" ]]; then
        print_error "API文件不存在: $API_FILE"
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
    local source_basename=$(basename "$source")
    
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
            print_info "已复制: $target"
        else
            print_info "跳过已存在文件: $target"
        fi
    fi
}

# 生成代码
generate_code() {
    local temp_dir=$(mktemp -d)
    local target_dir="./internal/$SERVICE_NAME"
    
    print_info "临时目录: $temp_dir"
    print_info "目标目录: $target_dir"
    
    # 构建 goctl 命令
    local goctl_cmd="goctl api go --api $API_FILE --dir $temp_dir --style=goZero"
    
    # 如果有自定义模板目录，添加模板参数
    if [[ -n "$TEMPLATE_DIR" ]]; then
        goctl_cmd="$goctl_cmd --home $TEMPLATE_DIR"
    fi
    
    print_info "执行 goctl 命令: $goctl_cmd"
    
    # 执行 goctl 生成代码
    if ! $goctl_cmd; then
        print_error "goctl 命令执行失败"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 查找生成的代码目录（goctl会在temp_dir下创建internal目录）
    local generated_internal="$temp_dir/internal"
    
    if [[ ! -d "$generated_internal" ]]; then
        print_error "未找到生成的internal目录"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 创建目标目录
    mkdir -p "$target_dir"
    
    print_info "复制生成的代码到目标目录..."
    
    # 复制内容，但要注意正确的目录结构
    # goctl 生成的结构是: temp_dir/internal/<files and dirs>
    # 我们需要复制到: ./internal/$SERVICE_NAME/<files and dirs>
    
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
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    print_success "代码生成完成！"
    print_info "生成的文件位于: $target_dir"
}

# 修复导入路径
fix_imports() {
    local target_dir="$1"
    local temp_dir_name="$2"
    
    print_info "修复导入路径..."
    
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
        print_info "已修复导入路径: $file"
    done
}

# 主函数
main() {
    print_info "开始执行 goctl-monorepo 脚本..."
    
    parse_args "$@"
    validate_args
    get_module_name
    check_dependencies
    generate_code
    
    print_success "脚本执行完成！"
}

# 执行主函数
main "$@"