#!/usr/bin/env dart

import 'dart:io';

/// 简单的剪贴板测试脚本
/// 用于验证剪贴板监听功能
void main() async {
  print('=== 剪贴板监听测试 ===');
  print('');

  // 测试 1: 复制文本到剪贴板
  print('测试 1: 复制文本到剪贴板');
  await copyTextToClipboard('Hello, Clipboard Test!');
  await Future.delayed(Duration(seconds: 1));

  // 测试 2: 复制另一个文本
  print('测试 2: 复制另一个文本');
  await copyTextToClipboard('这是中文测试内容');
  await Future.delayed(Duration(seconds: 1));

  // 测试 3: 复制 JSON 内容
  print('测试 3: 复制 JSON 内容');
  await copyTextToClipboard('{"name": "test", "value": 123}');
  await Future.delayed(Duration(seconds: 1));

  // 测试 4: 复制代码内容
  print('测试 4: 复制代码内容');
  await copyTextToClipboard('''
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}
''');

  print('');
  print('测试完成！请在应用中检查剪贴板历史记录。');
  print('如果剪贴板监听正常工作，应该能看到以上 4 个测试内容。');
}

/// 复制文本到剪贴板
Future<void> copyTextToClipboard(String text) async {
  try {
    if (Platform.isMacOS) {
      // 使用 pbcopy 命令复制到剪贴板
      final process = await Process.start('pbcopy', []);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
      print(
        '✓ 已复制: ${text.length > 50 ? text.substring(0, 50) + '...' : text}',
      );
    } else if (Platform.isLinux) {
      // 使用 xclip 命令复制到剪贴板
      final process = await Process.start('xclip', ['-selection', 'clipboard']);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
      print(
        '✓ 已复制: ${text.length > 50 ? text.substring(0, 50) + '...' : text}',
      );
    } else if (Platform.isWindows) {
      // 使用 clip 命令复制到剪贴板
      final process = await Process.start('clip', []);
      process.stdin.write(text);
      await process.stdin.close();
      await process.exitCode;
      print(
        '✓ 已复制: ${text.length > 50 ? text.substring(0, 50) + '...' : text}',
      );
    } else {
      print('✗ 不支持的平台');
    }
  } catch (e) {
    print('✗ 复制失败: $e');
  }
}
