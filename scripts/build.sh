#!/bin/bash

# ClipFlow Pro 构建脚本
# 支持开发和生产环境的构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}ClipFlow Pro 构建脚本${NC}"
    echo ""
    echo "用法: $0 [选项] <环境> <平台>"
    echo ""
    echo "环境:"
    echo "  dev, development    开发环境"
    echo "  prod, production    生产环境"
    echo ""
    echo "平台:"
    echo "  macos              macOS 应用"
    echo "  windows            Windows 应用"
    echo "  linux              Linux 应用"
    echo "  all                所有平台"
    echo ""
    echo "选项:"
    echo "  -h, --help         显示此帮助信息"
    echo "  -c, --clean        构建前清理"
    echo "  -r, --release      发布构建（默认）"
    echo "  -d, --debug        调试构建"
    echo ""
    echo "示例:"
    echo "  $0 dev macos       构建开发环境的 macOS 应用"
    echo "  $0 prod all        构建生产环境的所有平台应用"
    echo "  $0 -c dev macos    清理后构建开发环境的 macOS 应用"
}

# 默认参数
ENVIRONMENT=""
PLATFORM=""
BUILD_MODE="release"
CLEAN=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -r|--release)
            BUILD_MODE="release"
            shift
            ;;
        -d|--debug)
            BUILD_MODE="debug"
            shift
            ;;
        dev|development)
            ENVIRONMENT="dev"
            shift
            ;;
        prod|production)
            ENVIRONMENT="prod"
            shift
            ;;
        macos|windows|linux|all)
            PLATFORM="$1"
            shift
            ;;
        *)
            echo -e "${RED}错误: 未知参数 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}错误: 请指定环境 (dev/prod)${NC}"
    show_help
    exit 1
fi

if [[ -z "$PLATFORM" ]]; then
    echo -e "${RED}错误: 请指定平台 (macos/windows/linux/all)${NC}"
    show_help
    exit 1
fi

# 设置环境变量
case $ENVIRONMENT in
    dev)
        DART_DEFINE="ENVIRONMENT=development"
        ENV_NAME="开发环境"
        ;;
    prod)
        DART_DEFINE="ENVIRONMENT=production"
        ENV_NAME="生产环境"
        ;;
esac

echo -e "${BLUE}开始构建 ClipFlow Pro${NC}"
echo -e "${YELLOW}环境: $ENV_NAME${NC}"
echo -e "${YELLOW}平台: $PLATFORM${NC}"
echo -e "${YELLOW}模式: $BUILD_MODE${NC}"
echo ""

# 切换到项目根目录
cd "$(dirname "$0")/.."

# 清理（如果需要）
if [[ "$CLEAN" == true ]]; then
    echo -e "${YELLOW}清理项目...${NC}"
    flutter clean
    flutter pub get
fi

# 更新 macOS 配置（仅替换 include 行，保留头部注释与其他内容）
update_macos_config() {
    local config_file="macos/Runner/Configs/AppInfo.xcconfig"
    local dev_include_src="macos/Runner/Configs/AppInfo-Dev.xcconfig"
    local prod_include_src="macos/Runner/Configs/AppInfo-Prod.xcconfig"
    local include_line

    if [[ "$ENVIRONMENT" == "dev" ]]; then
        include_line='#include "AppInfo-Dev.xcconfig"'
        if [[ ! -f "$dev_include_src" ]]; then
            echo -e "${RED}❌ 缺少开发环境配置文件: $dev_include_src${NC}"
            exit 1
        fi
    else
        include_line='#include "AppInfo-Prod.xcconfig"'
        if [[ ! -f "$prod_include_src" ]]; then
            echo -e "${RED}❌ 缺少生产环境配置文件: $prod_include_src${NC}"
            exit 1
        fi
    fi

    if [[ -f "$config_file" ]]; then
        if grep -q '^#include "' "$config_file"; then
            # 仅替换 AppInfo 引用行
            sed -i '' 's|^#include "AppInfo-.*"|'"$include_line"'|' "$config_file"
        else
            printf "\n%s\n" "$include_line" >> "$config_file"
        fi
    else
        cat > "$config_file" << EOF
// Application-level settings for the Runner target.
//
// This configuration includes environment-specific settings.
// Use AppInfo-Dev.xcconfig for development and AppInfo-Prod.xcconfig for production.
$include_line
EOF
    fi
    echo -e "${GREEN}已更新 macOS 配置为 $ENV_NAME${NC}"
}

# 准备构建参数
prepare_build_args() {
    local base_args="--$BUILD_MODE --dart-define=$DART_DEFINE"
    
    # 如果设置了版本号和构建号环境变量，则添加它们
    if [ -n "$FLUTTER_BUILD_NAME" ] && [ -n "$FLUTTER_BUILD_NUMBER" ]; then
        echo -e "${BLUE}📋 使用指定版本信息:${NC}"
        echo -e "   版本号: ${GREEN}$FLUTTER_BUILD_NAME${NC}"
        echo -e "   构建号: ${GREEN}$FLUTTER_BUILD_NUMBER${NC}"
        base_args="$base_args --build-name=$FLUTTER_BUILD_NAME --build-number=$FLUTTER_BUILD_NUMBER"
    fi
    
    echo "$base_args"
}

# 构建 macOS
build_macos() {
    echo -e "${YELLOW}构建 macOS 应用...${NC}"
    update_macos_config
    
    local build_args
    build_args=$(prepare_build_args)
    
    flutter build macos $build_args
    
    echo -e "${GREEN}macOS 构建完成${NC}"
}

# 构建 Windows
build_windows() {
    echo -e "${YELLOW}构建 Windows 应用...${NC}"
    
    local build_args
    build_args=$(prepare_build_args)
    
    flutter build windows $build_args
    
    echo -e "${GREEN}Windows 构建完成${NC}"
}

# 构建 Linux
build_linux() {
    echo -e "${YELLOW}构建 Linux 应用...${NC}"
    
    local build_args
    build_args=$(prepare_build_args)
    
    flutter build linux $build_args
    
    echo -e "${GREEN}Linux 构建完成${NC}"
}

# 根据平台执行构建
case $PLATFORM in
    macos)
        build_macos
        ;;
    windows)
        build_windows
        ;;
    linux)
        build_linux
        ;;
    all)
        build_macos
        build_windows
        build_linux
        ;;
esac

echo ""
echo -e "${GREEN}✅ 构建完成！${NC}"
echo -e "${BLUE}构建产物位置:${NC}"

if [[ "$PLATFORM" == "macos" || "$PLATFORM" == "all" ]]; then
    echo -e "  macOS: build/macos/Build/Products/Release/ClipFlow Pro*.app"
fi

if [[ "$PLATFORM" == "windows" || "$PLATFORM" == "all" ]]; then
    echo -e "  Windows: build/windows/x64/runner/Release/"
fi

if [[ "$PLATFORM" == "linux" || "$PLATFORM" == "all" ]]; then
    echo -e "  Linux: build/linux/x64/release/bundle/"
fi