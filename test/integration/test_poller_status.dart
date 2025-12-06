#!/usr/bin/env dart

import 'dart:io';

/// 测试剪贴板轮询器状态的脚本
///
/// 这个脚本会复制不同类型的内容到剪贴板，
/// 然后提示用户检查应用中的调试工具来验证轮询器状态。

void main() async {
  print('=== 剪贴板轮询器状态测试 ===\n');

  print('这个测试将帮助验证剪贴板轮询器的状态和功能。');
  print('请确保 ClipFlow 应用正在运行，并打开调试页面。\n');

  // 测试 1: 复制简单文本
  print('测试 1: 复制简单文本');
  await copyToClipboard('Hello, Poller Test!');
  await waitAndPrompt('检查应用中的轮询器状态是否显示为"正在轮询"');

  // 测试 2: 复制 JSON 数据
  print('\n测试 2: 复制 JSON 数据');
  await copyToClipboard(
    '{"test": "poller", "timestamp": "${DateTime.now().millisecondsSinceEpoch}"}',
  );
  await waitAndPrompt('检查轮询间隔是否有变化（应该会加快）');

  // 测试 3: 复制代码片段
  print('\n测试 3: 复制代码片段');
  await copyToClipboard('''
class PollerTest {
  void testClipboard() {
    print("Testing clipboard poller");
  }
}
''');
  await waitAndPrompt('检查连续变化计数是否重置为 0');

  // 测试 4: 等待一段时间不复制任何内容
  print('\n测试 4: 等待轮询器自适应调整');
  print('现在等待 10 秒，不要复制任何内容...');
  for (int i = 10; i > 0; i--) {
    stdout.write('\r等待 $i 秒... ');
    await Future.delayed(Duration(seconds: 1));
  }
  print('\n');
  await waitAndPrompt('检查连续无变化计数是否增加，轮询间隔是否变长');

  // 测试 5: 再次快速复制内容
  print('\n测试 5: 快速连续复制');
  for (int i = 1; i <= 3; i++) {
    await copyToClipboard('快速测试 $i - ${DateTime.now().millisecondsSinceEpoch}');
    await Future.delayed(Duration(milliseconds: 200));
  }
  await waitAndPrompt('检查轮询间隔是否再次加快');

  print('\n=== 测试完成 ===');
  print('请在应用的调试页面中查看完整的轮询器状态信息：');
  print('- 当前轮询状态');
  print('- 轮询间隔');
  print('- 连续无变化计数');
  print('- 最近变化计数');
  print('- 剪贴板序列号（macOS）');
  print('\n如果所有状态都正常显示，说明轮询器工作正常！');
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
