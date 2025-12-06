#!/usr/bin/env dart

import 'dart:io';

/// 测试剪贴板权限和序列号获取功能的脚本
///
/// 这个脚本会测试：
/// 1. 剪贴板权限是否正常
/// 2. 序列号获取是否工作
/// 3. 不同类型内容的检测

void main() async {
  print('=== 剪贴板权限和序列号测试 ===\n');

  print('这个测试将验证剪贴板权限和平台特定功能。');
  print('请确保 ClipFlow 应用正在运行。\n');

  // 测试 1: 基本文本权限测试
  print('测试 1: 基本剪贴板权限');
  await copyToClipboard('权限测试文本');
  await waitAndPrompt('检查应用是否能检测到这个文本内容');

  // 测试 2: 序列号变化测试
  print('\n测试 2: 序列号变化检测');
  print('将复制 3 个不同的内容，每次都应该看到序列号增加...');

  for (int i = 1; i <= 3; i++) {
    await copyToClipboard(
      '序列号测试 $i - ${DateTime.now().millisecondsSinceEpoch}',
    );
    await Future.delayed(Duration(milliseconds: 500));
    print('已复制第 $i 个内容，请在调试工具中检查序列号是否增加');
    if (i < 3) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  await waitAndPrompt('确认序列号从初始值增加了 3');

  // 测试 3: 不同类型内容测试
  print('\n测试 3: 不同类型内容检测');

  // JSON 内容
  print('复制 JSON 内容...');
  await copyToClipboard(
    '{"test": "permissions", "timestamp": ${DateTime.now().millisecondsSinceEpoch}}',
  );
  await waitAndPrompt('检查是否正确识别为 JSON 类型');

  // URL 内容
  print('复制 URL 内容...');
  await copyToClipboard('https://github.com/flutter/flutter');
  await waitAndPrompt('检查是否正确识别为 URL 类型');

  // 邮箱内容
  print('复制邮箱内容...');
  await copyToClipboard('test@example.com');
  await waitAndPrompt('检查是否正确识别为邮箱类型');

  // 颜色值内容
  print('复制颜色值内容...');
  await copyToClipboard('#FF5722');
  await waitAndPrompt('检查是否正确识别为颜色类型');

  // 代码内容
  print('复制代码内容...');
  await copyToClipboard('''
void main() {
  print("Hello, Clipboard!");
}
''');
  await waitAndPrompt('检查是否正确识别为代码类型');

  // 测试 4: 权限错误处理
  print('\n测试 4: 权限错误处理');
  print('现在将测试应用在没有剪贴板权限时的行为...');
  print('注意：在 macOS 上，剪贴板访问通常不需要特殊权限，');
  print('但应用应该能够优雅地处理任何访问错误。');

  await waitAndPrompt('检查调试工具中是否显示任何权限相关的错误信息');

  print('\n=== 测试完成 ===');
  print('请在应用的调试页面中验证以下功能：');
  print('✓ 剪贴板权限状态');
  print('✓ 序列号获取和变化检测');
  print('✓ 不同内容类型的正确识别');
  print('✓ 错误处理机制');
  print('\n如果所有功能都正常，说明剪贴板权限和检测功能工作正常！');
}

/// 复制内容到剪贴板
Future<void> copyToClipboard(String content) async {
  if (Platform.isMacOS) {
    final process = await Process.start('pbcopy', []);
    process.stdin.write(content);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      print(
        '✓ 已复制: ${content.length > 50 ? content.substring(0, 50) + '...' : content}',
      );
    } else {
      print('❌ 复制失败');
    }
  } else if (Platform.isLinux) {
    final process = await Process.start('xclip', ['-selection', 'clipboard']);
    process.stdin.write(content);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      print(
        '✓ 已复制: ${content.length > 50 ? content.substring(0, 50) + '...' : content}',
      );
    } else {
      print('❌ 复制失败');
    }
  } else if (Platform.isWindows) {
    final result = await Process.run('powershell', [
      '-command',
      'Set-Clipboard',
      '-Value',
      content,
    ]);
    if (result.exitCode == 0) {
      print(
        '✓ 已复制: ${content.length > 50 ? content.substring(0, 50) + '...' : content}',
      );
    } else {
      print('❌ 复制失败');
    }
  } else {
    print('❌ 不支持的平台');
  }
}

/// 等待并提示用户检查
Future<void> waitAndPrompt(String message) async {
  print('📋 $message');
  print('按 Enter 键继续...');
  stdin.readLineSync();
}
