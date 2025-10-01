#!/bin/bash

# ClipFlow Pro 应用清理脚本
# 用于删除系统中所有的 ClipFlow Pro 应用包

set -e

echo "🧹 ClipFlow Pro 应用清理脚本"
echo "=============================="

# 查找所有相关的应用
echo "🔍 搜索系统中的 ClipFlow Pro 应用..."
APPS=$(find /Applications -name "*ClipFlow*" -o -name "*clip_flow*" 2>/dev/null || true)

if [ -z "$APPS" ]; then
    echo "✅ 未找到任何 ClipFlow Pro 应用"
    exit 0
fi

echo "📱 找到以下应用:"
echo "$APPS" | while read -r app; do
    if [ -n "$app" ]; then
        echo "   - $app"
    fi
done

echo ""
read -p "❓ 确定要删除这些应用吗？(y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消删除操作"
    exit 0
fi

echo "🗑️  开始删除应用..."

# 删除应用
echo "$APPS" | while read -r app; do
    if [ -n "$app" ] && [ -e "$app" ]; then
        echo "   删除: $app"
        rm -rf "$app"
    fi
done

# 清理可能的缓存
echo "🧽 清理相关缓存..."

# 清理应用支持文件
APP_SUPPORT_DIRS=(
    "$HOME/Library/Application Support/com.clipflow.pro"
    "$HOME/Library/Application Support/ClipFlow Pro"
    "$HOME/Library/Application Support/clip_flow_pro"
)

for dir in "${APP_SUPPORT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   删除应用支持目录: $dir"
        rm -rf "$dir"
    fi
done

# 清理偏好设置
PREF_FILES=(
    "$HOME/Library/Preferences/com.clipflow.pro.plist"
    "$HOME/Library/Preferences/ClipFlow Pro.plist"
)

for pref in "${PREF_FILES[@]}"; do
    if [ -f "$pref" ]; then
        echo "   删除偏好设置: $pref"
        rm -f "$pref"
    fi
done

# 清理缓存目录
CACHE_DIRS=(
    "$HOME/Library/Caches/com.clipflow.pro"
    "$HOME/Library/Caches/ClipFlow Pro"
)

for cache in "${CACHE_DIRS[@]}"; do
    if [ -d "$cache" ]; then
        echo "   删除缓存目录: $cache"
        rm -rf "$cache"
    fi
done

echo ""
echo "✅ 清理完成！"
echo "📝 建议重启 Dock 以刷新图标缓存:"
echo "   killall Dock"
echo ""
echo "🔍 验证清理结果:"
find /Applications -name "*ClipFlow*" -o -name "*clip_flow*" 2>/dev/null || echo "   未找到任何残留的应用"