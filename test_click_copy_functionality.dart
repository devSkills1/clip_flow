#!/usr/bin/env dart

import 'dart:io';

/// 测试点击卡片重新复制到剪贴板功能的脚本
///
/// 使用方法：
/// 1. 确保ClipFlow Pro应用正在运行
/// 2. 运行此脚本：dart test_click_copy_functionality.dart
/// 3. 按照提示操作

void main() async {
  print('🧪 ClipFlow Pro - 点击卡片重新复制功能测试');
  print('=' * 50);

  // 测试步骤1：复制不同类型的内容
  await testStep1();

  // 测试步骤2：验证点击重新复制功能
  await testStep2();

  // 测试步骤3：验证复制结果
  await testStep3();

  print('\n✅ 测试完成！');
}

/// 步骤1：复制不同类型的测试内容
Future<void> testStep1() async {
  print('\n📋 步骤1：复制测试内容到剪贴板');
  print('-' * 30);

  final testContents = [
    {
      'type': '文本',
      'content': '这是一个测试文本内容 - ClipFlow Pro 功能验证',
    },
    {
      'type': 'URL',
      'content': 'https://github.com/flutter/flutter',
    },
    {
      'type': 'JSON',
      'content':
          '{"name": "ClipFlow Pro", "version": "1.0.0", "platform": "macOS"}',
    },
    {
      'type': '代码',
      'content': r'''
function greetUser(name) {
  console.log(`Hello, ${name}!`);
  return `Welcome to ClipFlow Pro, ${name}`;
}''',
    },
    {
      'type': 'HTML',
      'content':
          '<div class="test"><h2>ClipFlow Pro</h2><p>剪贴板历史管理工具</p></div>',
    },
  ];

  for (var i = 0; i < testContents.length; i++) {
    final item = testContents[i];
    print('\n${i + 1}. 复制${item['type']}内容...');

    await copyToClipboard(item['content']!);
    await Future.delayed(const Duration(seconds: 2));

    print('   ✓ 已复制，请检查ClipFlow Pro应用中是否出现新的卡片');
  }

  print('\n📱 请检查ClipFlow Pro应用，确认所有测试内容都已显示为卡片');
  await waitForUser('确认所有卡片都已显示后，按Enter继续...');
}

/// 步骤2：测试点击重新复制功能
Future<void> testStep2() async {
  print('\n🖱️  步骤2：测试点击卡片重新复制功能');
  print('-' * 30);

  // 先复制一个新内容，改变当前剪贴板
  print('\n1. 复制新内容到剪贴板（用于对比）...');
  const newContent = '这是新的剪贴板内容 - 用于验证点击重新复制功能';
  await copyToClipboard(newContent);

  print('   ✓ 当前剪贴板内容：$newContent');

  print('\n2. 现在请在ClipFlow Pro应用中：');
  print('   - 点击任意一个之前的卡片（比如URL卡片或代码卡片）');
  print('   - 观察是否显示"已复制"的提示');
  print('   - 注意应用界面的反馈');

  await waitForUser('完成点击操作后，按Enter继续验证...');
}

/// 步骤3：验证复制结果
Future<void> testStep3() async {
  print('\n🔍 步骤3：验证复制结果');
  print('-' * 30);

  print('\n检查当前剪贴板内容...');
  final currentContent = await getClipboardContent();

  if (currentContent != null) {
    print('✓ 当前剪贴板内容：');
    print(
      '  ${currentContent.length > 100 ? '${currentContent.substring(0, 100)}...' : currentContent}',
    );

    // 检查是否是我们之前复制的测试内容之一
    final testContents = [
      'https://github.com/flutter/flutter',
      'function greetUser(name)',
      '{"name": "ClipFlow Pro"',
      '<div class="test">',
      '这是一个测试文本内容',
    ];

    final isTestContent = testContents.any(
      currentContent.contains,
    );

    if (isTestContent) {
      print('✅ 成功！剪贴板内容已更新为之前的测试内容');
      print('   点击卡片重新复制功能正常工作');
    } else {
      print('⚠️  剪贴板内容似乎不是预期的测试内容');
      print('   请确认是否正确点击了卡片');
    }
  } else {
    print('❌ 无法获取剪贴板内容');
  }

  print('\n🧪 额外测试：请尝试点击不同类型的卡片');
  print('   - 文本卡片');
  print('   - URL卡片（应该可以直接在浏览器中打开）');
  print('   - 代码卡片（应该保持格式）');
  print('   - JSON卡片（应该保持结构）');

  await waitForUser('完成额外测试后，按Enter结束...');
}

/// 复制内容到剪贴板
Future<void> copyToClipboard(String content) async {
  if (Platform.isMacOS) {
    final process = await Process.start('pbcopy', []);
    process.stdin.write(content);
    await process.stdin.close();
    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      final preview = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
      print('   ✓ 已复制: $preview');
    } else {
      print('   ❌ 复制失败');
    }
  } else {
    print('   ❌ 此脚本仅支持macOS');
  }
}

/// 获取剪贴板内容
Future<String?> getClipboardContent() async {
  if (Platform.isMacOS) {
    try {
      final result = await Process.run('pbpaste', []);
      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
    } catch (e) {
      print('   ❌ 获取剪贴板内容失败: $e');
    }
  }
  return null;
}

/// 等待用户输入
Future<void> waitForUser(String message) async {
  print('\n📝 $message');
  stdin.readLineSync();
}
