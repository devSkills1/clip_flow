import 'dart:async';
import 'dart:io';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:clip_flow_pro/core/services/database_service.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:flutter/services.dart';

/// 剪贴板调试工具
///
/// 用于诊断剪贴板监听失效的问题
class ClipboardDebug {
  static const MethodChannel _platformChannel = MethodChannel(
    'clipboard_service',
  );

  /// 执行完整的剪贴板诊断
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    try {
      // 1. 检查剪贴板服务状态
      results['service_status'] = await _checkServiceStatus();

      // 2. 检查平台通信
      results['platform_communication'] = await _checkPlatformCommunication();

      // 3. 检查剪贴板权限
      results['clipboard_permissions'] = await _checkClipboardPermissions();

      // 4. 检查轮询器状态
      results['poller_status'] = await _checkPollerStatus();

      // 5. 测试基本剪贴板操作
      results['basic_operations'] = await _testBasicOperations();
    } on PlatformException catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  /// 检查剪贴板服务状态
  static Future<Map<String, dynamic>> _checkServiceStatus() async {
    final service = ClipboardService.instance;

    return {
      'is_polling': service.isPolling,
      'current_interval': service.currentPollingInterval.inMilliseconds,
      'stream_available': true,
    };
  }

  /// 检查平台通信
  static Future<Map<String, dynamic>> _checkPlatformCommunication() async {
    try {
      // 测试平台通道是否可用
      final result = await _platformChannel.invokeMethod<String>('test');
      return {
        'channel_available': true,
        'test_result': result,
      };
    } on PlatformException catch (e) {
      return {
        'channel_available': false,
        'error': e.toString(),
      };
    }
  }

  /// 检查剪贴板权限
  static Future<Map<String, dynamic>> _checkClipboardPermissions() async {
    try {
      // 尝试读取剪贴板
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      // 尝试写入剪贴板
      await Clipboard.setData(const ClipboardData(text: 'test'));

      return {
        'read_permission': true,
        'write_permission': true,
        'current_content': clipboardData?.text ?? 'empty',
      };
    } on PlatformException catch (e) {
      return {
        'read_permission': false,
        'write_permission': false,
        'error': e.toString(),
      };
    }
  }

  /// 检查轮询器状态
  static Future<Map<String, dynamic>> _checkPollerStatus() async {
    final service = ClipboardService.instance;

    try {
      // 获取剪贴板序列号（如果支持）
      int? sequence;
      if (Platform.isMacOS) {
        try {
          sequence = await _platformChannel.invokeMethod<int>(
            'getClipboardSequence',
          );
        } on PlatformException catch (_) {
          // 序列号获取失败
        }
      }

      // 获取轮询器的详细统计信息
      var pollingStats = <String, dynamic>{};
      try {
        pollingStats = service.getPollingStats();
        // 添加一些额外的配置信息
        pollingStats['interval_range'] = '100ms - 2000ms';
        pollingStats['adaptive_polling'] = true;
      } on PlatformException catch (e) {
        pollingStats = {'stats_error': e.toString()};
      }

      return {
        'is_polling': service.isPolling,
        'interval_ms': service.currentPollingInterval.inMilliseconds,
        'platform': Platform.operatingSystem,
        'sequence_support': sequence != null,
        'current_sequence': sequence,
        'polling_stats': pollingStats,
        'status': service.isPolling ? '✅ 正在轮询' : '❌ 未轮询',
      };
    } on PlatformException catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// 强制触发一次剪贴板检查
  static Future<String> triggerClipboardCheck() async {
    try {
      final service = ClipboardService.instance;

      // 获取当前剪贴板类型来触发检查
      final clipType = await service.getCurrentClipboardType();
      final hasContent = await service.hasClipboardContent();

      return '''
✅ 剪贴板检查结果:
  - 当前类型: ${clipType?.toString() ?? '无内容'}
  - 有内容: $hasContent
''';
    } on PlatformException catch (e) {
      return '❌ 触发剪贴板检查失败: $e';
    }
  }

  /// 获取剪贴板历史记录数量
  static Future<String> getHistoryCount() async {
    try {
      final items = await DatabaseService.instance.getAllClipItems(limit: 1000);
      return '✅ 剪贴板历史记录: ${items.length} 条';
    } on PlatformException catch (e) {
      return '❌ 获取历史记录失败: $e';
    }
  }

  /// 测试基本剪贴板操作
  static Future<Map<String, dynamic>> _testBasicOperations() async {
    try {
      final testText = 'ClipFlow Test ${DateTime.now().millisecondsSinceEpoch}';

      // 写入测试文本
      await Clipboard.setData(ClipboardData(text: testText));

      // 等待一小段时间
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 读取剪贴板
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final readText = clipboardData?.text;

      return {
        'write_success': true,
        'read_success': readText != null,
        'content_match': readText == testText,
        'written_text': testText,
        'read_text': readText,
      };
    } on PlatformException catch (e) {
      return {
        'write_success': false,
        'read_success': false,
        'error': e.toString(),
      };
    }
  }

  /// 监听剪贴板变化（用于测试）
  static StreamSubscription<ClipItem>? startListening() {
    final service = ClipboardService.instance;

    return service.clipboardStream.listen(
      (clipItem) {
        final content = clipItem.content ?? '';
        final preview = content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
        Log.d(
          'Clipboard change detected: ${clipItem.type} - $preview',
          tag: 'clipboard_debug',
        );
      },
      onError: (Object error) {
        Log.e(
          'Clipboard monitoring error',
          tag: 'clipboard_debug',
          error: error,
        );
      },
    );
  }

  /// 停止监听
  static void stopListening(StreamSubscription<ClipItem>? subscription) {
    subscription?.cancel();
  }

  /// 打印诊断结果
  static void printDiagnostics(Map<String, dynamic> results) {
    Log.d('=== 剪贴板诊断结果 ===', tag: 'clipboard_debug');
    for (final entry in results.entries) {
      Log.d('${entry.key}: ${entry.value}', tag: 'clipboard_debug');
    }
    Log.d('=== 诊断完成 ===', tag: 'clipboard_debug');
  }

  /// 重新初始化剪贴板服务
  static Future<bool> reinitializeService() async {
    try {
      final service = ClipboardService.instance;

      // 停止当前服务
      await service.dispose();

      // 等待一小段时间
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 重新初始化
      await service.initialize();

      return true;
    } on PlatformException catch (e) {
      await Log.e(
        'Re-initialization failed',
        tag: 'clipboard_debug',
        error: e,
      );
      return false;
    }
  }
}
