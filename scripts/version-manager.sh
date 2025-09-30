#!/bin/bash

# ClipFlow Pro 版本管理脚本
# 功能：从 pubspec.yaml 提取版本号，生成构建号

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"
BUILD_COUNTER_FILE="$PROJECT_ROOT/.build_counter"

# 检查 pubspec.yaml 是否存在
check_pubspec() {
    if [[ ! -f "$PUBSPEC_FILE" ]]; then
        echo -e "${RED}❌ 错误: 找不到 pubspec.yaml 文件${NC}"
        echo "   路径: $PUBSPEC_FILE"
        exit 1
    fi
}

# 从 pubspec.yaml 提取版本号
get_version_from_pubspec() {
    local version_line
    version_line=$(grep "^version:" "$PUBSPEC_FILE" | head -1)
    
    if [[ -z "$version_line" ]]; then
        echo -e "${RED}❌ 错误: 在 pubspec.yaml 中找不到版本号${NC}"
        exit 1
    fi
    
    # 提取版本号（去掉 version: 前缀和可能的构建号）
    local full_version
    full_version=$(echo "$version_line" | sed 's/^version: *//' | sed 's/+.*//')
    
    echo "$full_version"
}

# 获取当前日期（YYYYMMDD 格式）
get_current_date() {
    date +"%Y%m%d"
}

# 读取或初始化构建计数器
get_build_counter() {
    local current_date="$1"
    local counter_content=""
    local stored_date=""
    local stored_counter=0
    
    # 如果计数器文件存在，读取内容
    if [[ -f "$BUILD_COUNTER_FILE" ]]; then
        counter_content=$(cat "$BUILD_COUNTER_FILE")
        stored_date=$(echo "$counter_content" | cut -d'|' -f1)
        stored_counter=$(echo "$counter_content" | cut -d'|' -f2)
    fi
    
    # 如果是新的一天，重置计数器
    if [[ "$stored_date" != "$current_date" ]]; then
        stored_counter=1
    else
        # 同一天，递增计数器
        stored_counter=$((stored_counter + 1))
    fi
    
    # 保存新的计数器值
    echo "${current_date}|${stored_counter}" > "$BUILD_COUNTER_FILE"
    
    # 返回格式化的两位数计数器
    printf "%02d" "$stored_counter"
}

# 生成完整的构建号
generate_build_number() {
    local current_date
    local counter
    
    current_date=$(get_current_date)
    counter=$(get_build_counter "$current_date")
    
    echo "${current_date}${counter}"
}

# 生成完整的版本字符串（版本号+构建号）
generate_full_version() {
    local version
    local build_number
    
    version=$(get_version_from_pubspec)
    build_number=$(generate_build_number)
    
    echo "${version}+${build_number}"
}

# 显示版本信息
show_version_info() {
    local version
    local build_number
    local full_version
    
    version=$(get_version_from_pubspec)
    build_number=$(generate_build_number)
    full_version="${version}+${build_number}"
    
    echo -e "${BLUE}📋 版本信息${NC}"
    echo -e "   版本号: ${GREEN}$version${NC}"
    echo -e "   构建号: ${GREEN}$build_number${NC}"
    echo -e "   完整版本: ${GREEN}$full_version${NC}"
    echo ""
}

# 重置构建计数器
reset_build_counter() {
    if [[ -f "$BUILD_COUNTER_FILE" ]]; then
        rm "$BUILD_COUNTER_FILE"
        echo -e "${GREEN}✅ 构建计数器已重置${NC}"
    else
        echo -e "${YELLOW}⚠️  构建计数器文件不存在${NC}"
    fi
}

# 显示帮助信息
show_help() {
    echo "ClipFlow Pro 版本管理脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --version, -v          显示版本号（不含构建号）"
    echo "  --build-number, -b     显示构建号"
    echo "  --full-version, -f     显示完整版本（版本号+构建号）"
    echo "  --info, -i             显示详细版本信息"
    echo "  --reset-counter, -r    重置构建计数器"
    echo "  --help, -h             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --version           # 输出: 1.0.0"
    echo "  $0 --build-number      # 输出: 2024122801"
    echo "  $0 --full-version      # 输出: 1.0.0+2024122801"
    echo "  $0 --info              # 显示详细信息"
    echo ""
    echo "构建号格式: YYYYMMDD + 两位自增数字（每天从01开始）"
}

# 主函数
main() {
    # 检查 pubspec.yaml 文件
    check_pubspec
    
    # 如果没有参数，显示详细信息
    if [[ $# -eq 0 ]]; then
        show_version_info
        return 0
    fi
    
    # 处理命令行参数
    case "$1" in
        --version|-v)
            get_version_from_pubspec
            ;;
        --build-number|-b)
            generate_build_number
            ;;
        --full-version|-f)
            generate_full_version
            ;;
        --info|-i)
            show_version_info
            ;;
        --reset-counter|-r)
            reset_build_counter
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            echo "使用 --help 查看可用选项"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"