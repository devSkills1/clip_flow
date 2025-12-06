import 'dart:io';
import 'package:clip_flow/core/services/clipboard_service.dart';
import 'package:flutter/services.dart';

/// 剪贴板诊断工具
///
/// 用于诊断剪贴板监听功能的问题
void main() async {
  print('=== 剪贴板诊断工具 ===\n');

  // 1. 测试平台通道连接
  print('1. 测试平台通道连接...');
  await testPlatformChannel();

  // 2. 测试剪贴板服务初始化
  print('\n2. 测试剪贴板服务初始化...');
  await testClipboardService();

  // 3. 测试手动剪贴板检查
  print('\n3. 测试手动剪贴板检查...');
  await testManualClipboardCheck();

  print('\n=== 诊断完成 ===');
}

/// 测试平台通道连接
Future<void> testPlatformChannel() async {
  const channel = MethodChannel('clipboard_service');

  try {
    // 测试获取剪贴板序列号
    final sequence = await channel.invokeMethod<int>('getClipboardSequence');
    print('✓ 平台通道连接正常');
    print('  当前剪贴板序列号: $sequence');

    // 测试获取剪贴板类型
    final type = await channel.invokeMethod<String>('getClipboardType');
    print('  当前剪贴板类型: $type');

    // 测试是否有剪贴板内容
    final hasContent = await channel.invokeMethod<bool>('hasClipboardContent');
    print('  是否有剪贴板内容: $hasContent');
  } catch (e) {
    print('✗ 平台通道连接失败: $e');
    print('  这可能是问题的根源！');
  }
}

/// 测试剪贴板服务初始化
Future<void> testClipboardService() async {
  try {
    final service = ClipboardService.instance;
    await service.initialize();
    print('✓ 剪贴板服务初始化成功');

    // 检查轮询状态
    final isPolling = service.isPolling;
    print('  轮询状态: ${isPolling ? "正在轮询" : "未轮询"}');

    final interval = service.currentPollingInterval;
    print('  当前轮询间隔: ${interval.inMilliseconds}ms');
  } catch (e) {
    print('✗ 剪贴板服务初始化失败: $e');
  }
}

/// 测试手动剪贴板检查
Future<void> testManualClipboardCheck() async {
  print('请复制一些文本到剪贴板，然后按 Enter 键...');
  stdin.readLineSync();

  try {
    final service = ClipboardService.instance;

    // 获取当前剪贴板类型
    final type = await service.getCurrentClipboardType();
    print('✓ 检测到剪贴板类型: $type');

    // 检查是否有内容
    final hasContent = await service.hasClipboardContent();
    print('  是否有内容: $hasContent');

    // 尝试获取文本内容
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    if (text != null) {
      print(
        '  文本内容: "${text.length > 50 ? text.substring(0, 50) + "..." : text}"',
      );
    } else {
      print('  无法获取文本内容');
    }
  } catch (e) {
    print('✗ 手动剪贴板检查失败: $e');
  }
}
