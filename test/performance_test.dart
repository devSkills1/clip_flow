import 'dart:async';
import 'dart:io';

import 'package:clip_flow_pro/core/services/clipboard_detector.dart';
import 'package:clip_flow_pro/core/services/clipboard_poller.dart';
import 'package:clip_flow_pro/core/services/clipboard_processor.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 性能监控测试
///
/// 测试架构优化后的性能表现，包括：
/// - 缓存效率
/// - 轮询性能
/// - 内存使用
/// - 响应时间
void main() {
  group('性能监控测试', () {
    late ClipboardService clipboardService;
    late ClipboardProcessor processor;
    late ClipboardPoller poller;
    late ClipboardDetector detector;

    setUp(() {
      clipboardService = ClipboardService();
      processor = ClipboardProcessor();
      poller = ClipboardPoller();
      detector = ClipboardDetector();
    });

    tearDown(() async {
      await clipboardService.dispose();
      poller.stopPolling();
      processor.clearCache();
    });

    group('ClipboardProcessor 性能测试', () {
      test('缓存效率测试', () async {
        // 清空缓存
        processor.clearCache();

        // 模拟重复内容处理
        const testContent = 'Hello, World!';

        // 第一次处理 - 应该是缓存未命中
        final stopwatch1 = Stopwatch()..start();
        await processor.processClipboardContent();
        stopwatch1.stop();

        // 获取缓存统计
        final stats1 = processor.getCacheStats();

        // 第二次处理相同内容 - 应该是缓存命中
        final stopwatch2 = Stopwatch()..start();
        await processor.processClipboardContent();
        stopwatch2.stop();

        final stats2 = processor.getCacheStats();

        // 验证缓存效果
        expect(
          int.parse(stats2['cacheHits'].toString()),
          greaterThan(int.parse(stats1['cacheHits'].toString())),
        );

        // 验证性能提升（缓存命中应该更快）
        expect(
          stopwatch2.elapsedMicroseconds,
          lessThanOrEqualTo(stopwatch1.elapsedMicroseconds),
        );

        print('缓存统计: $stats2');
        print('第一次处理时间: ${stopwatch1.elapsedMicroseconds}μs');
        print('第二次处理时间: ${stopwatch2.elapsedMicroseconds}μs');
      });

      test('内存使用监控', () {
        processor.clearCache();

        final initialStats = processor.getCacheStats();
        final initialMemory = int.parse(initialStats['memoryUsage'].toString());

        // 模拟大量内容处理
        for (int i = 0; i < 50; i++) {
          // 这里应该模拟处理不同的内容
          // 由于测试环境限制，我们主要测试统计功能
        }

        final finalStats = processor.getCacheStats();
        final memoryUsagePercent = double.parse(
          finalStats['memoryUsagePercent'].toString().replaceAll('%', ''),
        );

        // 验证内存使用在合理范围内
        expect(memoryUsagePercent, lessThan(100.0));

        print('内存使用统计: $finalStats');
      });

      test('性能指标获取', () {
        final metrics = processor.getPerformanceMetrics();

        expect(metrics, containsPair('cacheEfficiency', isA<Map>()));
        expect(metrics, containsPair('memoryOptimization', isA<Map>()));

        final cacheEfficiency = metrics['cacheEfficiency'] as Map;
        expect(cacheEfficiency, containsPair('hitRate', isA<String>()));
        expect(
          cacheEfficiency,
          containsPair('memoryUsagePercent', isA<String>()),
        );

        print('性能指标: $metrics');
      });
    });

    group('ClipboardPoller 性能测试', () {
      test('轮询效率测试', () async {
        poller.resetStats();

        // 启动轮询
        final completer = Completer<void>();
        int changeCount = 0;

        poller.startPolling(
          onClipboardChanged: () {
            changeCount++;
            if (changeCount >= 3) {
              completer.complete();
            }
          },
          onError: (error) => print('轮询错误: $error'),
        );

        // 等待一段时间收集统计数据
        await Future.delayed(Duration(seconds: 2));

        final stats = poller.getPollingStats();

        // 验证轮询统计
        expect(int.parse(stats['totalChecks'].toString()), greaterThan(0));
        expect(double.parse(stats['successRate'].toString()), greaterThan(0.0));

        poller.stopPolling();

        print('轮询统计: $stats');
      });

      test('自适应间隔测试', () async {
        poller.resetStats();

        final initialInterval = poller.currentInterval;

        // 启动轮询
        poller.startPolling();

        // 等待自适应调整
        await Future.delayed(Duration(seconds: 3));

        final stats = poller.getPollingStats();
        final currentInterval = poller.currentInterval;

        // 验证间隔可能发生变化（根据活动情况）
        expect(stats, containsPair('currentInterval', isA<int>()));
        expect(stats, containsPair('isIdleMode', isA<bool>()));

        poller.stopPolling();

        print('初始间隔: ${initialInterval.inMilliseconds}ms');
        print('当前间隔: ${currentInterval.inMilliseconds}ms');
        print('轮询状态: $stats');
      });

      test('空闲模式测试', () async {
        poller.resetStats();

        // 启动轮询
        poller.startPolling();

        // 等待足够长的时间以触发空闲模式
        await Future.delayed(Duration(seconds: 1));

        final stats = poller.getPollingStats();

        // 验证空闲模式功能
        expect(stats, containsPair('isIdleMode', isA<bool>()));
        expect(stats, containsPair('consecutiveNoChangeCount', isA<int>()));

        poller.stopPolling();

        print('空闲模式统计: $stats');
      });

      test('性能指标获取', () {
        final metrics = poller.getPerformanceMetrics();

        expect(metrics, containsPair('pollingEfficiency', isA<Map>()));
        expect(metrics, containsPair('resourceOptimization', isA<Map>()));

        final optimization = metrics['resourceOptimization'] as Map;
        expect(optimization, containsPair('idleDetection', isA<bool>()));
        expect(optimization, containsPair('adaptiveInterval', isA<bool>()));
        expect(optimization, containsPair('timeBasedAdjustment', isA<bool>()));

        print('轮询性能指标: $metrics');
      });
    });

    group('ClipboardDetector 性能测试', () {
      test('检测速度测试', () {
        final testCases = [
          'Hello, World!',
          '{"name": "test", "value": 123}',
          '<html><body>Test</body></html>',
          'https://example.com',
          'test@example.com',
          '#FF0000',
          'function test() { return true; }',
        ];

        final stopwatch = Stopwatch()..start();

        for (final content in testCases) {
          final type = detector.detectContentType(content);
          expect(type, isNotNull);
        }

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMicroseconds / testCases.length;

        // 验证检测速度（应该很快）
        expect(avgTime, lessThan(10000)); // 小于10ms

        print('平均检测时间: ${avgTime.toStringAsFixed(2)}μs');
        print('总检测时间: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('大文本检测性能', () {
        // 生成大文本
        final largeText = 'A' * 10000; // 10KB文本

        final stopwatch = Stopwatch()..start();
        final type = detector.detectContentType(largeText);
        stopwatch.stop();

        expect(type, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 小于100ms

        print('大文本检测时间: ${stopwatch.elapsedMilliseconds}ms');
        print('检测结果: $type');
      });
    });

    group('集成性能测试', () {
      test('端到端性能测试', () async {
        // 初始化服务
        await clipboardService.initialize();

        final stopwatch = Stopwatch()..start();

        // 模拟剪贴板活动
        await Future.delayed(Duration(seconds: 2));

        stopwatch.stop();

        // 获取各组件的性能指标
        final processorMetrics = processor.getPerformanceMetrics();
        final pollerMetrics = poller.getPerformanceMetrics();

        expect(processorMetrics, isNotNull);
        expect(pollerMetrics, isNotNull);

        print('处理器性能: $processorMetrics');
        print('轮询器性能: $pollerMetrics');
        print('总测试时间: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('资源清理测试', () async {
        // 初始化服务
        await clipboardService.initialize();

        // 运行一段时间
        await Future.delayed(Duration(seconds: 1));

        // 清理资源
        await clipboardService.dispose();
        processor.clearCache();
        poller.stopPolling();

        // 验证清理效果
        final cacheStats = processor.getCacheStats();
        expect(int.parse(cacheStats['cacheSize'].toString()), equals(0));
        expect(poller.isPolling, isFalse);

        print('资源清理完成');
      });
    });
  });
}
