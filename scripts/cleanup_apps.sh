#!/bin/bash

# ClipFlow 应用清理脚本（增强版）
# - 扩大搜索范围：系统/用户应用目录以及项目构建产物
# - 清理应用支持/偏好/缓存目录
# - 重建 LaunchServices 数据库，移除系统残留的应用索引
# - Spotlight 索引处理默认跳过；如需处理，加 --spotlight 并在提示确认后执行
# - 避免使用被禁用命令（如 killall），改用 AppleScript 重启 Finder

set -euo pipefail

echo "🧹 ClipFlow 应用清理脚本（增强版）"
echo "=============================="

# 解析项目根目录（脚本所在目录的上一级）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 目标 Bundle 标识与名称关键词
# 环境化的 Bundle ID（支持通过环境变量或参数传入）
RELEASE_BUNDLE_ID="${APP_RELEASE_BUNDLE_ID:-com.clipflow.app}"
DEV_BUNDLE_ID="${APP_DEV_BUNDLE_ID:-com.clipflow.app.dev}"
ENV="${APP_ENV:-all}"
DRY_RUN=false
SPOTLIGHT=false
VERBOSE=false
# 参数解析：-e|--env 指定环境（release|dev）；-n|--dry-run 预演模式说明：
# - 通过 --dry-run 或 -n 启用，仅预览将执行的删除操作，不实际删除任何文件/目录
# - 适用范围：.app 包、Application Support、Preferences、Caches、Logs 的删除动作均变为“预览”
# - 保留的系统操作：列出匹配项与删除确认提示；LaunchServices 刷新始终执行；Spotlight 处理默认跳过（需 --spotlight 才会提示并选择执行）；Finder 重启始终执行
# - 如需让 dry-run 完全无副作用（不刷新索引、不重启 Finder），可继续调整脚本将这些系统操作也纳入 dry-run 保护
# - 使用示例：scripts/cleanup_apps.sh --env all --dry-run 或 scripts/cleanup_apps.sh --env dev --dry-run；如需处理 Spotlight：scripts/cleanup_apps.sh --spotlight
# - 环境选择：--env 支持 release|dev|all（默认 all，同时覆盖两套 Bundle ID）
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENV="${2:-$ENV}"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -s|--spotlight)
      SPOTLIGHT=true
      shift
      ;;
    *)
      echo "Usage: $0 [-e|--env release|dev|all] [-n|--dry-run]"
      exit 1
      ;;
  esac
done
if [[ "$ENV" != "release" && "$ENV" != "dev" && "$ENV" != "all" ]]; then
  echo "❌ 无效环境: ${ENV}（仅支持 release、dev 或 all）"
  exit 1
fi
if [[ "$ENV" == "dev" ]]; then
  BUNDLE_IDS=("$DEV_BUNDLE_ID")
elif [[ "$ENV" == "release" ]]; then
  BUNDLE_IDS=("$RELEASE_BUNDLE_ID")
else
  BUNDLE_IDS=("$RELEASE_BUNDLE_ID" "$DEV_BUNDLE_ID")
fi
echo "🔧 当前目标环境: ${ENV}（Bundle IDs: ${BUNDLE_IDS[*]}，dry-run: ${DRY_RUN}，verbose: ${VERBOSE}，spotlight: ${SPOTLIGHT}）"
NAME_PATTERNS=("*ClipFlow*.app" "*clip_flow*.app" "*ClipFlow*Dev*.app" "*ClipFlow*Debug*.app")

# 搜索应用的函数
find_apps() {
  local results=()
  local search_paths=(
    "/Applications"
    "$HOME/Applications"
    "$PROJECT_ROOT/build"
    "$PROJECT_ROOT/build/macos/Build/Products"
  )
  for path in "${search_paths[@]}"; do
    if [ -d "$path" ]; then
      [ "$VERBOSE" = true ] && echo "   🔎 扫描目录: $path"
      for pat in "${NAME_PATTERNS[@]}"; do
        [ "$VERBOSE" = true ] && echo "     • 使用模式: $pat"
        while IFS= read -r app; do
          [ -n "$app" ] && results+=("$app")
        done < <(find "$path" -maxdepth 7 -type d -name "$pat" 2>/dev/null || true)
      done
    fi
  done
  if [ "${#results[@]}" -gt 0 ]; then
    printf "%s\n" "${results[@]}" | sort -u
  fi
}

# 通过 Spotlight 查找（可能包含残留项）
spotlight_apps() {
  local results=()
  [ "$VERBOSE" = true ] && echo "   🔎 通过 Spotlight 搜索: ${BUNDLE_IDS[*]}"
  for id in "${BUNDLE_IDS[@]}"; do
    while IFS= read -r item; do
      [ -n "$item" ] && results+=("$item")
    done < <(mdfind "kMDItemCFBundleIdentifier == '$id' || kMDItemDisplayName == 'ClipFlow' || kMDItemDisplayName == 'ClipFlow Dev'" 2>/dev/null || true)
  done
  if [ "${#results[@]}" -gt 0 ]; then
    printf "%s\n" "${results[@]}" | sort -u
  fi
}

# 1) 列出发现的应用
echo "🔎 正在扫描文件系统中的应用...（可能需要数秒）"
SYSTEM_APPS=$(find_apps)
SPOTLIGHT_APPS=$(spotlight_apps)

if [ -z "$SYSTEM_APPS" ] && [ -z "$SPOTLIGHT_APPS" ]; then
  echo "✅ 未找到任何 ClipFlow 应用或索引项"
else
  echo "📱 找到以下可能的应用/索引路径："
  if [ -n "$SYSTEM_APPS" ]; then
    echo "— 文件系统实际存在："
    echo "$SYSTEM_APPS" | while read -r app; do
      [ -n "$app" ] && echo "   • $app"
    done
  fi
  if [ -n "$SPOTLIGHT_APPS" ]; then
    echo "— Spotlight 索引项（可能已失效）："
    echo "$SPOTLIGHT_APPS" | while read -r app; do
      [ -n "$app" ] && echo "   • $app"
    done
  fi
fi

# 2) 确认删除
echo ""
read -p "❓ 确定要删除上述文件系统中的应用吗？(y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ 取消删除操作"
  exit 0
fi

# 3) 删除文件系统中的应用
# 删除白名单前缀，防止误删系统外路径
ALLOWED_DELETE_PREFIXES=(
  "/Applications"
  "$HOME/Applications"
  "$PROJECT_ROOT/build"
  "$HOME/Library/Application Support"
  "$HOME/Library/Preferences"
  "$HOME/Library/Caches"
  "$HOME/Library/Logs"
)
# 安全删除函数：仅允许删除位于白名单前缀下的路径
safe_rm() {
  local target="$1"
  for prefix in "${ALLOWED_DELETE_PREFIXES[@]}"; do
    if [[ "$target" == "$prefix"* ]]; then
      rm -rf "$target"
      return 0
    fi
  done
  echo "   ⚠️ 路径不在白名单，已跳过删除: $target"
  return 1
}
if [ -n "$SYSTEM_APPS" ]; then
  echo "🗑️  开始删除实际存在的 .app 包..."
  echo "$SYSTEM_APPS" | while read -r app; do
    if [ -n "$app" ] && [ -e "$app" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo "   预览: 将删除 $app"
      else
        echo "   删除: $app"
        safe_rm "$app"
      fi
    fi
  done
else
  echo "ℹ️ 文件系统中未发现可删除的 .app 包"
fi

# 4) 清理相关缓存/支持/偏好目录（与原脚本一致）
echo "🧽 清理相关缓存/支持/偏好..."
APP_SUPPORT_DIRS=(
  "$HOME/Library/Application Support/$RELEASE_BUNDLE_ID"
  "$HOME/Library/Application Support/$DEV_BUNDLE_ID"
  "$HOME/Library/Application Support/ClipFlow"
  "$HOME/Library/Application Support/clip_flow"
  "$HOME/Library/Application Support/ClipFlow Dev"
  "$HOME/Library/Application Support/clip_flow_dev"
)
for dir in "${APP_SUPPORT_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "   预览: 将删除应用支持目录: $dir"
    else
      echo "   删除应用支持目录: $dir"
      safe_rm "$dir"
    fi
  fi
done

PREF_FILES=(
  "$HOME/Library/Preferences/${RELEASE_BUNDLE_ID}.plist"
  "$HOME/Library/Preferences/${DEV_BUNDLE_ID}.plist"
  "$HOME/Library/Preferences/ClipFlow.plist"
  "$HOME/Library/Preferences/ClipFlow Dev.plist"
)
for pref in "${PREF_FILES[@]}"; do
  if [ -f "$pref" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "   预览: 将删除偏好设置: $pref"
    else
      echo "   删除偏好设置: $pref"
      safe_rm "$pref"
    fi
  fi
done

CACHE_DIRS=(
  "$HOME/Library/Caches/${RELEASE_BUNDLE_ID}"
  "$HOME/Library/Caches/${DEV_BUNDLE_ID}"
  "$HOME/Library/Caches/ClipFlow"
  "$HOME/Library/Caches/ClipFlow Dev"
)
for cache in "${CACHE_DIRS[@]}"; do
  if [ -d "$cache" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "   预览: 将删除缓存目录: $cache"
    else
      echo "   删除缓存目录: $cache"
      safe_rm "$cache"
    fi
  fi
done

# 新增：清理日志目录
LOG_DIRS=(
  "$HOME/Library/Logs/ClipFlow"
  "$HOME/Library/Logs/ClipFlow Dev"
  "$HOME/Library/Logs/${RELEASE_BUNDLE_ID}"
  "$HOME/Library/Logs/${DEV_BUNDLE_ID}"
)
for log in "${LOG_DIRS[@]}"; do
  if [ -d "$log" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "   预览: 将删除日志目录: $log"
    else
      echo "   删除日志目录: $log"
      safe_rm "$log"
    fi
  fi
done

# 5) 重建 LaunchServices 数据库，移除残留的应用索引
echo "🔧 重建 LaunchServices 数据库以移除系统索引..."
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -r -domain local -domain system -domain user || true
  echo "   ✅ LaunchServices 已刷新"
else
  echo "   ⚠️ 未找到 lsregister 工具，跳过"
fi

# 6) 可选：重建 Spotlight 索引（默认跳过，需 --spotlight 才提示）
if [ "${SPOTLIGHT}" = true ]; then
  read -p "❓ 是否重建 Spotlight 索引以彻底移除搜索残留？(y/N): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v mdutil >/dev/null 2>&1; then
      echo "   开始重建 Spotlight 索引（可能需要输入管理员密码）..."
      if sudo -n true 2>/dev/null; then
        sudo mdutil -i on / || true
        sudo mdutil -E / || true
      else
        echo "   ⚠️ 未检测到免密 sudo，将尝试以普通权限重建用户目录索引"
        mdutil -i on "$HOME" || true
        mdutil -E "$HOME" || true
        echo "   ℹ️ 如需彻底重建系统卷索引，请手动执行：sudo mdutil -i on / && sudo mdutil -E /"
      fi
    else
      echo "   ⚠️ 未找到 mdutil 工具，跳过"
    fi
  else
    echo "   ⏭️ 已跳过 Spotlight 索引重建"
  fi
else
  echo "🌓 已跳过 Spotlight 索引处理（默认关闭，可用 --spotlight 启用）"
fi

# 7) 重启 Finder（刷新图标/应用列表）
echo "🔄 重启 Finder 以刷新图标缓存（无需 killall）..."
osascript -e 'tell application "Finder" to quit' >/dev/null 2>&1 || true
sleep 1
osascript -e 'tell application "Finder" to activate' >/dev/null 2>&1 || true

# 8) 验证清理结果
echo ""
echo "🔍 验证清理结果（文件系统与 Spotlight）..."
REMAINING=$(find_apps)
REMAINING_SPOTLIGHT=$(spotlight_apps)
if [ -z "$REMAINING" ]; then
  echo "   ✅ 文件系统中未发现残留 .app 包"
else
  echo "   ⚠️ 文件系统仍存在以下残留："
  echo "$REMAINING" | while read -r app; do
    [ -n "$app" ] && echo "      • $app"
  done
fi

if [ -z "$REMAINING_SPOTLIGHT" ]; then
  echo "   ✅ Spotlight 索引中未发现残留条目"
else
  echo "   ⚠️ Spotlight 仍显示以下条目（可能是陈旧索引）："
  echo "$REMAINING_SPOTLIGHT" | while read -r app; do
    [ -n "$app" ] && echo "      • $app"
  done
  echo "   👉 如需彻底清除，请确认已执行 Spotlight 重建索引，并稍候片刻再试"
fi

echo ""
echo "✅ 清理流程完成"
