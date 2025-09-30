#!/bin/bash

# ClipFlow Pro 环境切换脚本
# 快速切换开发和生产环境配置

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}ClipFlow Pro 环境切换脚本${NC}"
    echo ""
    echo "用法: $0 <环境>"
    echo ""
    echo "环境:"
    echo "  dev, development    切换到开发环境"
    echo "  prod, production    切换到生产环境"
    echo "  status              显示当前环境状态"
    echo ""
    echo "选项:"
    echo "  -h, --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 dev             切换到开发环境"
    echo "  $0 prod            切换到生产环境"
    echo "  $0 status          查看当前环境"
}

# 获取当前环境
get_current_env() {
    local config_file="macos/Runner/Configs/AppInfo.xcconfig"
    if [[ -f "$config_file" ]]; then
        if grep -q "^#include \"AppInfo-Dev.xcconfig\"" "$config_file"; then
            echo "dev"
        elif grep -q "^#include \"AppInfo-Prod.xcconfig\"" "$config_file"; then
            echo "prod"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# 显示当前状态
show_status() {
    echo -e "${BLUE}当前环境状态:${NC}"
    echo ""
    
    local config_file="macos/Runner/Configs/AppInfo.xcconfig"
    if [[ -f "$config_file" ]]; then
        if grep -q "^#include \"AppInfo-Dev.xcconfig\"" "$config_file"; then
            echo -e "  环境: ${GREEN}开发环境 (Development)${NC}"
            echo -e "  包名: ${YELLOW}com.clipflow.pro.dev${NC}"
            echo -e "  应用名: ${YELLOW}ClipFlow Pro Dev${NC}"
        elif grep -q "^#include \"AppInfo-Prod.xcconfig\"" "$config_file"; then
            echo -e "  环境: ${GREEN}生产环境 (Production)${NC}"
            echo -e "  包名: ${YELLOW}com.clipflow.pro${NC}"
            echo -e "  应用名: ${YELLOW}ClipFlow Pro${NC}"
        else
            echo -e "  环境: ${RED}未知${NC}"
            echo -e "  ${YELLOW}请运行环境切换命令来配置环境${NC}"
        fi
    else
        echo -e "  环境: ${RED}配置文件不存在${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}配置文件:${NC}"
    echo -e "  macOS: macos/Runner/Configs/AppInfo.xcconfig"
    echo -e "  Flutter: config/app_config.dart"
}

# 切换到开发环境
switch_to_dev() {
    echo -e "${YELLOW}切换到开发环境...${NC}"
    local config_file="macos/Runner/Configs/AppInfo.xcconfig"
    local dev_include_src="macos/Runner/Configs/AppInfo-Dev.xcconfig"
    local include_line='#include "AppInfo-Dev.xcconfig"'
    if [[ ! -f "$dev_include_src" ]]; then
        echo -e "${RED}❌ 缺少开发环境配置文件: $dev_include_src${NC}"
        exit 1
    fi
    if [[ -f "$config_file" ]]; then
        if grep -q '^#include "' "$config_file"; then
            # 仅替换 AppInfo 引用行，保留头部注释与其他内容
            sed -i '' 's|^#include "AppInfo-.*"|#include "AppInfo-Dev.xcconfig"|' "$config_file"
        else
            printf "\n%s\n" "$include_line" >> "$config_file"
        fi
    else
        cat > "$config_file" << EOF
// Application-level settings for the Runner target.
//
// This configuration includes environment-specific settings.
// Use AppInfo-Dev.xcconfig for development and AppInfo-Prod.xcconfig for production.

#include "AppInfo-Dev.xcconfig"
EOF
    fi
    echo -e "${GREEN}✅ 已切换到开发环境${NC}"
    echo ""
    show_status
}

# 切换到生产环境
switch_to_prod() {
    echo -e "${YELLOW}切换到生产环境...${NC}"
    local config_file="macos/Runner/Configs/AppInfo.xcconfig"
    local prod_include_src="macos/Runner/Configs/AppInfo-Prod.xcconfig"
    local include_line='#include "AppInfo-Prod.xcconfig"'
    if [[ ! -f "$prod_include_src" ]]; then
        echo -e "${RED}❌ 缺少生产环境配置文件: $prod_include_src${NC}"
        exit 1
    fi
    if [[ -f "$config_file" ]]; then
        if grep -q '^#include "' "$config_file"; then
            # 仅替换 AppInfo 引用行，保留头部注释与其他内容
            sed -i '' 's|^#include "AppInfo-.*"|#include "AppInfo-Prod.xcconfig"|' "$config_file"
        else
            printf "\n%s\n" "$include_line" >> "$config_file"
        fi
    else
        cat > "$config_file" << EOF
// Application-level settings for the Runner target.
//
// This configuration includes environment-specific settings.
// Use AppInfo-Dev.xcconfig for development and AppInfo-Prod.xcconfig for production.

#include "AppInfo-Prod.xcconfig"
EOF
    fi
    echo -e "${GREEN}✅ 已切换到生产环境${NC}"
    echo ""
    show_status
}

# 切换到项目根目录
cd "$(dirname "$0")/.."

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    dev|development)
        switch_to_dev
        ;;
    prod|production)
        switch_to_prod
        ;;
    status)
        show_status
        ;;
    "")
        echo -e "${RED}错误: 请指定环境${NC}"
        echo ""
        show_help
        exit 1
        ;;
    *)
        echo -e "${RED}错误: 未知环境 '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac