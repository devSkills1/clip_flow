#!/bin/bash

echo "🧪 测试剪贴板权限修复效果"
echo "================================"
echo ""

echo "📋 开始测试剪贴板权限行为..."
echo "请按照以下步骤进行测试："
echo ""

echo "1. 确保 ClipFlow Pro 应用已经启动"
echo "2. 复制一些文本内容（例如：Hello World）"
echo "3. 观察是否还会频繁弹出权限请求对话框"
echo "4. 等待 10-15 秒，再复制其他内容"
echo "5. 检查权限请求的频率是否有所改善"
echo ""

echo "🔧 已应用的修复（第二轮优化）："
echo "- ✅ 添加了剪贴板权限到 entitlements 文件"
echo "- ✅ 添加了权限使用说明到 Info.plist"
echo "- ✅ 优化了轮询间隔（从 500ms 增加到 1000ms）"
echo "- ✅ 更快进入空闲模式（20次无变化后进入长间隔模式）"
echo "- ✅ 增加了空闲间隔（从 5秒 增加到 10秒）"
echo "- ✅ 添加了更多 macOS 权限（网络、JIT、内存等）"
echo "- ✅ 在 Swift 插件中添加了缓存机制（500ms 缓存间隔）"
echo "- ✅ 优化了 getClipboardSequence 和 getClipboardType 方法"
echo "- ✅ 减少了对 NSPasteboard.general 的直接访问频率"
echo ""

echo "📊 预期改善："
echo "- 权限请求频率应该显著降低"
echo "- 应用在无剪贴板活动时会自动进入低频监听模式"
echo "- 首次权限授权后应该不再频繁弹出权限对话框"
echo ""

echo "如果问题仍然存在，请检查："
echo "- macOS 系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能"
echo "- 确保 ClipFlow Pro 已被授权"
echo ""

# 模拟一些剪贴板操作来测试
echo "🎯 自动测试剪贴板操作..."
for i in {1..5}; do
    echo "测试文本 $i - $(date)" | pbcopy
    echo "已复制测试文本 $i"
    sleep 3
done

echo ""
echo "✅ 测试完成！请观察应用的权限请求行为。"