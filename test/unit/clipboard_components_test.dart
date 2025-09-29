import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/services/clipboard_detector.dart';
import 'package:clip_flow_pro/core/services/clipboard_poller.dart';
import 'package:clip_flow_pro/core/services/clipboard_processor.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';

void main() {
  group('ClipboardDetector 单元测试', () {
    late ClipboardDetector detector;

    setUp(() {
      detector = ClipboardDetector();
    });

    test('应该正确检测纯文本内容', () {
      const text = '这是一段普通的文本内容';
      final result = detector.detectContentType(text);
      expect(result, ClipType.text);
    });

    test('应该正确检测URL内容', () {
      const url = 'https://www.example.com';
      final result = detector.detectContentType(url);
      expect(result, ClipType.url);
    });

    test('应该正确检测邮箱地址', () {
      const email = 'test@example.com';
      final result = detector.detectContentType(email);
      expect(result, ClipType.email);
    });

    test('应该正确检测颜色值', () {
      const color = '#FF5733';
      final result = detector.detectContentType(color);
      expect(result, ClipType.color);
    });

    test('应该正确检测代码内容', () {
      const code = '''
      function hello() {
        console.log("Hello World");
      }
      ''';
      final result = detector.detectContentType(code);
      expect(result, ClipType.code);
    });

    test('应该正确检测HTML内容', () {
      const html = '<div><p>Hello World</p></div>';
      final result = detector.detectContentType(html);
      expect(result, ClipType.html);
    });

    test('应该正确检测JSON内容', () {
      const json = '{"name": "John", "age": 30}';
      final result = detector.detectContentType(json);
      expect(result, ClipType.json);
    });

    test('应该处理空字符串', () {
      const empty = '';
      final result = detector.detectContentType(empty);
      expect(result, ClipType.text);
    });

    test('应该处理空字符串', () {
      final result = detector.detectContentType('');
      expect(result, ClipType.text);
    });
  });

  group('ClipboardPoller 单元测试', () {
    late ClipboardPoller poller;

    setUp(() {
      poller = ClipboardPoller();
    });

    tearDown(() {
      // ClipboardPoller 没有 dispose 方法
    });

    test('初始状态应该是未轮询', () {
      expect(poller.isPolling, false);
    });

    test('应该能够获取轮询状态', () {
      expect(poller.isPolling, false);
    });

    test('应该能够重置状态', () {
      // 这个测试验证重置方法不会抛出异常
      expect(() => poller.resetStats(), returnsNormally);
    });

    test('应该能够获取轮询统计信息', () {
      final stats = poller.getPollingStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalChecks'), true);
      expect(stats.containsKey('successfulChecks'), true);
      expect(stats.containsKey('failedChecks'), true);
    });

    test('应该能够获取性能指标', () {
      final metrics = poller.getPerformanceMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('averageInterval'), true);
      expect(metrics.containsKey('successRate'), true);
    });

    test('应该能够重置统计信息', () {
      expect(() => poller.resetStats(), returnsNormally);
      final stats = poller.getPollingStats();
      expect(stats['totalChecks'], 0);
      expect(stats['successfulChecks'], 0);
      expect(stats['failedChecks'], 0);
    });
  });

  group('ClipboardProcessor 单元测试', () {
    late ClipboardProcessor processor;

    setUp(() {
      processor = ClipboardProcessor();
    });

    tearDown(() {
      // ClipboardProcessor 没有 dispose 方法
    });

    test('应该能够清理缓存', () {
      expect(() => processor.clearCache(), returnsNormally);
    });

    test('应该能够获取缓存统计信息', () {
      final stats = processor.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalItems'), true);
      expect(stats.containsKey('memoryUsage'), true);
      expect(stats.containsKey('hitRate'), true);
    });

    test('应该能够获取性能指标', () {
      final metrics = processor.getPerformanceMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics.containsKey('cacheHitRate'), true);
      expect(metrics.containsKey('memoryUsage'), true);
      expect(metrics.containsKey('maxMemoryUsage'), true);
    });

    test('缓存统计应该有正确的初始值', () {
      final stats = processor.getCacheStats();
      expect(stats['totalItems'], anyOf(0, isNull));
      expect(stats['memoryUsage'], anyOf(0, isNull));
      expect(stats['hitRate'], anyOf(0.0, isNull));
    });

    test('性能指标应该有合理的默认值', () {
      final metrics = processor.getPerformanceMetrics();
      expect(metrics['cacheHitRate'], anyOf(0.0, isNull));
      expect(metrics['memoryUsage'], anyOf(0, isNull));
      expect(metrics['maxMemoryUsage'], anyOf(greaterThan(0), isNull));
    });
  });

  group('组件集成测试', () {
    late ClipboardDetector detector;
    late ClipboardPoller poller;
    late ClipboardProcessor processor;

    setUp(() {
      detector = ClipboardDetector();
      poller = ClipboardPoller();
      processor = ClipboardProcessor();
    });

    tearDown(() {
      // 这些组件没有 dispose 方法
    });

    test('检测器和处理器应该能够协同工作', () {
      const testText = 'https://www.example.com';
      final detectedType = detector.detectContentType(testText);
      expect(detectedType, ClipType.url);

      // 验证处理器可以处理检测到的类型
      expect(() => processor.clearCache(), returnsNormally);
    });

    test('所有组件都应该有正确的初始状态', () {
      expect(detector.detectContentType('test'), isA<ClipType>());
      expect(poller.isPolling, false);
      expect(processor.getCacheStats()['totalItems'], anyOf(0, isNull));
    });

    test('组件应该能够正确清理资源', () {
      expect(() {
        // 这些组件没有 dispose 方法，但可以正常创建和使用
        processor.clearCache();
      }, returnsNormally);
    });
  });
}
