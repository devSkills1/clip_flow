#!/bin/bash

# ClipFlow Pro 无签名构建脚本
# 用于在没有开发者证书的情况下构建应用

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SWITCH_ENV="$SCRIPT_DIR/switch-env.sh"

# 显示帮助信息
show_help() {
    echo "ClipFlow Pro 无签名构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    构建前清理"
    echo "  -d, --dmg      创建 DMG 安装包（优先使用 create-dmg，回退 hdiutil）"
    echo "  -o, --open     构建完成后打开输出目录"
    echo "  -e, --env ENV  指定环境 (dev|prod，默认: dev)"
    echo "  -p, --platform NAME 指定平台后缀（默认自动检测，如 macos/linux/windows）"
    echo ""
    echo "示例:"
    echo "  $0              # 基本构建 (开发环境)"
    echo "  $0 -c -d        # 清理后构建并创建 DMG"
    echo "  $0 --env prod   # 生产环境构建"
    echo "  $0 --clean --dmg --env prod  # 生产环境完整流程"
    echo "  $0 --dmg --platform darwin   # 指定平台后缀为 darwin"
}

# 解析命令行参数
CLEAN=false
CREATE_DMG=false
OPEN_OUTPUT=false
BUILD_ENV="dev"  # 默认开发环境
PLATFORM_SUFFIX=""

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
        -d|--dmg)
            CREATE_DMG=true
            shift
            ;;
        -o|--open)
            OPEN_OUTPUT=true
            shift
            ;;
        -e|--env)
            BUILD_ENV="$2"
            if [[ "$BUILD_ENV" != "dev" && "$BUILD_ENV" != "prod" ]]; then
                echo -e "${RED}❌ 无效的环境: $BUILD_ENV (只支持 dev 或 prod)${NC}"
                exit 1
            fi
            shift 2
            ;;
        -p|--platform)
            PLATFORM_SUFFIX="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 开始构建 ClipFlow Pro (无签名版本)${NC}"
echo ""

# 计算平台后缀（如未指定）
if [ -z "$PLATFORM_SUFFIX" ]; then
    uname_s=$(uname -s 2>/dev/null || echo "")
    case "$uname_s" in
        Darwin)
            PLATFORM_SUFFIX="macos"
            ;;
        Linux)
            PLATFORM_SUFFIX="linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM_SUFFIX="windows"
            ;;
        *)
            PLATFORM_SUFFIX="unknown"
            ;;
    esac
fi

# 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter 未安装或不在 PATH 中${NC}"
    exit 1
fi

# 检查打包依赖
if ! command -v hdiutil &> /dev/null && ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}❌ 未找到 hdiutil 或 create-dmg，无法创建 DMG（macOS 系统工具）${NC}"
    echo -e "${YELLOW}👉 可通过 Homebrew 安装 create-dmg：brew install create-dmg${NC}"
    exit 1
fi
if ! command -v shasum &> /dev/null; then
    echo -e "${YELLOW}⚠️  未找到 shasum，将无法生成 SHA256 校验文件${NC}"
fi

# 创建并清理 build 输出目录
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build"
echo -e "${YELLOW}📁 准备 build 输出目录...${NC}"

# 安全清理 build 文件夹
if [ -d "$BUILD_OUTPUT_DIR" ]; then
    # 只清理我们创建的文件，保留 Flutter 构建缓存
    echo -e "${YELLOW}🧹 清理旧的构建输出...${NC}"
    find "$BUILD_OUTPUT_DIR" -name "*.dmg" -delete 2>/dev/null || true
    find "$BUILD_OUTPUT_DIR" -name "*.sha256" -delete 2>/dev/null || true
    find "$BUILD_OUTPUT_DIR" -name "*.zip" -delete 2>/dev/null || true
    find "$BUILD_OUTPUT_DIR" -name "*.tar.gz" -delete 2>/dev/null || true
else
    mkdir -p "$BUILD_OUTPUT_DIR"
fi

# 切换到指定环境
echo -e "${YELLOW}📝 切换到 $BUILD_ENV 环境...${NC}"
if [ -f "$SWITCH_ENV" ]; then
    cd "$PROJECT_ROOT" && "$SWITCH_ENV" "$BUILD_ENV"
else
    echo -e "${YELLOW}⚠️  环境切换脚本不存在，使用默认配置${NC}"
fi

# 清理构建缓存
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}🧹 清理构建缓存...${NC}"
    flutter clean
    flutter pub get
fi

# 构建应用
echo -e "${YELLOW}🔨 构建 macOS 应用...${NC}"

# 准备构建参数（无签名构建）
if [ "$BUILD_ENV" = "prod" ]; then
    BUILD_ARGS="--dart-define=ENVIRONMENT=production --release"
else
    BUILD_ARGS="--dart-define=ENVIRONMENT=development --release"
fi

# 获取版本与构建号用于包名
VERSION_MANAGER="$PROJECT_ROOT/scripts/version-manager.sh"
if [ -f "$VERSION_MANAGER" ]; then
    BUILD_NUMBER=$("$VERSION_MANAGER" --build-number)
    PUBSPEC_VERSION=$("$VERSION_MANAGER" --version)
    VERSION="v$PUBSPEC_VERSION"
    echo -e "${BLUE}📋 获取版本与构建号: ${GREEN}$VERSION${NC} / ${GREEN}$BUILD_NUMBER${NC}"
else
    # 如果版本管理器不存在，使用时间戳作为构建号
    BUILD_NUMBER=$(date +"%Y%m%d%H%M")
    VERSION="v0.0.0"
    echo -e "${YELLOW}⚠️  版本管理器不存在，使用时间戳作为构建号: ${GREEN}$BUILD_NUMBER${NC}"
fi

# 如果设置了版本号和构建号环境变量，则使用它们
if [ -n "${FLUTTER_BUILD_NAME:-}" ] && [ -n "${FLUTTER_BUILD_NUMBER:-}" ]; then
    echo -e "${BLUE}📋 使用指定版本信息:${NC}"
    echo -e "   版本号: ${GREEN}$FLUTTER_BUILD_NAME${NC}"
    echo -e "   构建号: ${GREEN}$FLUTTER_BUILD_NUMBER${NC}"
    BUILD_ARGS="$BUILD_ARGS --build-name=$FLUTTER_BUILD_NAME --build-number=$FLUTTER_BUILD_NUMBER"
    # 使用指定的构建号更新包名构建号
    BUILD_NUMBER="$FLUTTER_BUILD_NUMBER"
    VERSION="v$FLUTTER_BUILD_NAME"
fi

flutter build macos $BUILD_ARGS

# 检查构建结果
if [ "$BUILD_ENV" = "prod" ]; then
    APP_PATH="build/macos/Build/Products/Release/ClipFlow Pro.app"
else
    APP_PATH="build/macos/Build/Products/Release/ClipFlow Pro Dev.app"
fi

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ 应用构建失败，未找到: $APP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 应用构建成功${NC}"
echo -e "   路径: $APP_PATH"

# 显示应用信息
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo -e "   大小: $APP_SIZE"

# 创建 DMG 安装包
if [ "$CREATE_DMG" = true ]; then
    echo -e "${YELLOW}📦 创建 DMG 安装包...${NC}"
    
    # 根据环境生成 DMG 名称（使用构建号）
if [ "$BUILD_ENV" = "prod" ]; then
    DMG_NAME="ClipFlowPro-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg"
    VOLUME_NAME="ClipFlow Pro"
else
    DMG_NAME="ClipFlowPro-Dev-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg"
    VOLUME_NAME="ClipFlow Pro Dev"
fi
    
    # DMG 输出路径
    DMG_OUTPUT_PATH="$BUILD_OUTPUT_DIR/$DMG_NAME"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$TEMP_DIR/"
    
    # 创建 DMG（优先使用 create-dmg，缺失时回退 hdiutil）
    if command -v create-dmg &> /dev/null; then
        create-dmg \
          --overwrite \
          --volname "$VOLUME_NAME" \
          --window-pos 200 120 \
          --window-size 800 400 \
          --icon-size 110 \
          --app-drop-link 600 200 \
          "$DMG_OUTPUT_PATH" "$TEMP_DIR"
    else
        hdiutil create -volname "$VOLUME_NAME" \
                       -srcfolder "$TEMP_DIR" \
                       -ov \
                       -format UDZO \
                       "$DMG_OUTPUT_PATH"
    fi
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    if [ -f "$DMG_OUTPUT_PATH" ]; then
        DMG_SIZE=$(du -sh "$DMG_OUTPUT_PATH" | cut -f1)
        echo -e "${GREEN}✅ DMG 创建成功${NC}"
        echo -e "   文件: $DMG_OUTPUT_PATH"
        echo -e "   大小: $DMG_SIZE"

        # 生成 SHA256 校验文件（若可用）
        if command -v shasum &> /dev/null; then
            shasum -a 256 "$DMG_OUTPUT_PATH" > "$DMG_OUTPUT_PATH.sha256"
            echo -e "${GREEN}✅ 已生成 SHA256 校验文件: $DMG_OUTPUT_PATH.sha256${NC}"
        fi
    else
        echo -e "${RED}❌ DMG 创建失败${NC}"
    fi
fi

# 显示安装说明
echo ""
echo -e "${BLUE}📋 安装说明${NC}"
echo -e "${YELLOW}注意：此应用未经 Apple 签名，首次运行可能需要额外步骤${NC}"
echo ""
echo "1. 推荐：右键点击应用 -> 选择 '打开' -> 在弹出对话框中再次点击 '打开'"
echo "2. 如果仍受隔离限制，可在终端执行（仅针对本应用）："
echo "   xattr -dr com.apple.quarantine \"$APP_PATH\""
echo "   然后重新打开应用"
echo ""
echo "3. 不推荐全局禁用 Gatekeeper（仅在问题排查时临时使用）"

# 打开输出目录
if [ "$OPEN_OUTPUT" = true ]; then
    echo -e "${YELLOW}📂 打开输出目录...${NC}"
    # 打开应用文件所在目录
    open "$(dirname "$APP_PATH")"
    # 如果创建了 DMG，打开 build 文件夹
    if [ "$CREATE_DMG" = true ] && [ -f "$DMG_OUTPUT_PATH" ]; then
        open "$BUILD_OUTPUT_DIR"
    fi
fi

echo -e "${GREEN}🎉 构建完成！${NC}"

# # 基本构建（个人使用）
# ./scripts/build-unsigned.sh

# # 完整构建（包含 DMG，用于分发）
# ./scripts/build-unsigned.sh --clean --dmg --open