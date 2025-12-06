#!/bin/bash

# ClipFlow 发布脚本
# 用于准备 GitHub Release 发布文件

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
VERSION_MANAGER="$SCRIPT_DIR/version-manager.sh"
SWITCH_ENV="$SCRIPT_DIR/switch-env.sh"
BUILD_UNSIGNED="$SCRIPT_DIR/build-unsigned.sh"

# 显示帮助信息
show_help() {
    echo "ClipFlow 发布脚本"
    echo ""
    echo "用法: $0 [version] [选项]"
    echo ""
    echo "参数:"
    echo "  version        版本号 (例如: v1.0.0, 可选，默认从 pubspec.yaml 获取)"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    构建前清理"
    echo "  --no-dmg       不创建 DMG 文件"
    echo "  --yes          无交互模式（CI 环境或跳过确认）"
    echo "  --platform NAME 指定平台后缀（默认自动检测，如 macos/linux/windows）"
    echo "  --notes-from-diff <tag> 依据 git log <tag>..HEAD 生成分类变更"
    echo "  --auto-version 自动从 pubspec.yaml 获取版本号"
    echo ""
    echo "示例:"
    echo "  $0                     # 自动获取版本号并发布"
    echo "  $0 v1.0.0              # 发布指定版本"
    echo "  $0 --auto-version      # 明确使用自动版本"
    echo "  $0 v1.0.0 --clean      # 清理后发布"
    echo "  $0 --clean --no-dmg    # 清理构建，不创建 DMG"
}

# 从 git diff 生成发布说明分类内容（设置全局变量 DIFF_*）
generate_notes_from_diff() {
    local tag="$1"
    DIFF_FEATURES=""; DIFF_FIXES=""; DIFF_DOCS=""; DIFF_PERF=""; DIFF_REFACTOR=""; DIFF_CHORE=""; DIFF_OTHER=""
    if [ -z "$tag" ]; then
        return 0
    fi
    local subjects
    subjects=$(git log "$tag"..HEAD --pretty=format:"%s" 2>/dev/null || echo "")
    if [ -z "$subjects" ]; then
        return 0
    fi
    while IFS= read -r line; do
        case "$line" in
            feat*|feature*) DIFF_FEATURES+="- ${line}\n" ;;
            fix*|bugfix*) DIFF_FIXES+="- ${line}\n" ;;
            docs*|doc*) DIFF_DOCS+="- ${line}\n" ;;
            perf*|performance*) DIFF_PERF+="- ${line}\n" ;;
            refactor*) DIFF_REFACTOR+="- ${line}\n" ;;
            chore*|build*|ci*) DIFF_CHORE+="- ${line}\n" ;;
            *) DIFF_OTHER+="- ${line}\n" ;;
        esac
    done <<< "$subjects"
}

# 获取版本号
get_version() {
    if [ -f "$VERSION_MANAGER" ]; then
        local pubspec_version
        pubspec_version=$("$VERSION_MANAGER" --version)
        echo "v$pubspec_version"
    else
        echo -e "${RED}❌ 错误：版本管理脚本不存在${NC}"
        exit 1
    fi
}

# 获取最后一次 commit 信息
get_last_commit_info() {
    local commit_subject
    local commit_body
    local commit_type=""
    local commit_scope=""
    local commit_description=""
    
    # 获取最后一次 commit 的主题行
    commit_subject=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
    
    # 获取最后一次 commit 的详细信息（排除主题行）
    commit_body=$(git log -1 --pretty=format:"%b" 2>/dev/null || echo "")
    
    if [ -z "$commit_subject" ]; then
        echo "无法获取 commit 信息"
        return 1
    fi
    
    # 解析 commit 主题行，提取类型、作用域和描述
    # 格式: type(scope): description 或 type: description
    if [[ "$commit_subject" == *": "* ]]; then
        # 提取冒号前的部分
        local prefix="${commit_subject%%: *}"
        commit_description="${commit_subject#*: }"
        
        # 检查是否有作用域
        if [[ "$prefix" == *"("*")" ]]; then
            commit_type="${prefix%%(*}"
            commit_scope="${prefix#*(}"
            commit_scope="${commit_scope%)}"
        else
            commit_type="$prefix"
            commit_scope=""
        fi
    else
        # 如果不符合约定式提交格式，将整个主题作为描述
        commit_type=""
        commit_scope=""
        commit_description="$commit_subject"
    fi
    
    # 输出结果（用特殊分隔符分隔各部分）
    echo "${commit_type}|${commit_scope}|${commit_description}|${commit_body}"
}

# 根据 commit 类型分类变更
categorize_commit() {
    local commit_type="$1"
    local commit_scope="$2"
    local commit_description="$3"
    local commit_body="$4"
    
    case "$commit_type" in
        feat|feature)
            echo "new_features"
            ;;
        fix|bugfix)
            echo "bug_fixes"
            ;;
        docs|doc)
            echo "documentation"
            ;;
        style)
            echo "style_changes"
            ;;
        refactor)
            echo "refactoring"
            ;;
        test|tests)
            echo "testing"
            ;;
        chore)
            echo "maintenance"
            ;;
        perf|performance)
            echo "performance"
            ;;
        revert)
            echo "reverts"
            ;;
        *)
            echo "other_changes"
            ;;
    esac
}

# 格式化 commit 信息为发布说明条目
format_commit_for_release() {
    local commit_type="$1"
    local commit_scope="$2"
    local commit_description="$3"
    local commit_body="$4"
    
    local formatted_entry=""
    
    # 构建条目
    if [ -n "$commit_scope" ]; then
        formatted_entry="- **${commit_scope}**: ${commit_description}"
    else
        formatted_entry="- ${commit_description}"
    fi
    
    # 如果有详细的 commit body，添加到条目中
    if [ -n "$commit_body" ] && [ "$commit_body" != "$commit_description" ]; then
        # 将 commit body 的每一行都添加为子项
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                # 如果行已经以 - 开头，直接添加缩进，否则添加 - 前缀
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]* ]]; then
                    formatted_entry="${formatted_entry}\n  ${line}"
                else
                    formatted_entry="${formatted_entry}\n  - ${line}"
                fi
            fi
        done <<< "$commit_body"
    fi
    
    echo -e "$formatted_entry"
}

# 检查参数
VERSION=""
AUTO_VERSION=false

# 如果第一个参数不是选项，则认为是版本号
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    VERSION=$1
    shift
elif [[ $# -eq 0 ]]; then
    # 没有参数时自动获取版本
    AUTO_VERSION=true
fi

# 解析选项
CLEAN=false
CREATE_DMG=true
NON_INTERACTIVE=false
PLATFORM_SUFFIX=""
NOTES_DIFF_TAG=""

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
        --no-dmg)
            CREATE_DMG=false
            shift
            ;;
        --yes)
            NON_INTERACTIVE=true
            shift
            ;;
        --platform)
            PLATFORM_SUFFIX="$2"
            shift 2
            ;;
        --notes-from-diff)
            NOTES_DIFF_TAG="$2"
            shift 2
            ;;
        --auto-version)
            AUTO_VERSION=true
            shift
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 确定最终版本号
if [ -z "$VERSION" ] || [ "$AUTO_VERSION" = true ]; then
    VERSION=$(get_version)
    echo -e "${BLUE}📋 自动获取版本号: $VERSION${NC}"
fi

echo -e "${BLUE}🚀 准备发布 ClipFlow $VERSION${NC}"
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

# 检查版本号格式
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠️  版本号格式建议: vX.Y.Z (例如: v1.0.0)${NC}"
fi

# 检查 Git 状态
if [ -d ".git" ]; then
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}⚠️  检测到未提交的更改，建议先提交代码${NC}"
        if [ "$NON_INTERACTIVE" = true ] || [ -n "${CI:-}" ]; then
            echo -e "${BLUE}📋 无交互模式：自动继续${NC}"
        else
            read -p "是否继续？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
fi

# 1. 切换到生产环境
echo -e "${YELLOW}📝 切换到生产环境...${NC}"
if [ -f "$SWITCH_ENV" ]; then
    cd "$PROJECT_ROOT" && "$SWITCH_ENV" prod
else
    echo -e "${YELLOW}⚠️  环境切换脚本不存在，使用默认配置${NC}"
fi

# 2. 获取完整版本信息
echo -e "${YELLOW}📋 获取版本信息...${NC}"
if [ -f "$VERSION_MANAGER" ]; then
    FULL_VERSION=$("$VERSION_MANAGER" --full-version)
    BUILD_NUMBER=$("$VERSION_MANAGER" --build-number)
    echo -e "   版本号: ${GREEN}${VERSION#v}${NC}"
    echo -e "   构建号: ${GREEN}$BUILD_NUMBER${NC}"
    echo -e "   完整版本: ${GREEN}$FULL_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  版本管理脚本不存在，使用默认构建号${NC}"
    FULL_VERSION="${VERSION#v}+$(date +%Y%m%d)01"
    BUILD_NUMBER="$(date +%Y%m%d)01"
fi

# 3. 清理旧的发布文件
echo -e "${YELLOW}🧹 清理旧的发布文件...${NC}"
if [ -d "$PROJECT_ROOT/build" ]; then
    # 清理旧的 DMG 文件和相关文件
    rm -f "$PROJECT_ROOT/build"/*.dmg
    rm -f "$PROJECT_ROOT/build"/*.dmg.sha256
    rm -f "$PROJECT_ROOT/build"/release-notes-*.md
    echo -e "${GREEN}✅ 已清理旧的发布文件${NC}"
else
    echo -e "${BLUE}📁 build 文件夹不存在，将在构建时创建${NC}"
fi

# 4. 构建应用
echo -e "${YELLOW}🔨 构建应用...${NC}"
BUILD_ARGS=""
if [ "$CLEAN" = true ]; then
    BUILD_ARGS="$BUILD_ARGS --clean"
fi
if [ "$CREATE_DMG" = true ]; then
    BUILD_ARGS="$BUILD_ARGS --dmg"
fi

# 传递完整版本号给构建脚本
export FLUTTER_BUILD_NAME="${VERSION#v}"
export FLUTTER_BUILD_NUMBER="$BUILD_NUMBER"

if [ -f "$BUILD_UNSIGNED" ]; then
    # 将平台后缀传递给构建脚本，保证命名一致
    cd "$PROJECT_ROOT" && "$BUILD_UNSIGNED" --env prod $BUILD_ARGS --platform "$PLATFORM_SUFFIX"
else
    echo -e "${RED}❌ 构建脚本不存在${NC}"
    exit 1
fi

# 5. 查找并重命名文件
echo -e "${YELLOW}📦 准备发布文件...${NC}"

# 定义构建目录
BUILD_DIR="$PROJECT_ROOT/build"

# 查找 DMG 文件（统一命名后无需重命名）
if [ "$CREATE_DMG" = true ]; then
    TARGET_DMG="$BUILD_DIR/ClipFlow-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg"
    if [ -f "$TARGET_DMG" ]; then
        echo -e "${GREEN}✅ 找到 DMG 文件: $TARGET_DMG${NC}"
        # 若校验文件不存在则生成
        if [ ! -f "$TARGET_DMG.sha256" ]; then
            if command -v shasum &> /dev/null; then
                shasum -a 256 "$TARGET_DMG" > "$TARGET_DMG.sha256"
                echo -e "${GREEN}✅ 已生成 SHA256 校验和${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  未找到 DMG 文件：$TARGET_DMG${NC}"
    fi
fi

# 查找应用文件
APP_PATH="build/macos/Build/Products/Release/ClipFlow.app"
if [ -d "$APP_PATH" ]; then
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    echo -e "${GREEN}✅ 应用文件: $APP_PATH (大小: $APP_SIZE)${NC}"
fi

# 6. 显示发布文件列表
echo ""
echo -e "${BLUE}📁 发布文件列表:${NC}"
if [ "$CREATE_DMG" = true ]; then
    ls -la "$BUILD_DIR"/ClipFlow-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.* 2>/dev/null || echo "  (未找到 DMG 文件)"
fi
if [ -d "$APP_PATH" ]; then
    echo "  应用文件: $APP_PATH"
fi

# 7. 生成发布说明模板
RELEASE_NOTES="$BUILD_DIR/release-notes-$VERSION-$BUILD_NUMBER.md"

# 获取最后一次 commit 信息
echo -e "${BLUE}📝 正在获取最后一次 commit 信息...${NC}"
COMMIT_INFO=$(get_last_commit_info)

if [ $? -eq 0 ] && [ -n "$COMMIT_INFO" ]; then
    # 解析 commit 信息
    IFS='|' read -r COMMIT_TYPE COMMIT_SCOPE COMMIT_DESCRIPTION COMMIT_BODY <<< "$COMMIT_INFO"
    
    # 分类 commit
    COMMIT_CATEGORY=$(categorize_commit "$COMMIT_TYPE" "$COMMIT_SCOPE" "$COMMIT_DESCRIPTION" "$COMMIT_BODY")
    
    # 格式化 commit 信息
    FORMATTED_COMMIT=$(format_commit_for_release "$COMMIT_TYPE" "$COMMIT_SCOPE" "$COMMIT_DESCRIPTION" "$COMMIT_BODY")
    
    echo -e "${GREEN}✅ 已获取 commit 信息: ${COMMIT_TYPE}${COMMIT_SCOPE:+($COMMIT_SCOPE)}: $COMMIT_DESCRIPTION${NC}"
else
    echo -e "${YELLOW}⚠️  无法获取 commit 信息，使用默认模板${NC}"
    COMMIT_CATEGORY=""
    FORMATTED_COMMIT=""
fi

# 生成发布说明模板
cat > "$RELEASE_NOTES" << EOF
# ClipFlow $VERSION

## 📥 下载安装

### 安装说明（未签名版本）

1. 下载 \`ClipFlow-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg\`
2. 双击 DMG 文件挂载（macOS）或解压相应包（其他平台）
3. 将 \`ClipFlow\` 拖拽到 \`Applications\` 文件夹（macOS）或按平台指引安装
4. 首次运行时：
   - 如果提示"无法打开"，请右键点击应用选择"打开"
   - 或在终端执行：\`xattr -dr com.apple.quarantine "/Applications/ClipFlow.app"\`（针对本应用解除隔离）

## ✨ 新功能
EOF

# 基于 diff 生成分类内容（如提供）
generate_notes_from_diff "$NOTES_DIFF_TAG"
# 根据 commit 类型添加相应内容
if [ -n "$DIFF_FEATURES" ]; then
    echo "$DIFF_FEATURES" >> "$RELEASE_NOTES"
elif [ "$COMMIT_CATEGORY" = "new_features" ] && [ -n "$FORMATTED_COMMIT" ]; then
    echo "$FORMATTED_COMMIT" >> "$RELEASE_NOTES"
else
    echo "- [ ] 功能1描述" >> "$RELEASE_NOTES"
    echo "- [ ] 功能2描述" >> "$RELEASE_NOTES"
fi

cat >> "$RELEASE_NOTES" << EOF

## 🐛 修复问题
EOF

if [ -n "$DIFF_FIXES" ]; then
    echo "$DIFF_FIXES" >> "$RELEASE_NOTES"
elif [ "$COMMIT_CATEGORY" = "bug_fixes" ] && [ -n "$FORMATTED_COMMIT" ]; then
    echo "$FORMATTED_COMMIT" >> "$RELEASE_NOTES"
else
    echo "- [ ] 问题1修复" >> "$RELEASE_NOTES"
    echo "- [ ] 问题2修复" >> "$RELEASE_NOTES"
fi

# 如果是其他类型的 commit，添加到相应分类
if [ -n "$FORMATTED_COMMIT" ] && [ "$COMMIT_CATEGORY" != "new_features" ] && [ "$COMMIT_CATEGORY" != "bug_fixes" ]; then
    case "$COMMIT_CATEGORY" in
        "performance")
            cat >> "$RELEASE_NOTES" << EOF

## ⚡ 性能优化
$FORMATTED_COMMIT
EOF
            ;;
        "documentation")
            cat >> "$RELEASE_NOTES" << EOF

## 📚 文档更新
$FORMATTED_COMMIT
EOF
            ;;
        "style_changes")
            cat >> "$RELEASE_NOTES" << EOF

## 🎨 样式改进
$FORMATTED_COMMIT
EOF
            ;;
        "refactoring")
            cat >> "$RELEASE_NOTES" << EOF

## 🔧 代码重构
$FORMATTED_COMMIT
EOF
            ;;
        "testing")
            cat >> "$RELEASE_NOTES" << EOF

## 🧪 测试改进
$FORMATTED_COMMIT
EOF
            ;;
        "maintenance")
            cat >> "$RELEASE_NOTES" << EOF

## 🔧 维护更新
$FORMATTED_COMMIT
EOF
            ;;
        *)
            cat >> "$RELEASE_NOTES" << EOF

## 🔄 其他变更
$FORMATTED_COMMIT
EOF
            ;;
    esac
fi

# 如果 diff 中包含其他分类，追加到发布说明
if [ -n "$DIFF_DOCS" ]; then
    cat >> "$RELEASE_NOTES" << EOF

## 📚 文档更新
$DIFF_DOCS
EOF
fi
if [ -n "$DIFF_PERF" ]; then
    cat >> "$RELEASE_NOTES" << EOF

## ⚡ 性能优化
$DIFF_PERF
EOF
fi
if [ -n "$DIFF_REFACTOR" ]; then
    cat >> "$RELEASE_NOTES" << EOF

## 🔧 代码重构
$DIFF_REFACTOR
EOF
fi
if [ -n "$DIFF_CHORE" ]; then
    cat >> "$RELEASE_NOTES" << EOF

## 🧰 维护与杂项
$DIFF_CHORE
EOF
fi
if [ -n "$DIFF_OTHER" ]; then
    cat >> "$RELEASE_NOTES" << EOF

## 🔄 其他变更
$DIFF_OTHER
EOF
fi

cat >> "$RELEASE_NOTES" << EOF

## 📋 系统要求
- macOS 10.15 或更高版本
- 64位处理器

## 🔒 安全说明
本应用是开源项目，代码完全透明。安全警告仅因为缺乏 Apple 开发者证书，不影响应用功能和安全性。

## 📞 技术支持
如果遇到安装问题，请：
1. 查看 [代码签名指南](docs/code-signing-guide.md)
2. 提交 [Issue](../../issues)
EOF

echo -e "${GREEN}✅ 已生成发布说明模板: $RELEASE_NOTES${NC}"

# 8. 显示下一步操作
echo ""
echo -e "${BLUE}📋 下一步操作:${NC}"
echo "1. 编辑发布说明: $RELEASE_NOTES"
echo "2. 创建 GitHub Release: $VERSION"
if [ "$CREATE_DMG" = true ]; then
    echo "3. 上传文件: build/ClipFlow-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg"
    echo "4. 上传校验和: build/ClipFlow-$VERSION-$BUILD_NUMBER-$PLATFORM_SUFFIX.dmg.sha256"
fi
echo "5. 复制发布说明内容到 GitHub"

# 9. Git 标签建议
if [ -d ".git" ]; then
    echo ""
    echo -e "${BLUE}🏷️  Git 标签建议:${NC}"
    echo "git tag -a $VERSION -m \"Release $VERSION\""
    echo "git push origin $VERSION"
fi

echo ""
echo -e "${GREEN}🎉 发布准备完成！${NC}"