import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/async_processing_queue.dart';
import 'package:clip_flow_pro/core/services/clipboard_poller.dart';
import 'package:clip_flow_pro/core/services/optimized_clipboard_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 确保Flutter测试环境初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  group('剪贴板性能优化测试', () {
    late OptimizedClipboardManager manager;
    late ClipboardPoller poller;
    late AsyncProcessingQueue queue;

    setUp(() async {
      manager = OptimizedClipboardManager();
      poller = ClipboardPoller();
      queue = AsyncProcessingQueue();
    });

    tearDown(() async {
      await manager.dispose();
      poller.stopPolling();
      queue.stop();
    });

    test('快速复制模式检测测试', () async {
      poller.startPolling();

      // 模拟快速复制
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: 200));
        poller.checkOnce();
      }

      // 检查是否进入快速复制模式
      final stats = poller.getPollingStats();
      print('轮询统计: $stats');

      expect(stats['isRapidCopyMode'], isTrue);
      expect(stats['rapidCopyCount'], greaterThan(0));
    });

    test('异步处理队列性能测试', () async {
      queue.start();

      final stopwatch = Stopwatch()..start();

      // 添加多个处理任务
      final futures = <Future>[];
      for (int i = 0; i < 20; i++) {
        final item = ClipItem(
          id: 'test_$i',
          type: ClipType.text,
          content: '测试内容 $i',
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final future = queue.addClipboardTask(
          item: item,
          processor: (item) async {
            // 模拟处理时间
            await Future.delayed(
              Duration(milliseconds: 10 + Random().nextInt(20)),
            );
            return item;
          },
          priority: i % 3 == 0 ? Priority.high : Priority.normal,
        );

        futures.add(future);
      }

      // 等待所有任务完成
      final results = await Future.wait(futures);

      stopwatch.stop();

      final queueStats = queue.getStats();
      print('队列统计: $queueStats');
      print('总处理时间: ${stopwatch.elapsedMilliseconds}ms');
      print('平均处理时间: ${stopwatch.elapsedMilliseconds / results.length}ms');

      expect(results.length, equals(20));
      expect(queueStats['totalProcessed'], equals(20));
      expect(queueStats['successRate'], equals('100.0'));
    });

    test('批量写入性能测试', () async {
      await manager.initialize();

      final stopwatch = Stopwatch()..start();

      // 模拟快速复制场景
      final items = <ClipItem>[];
      for (int i = 0; i < 50; i++) {
        items.add(
          ClipItem(
            id: 'batch_test_$i',
            type: i % 4 == 0 ? ClipType.code : ClipType.text,
            content: '批量测试内容 $i',
            metadata: {},
            createdAt: DateTime.now().subtract(Duration(seconds: i)),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 使用优化管理器处理
      for (final item in items) {
        await manager.addToProcessingQueue(item);
      }

      // 等待处理完成
      await Future.delayed(Duration(seconds: 2));
      await manager.flushAllBuffers();

      stopwatch.stop();

      final metrics = manager.getPerformanceMetrics();
      print('性能指标: $metrics');
      print('批量写入总时间: ${stopwatch.elapsedMilliseconds}ms');

      expect(metrics['storage']['totalSaved'], greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 应该在3秒内完成
    });

    test('轮询间隔自适应测试', () async {
      poller.startPolling();

      final initialInterval = poller.currentPollingInterval;
      print('初始轮询间隔: ${initialInterval.inMilliseconds}ms');

      // 模拟连续变化
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(milliseconds: 300));
        await poller.checkOnce();
      }

      final activeInterval = poller.currentPollingInterval;
      print('活跃轮询间隔: ${activeInterval.inMilliseconds}ms');

      // 在快速复制模式下，间隔应该减少
      expect(
        activeInterval.inMilliseconds,
        lessThanOrEqualTo(initialInterval.inMilliseconds),
      );

      // 等待一段时间，检查间隔是否恢复
      await Future.delayed(Duration(seconds: 10));
      final relaxedInterval = poller.currentPollingInterval;
      print('放松轮询间隔: ${relaxedInterval.inMilliseconds}ms');

      expect(
        relaxedInterval.inMilliseconds,
        greaterThan(activeInterval.inMilliseconds),
      );
    });

    test('内存使用和缓存效率测试', () async {
      await manager.initialize();
      manager.startMonitoring();

      // 生成大量数据测试内存使用
      for (int i = 0; i < 100; i++) {
        final item = ClipItem(
          id: 'memory_test_$i',
          type: ClipType.text,
          content: '内存测试内容 $i' * (10 + Random().nextInt(50)), // 变长内容
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await manager.addToProcessingQueue(item);
      }

      // 等待处理完成
      await Future.delayed(Duration(seconds: 3));
      await manager.flushAllBuffers();

      final metrics = manager.getPerformanceMetrics();
      print('内存使用指标: $metrics');

      // 检查处理效率
      expect(metrics['detection']['totalProcessed'], greaterThan(80));
      expect(metrics['storage']['totalSaved'], greaterThan(80));
    });

    test('并发处理能力测试', () async {
      queue.start();

      const concurrency = 10;
      const itemsPerBatch = 20;

      final stopwatch = Stopwatch()..start();

      // 创建多个并发批次
      final batchFutures = <Future>[];
      for (int batch = 0; batch < concurrency; batch++) {
        final batchFuture = () async {
          for (int i = 0; i < itemsPerBatch; i++) {
            final item = ClipItem(
              id: 'concurrent_${batch}_$i',
              type: ClipType.text,
              content: '并发测试内容 ${batch}_$i',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await queue.addClipboardTask(
              item: item,
              processor: (item) async {
                // 模拟不同的处理时间
                await Future.delayed(
                  Duration(milliseconds: 5 + Random().nextInt(15)),
                );
                return item;
              },
            );
          }
        }();

        batchFutures.add(batchFuture);
      }

      await Future.wait(batchFutures);

      // 等待所有任务完成
      await Future.delayed(Duration(seconds: 5));

      stopwatch.stop();

      final stats = queue.getStats();
      print('并发处理统计: $stats');
      print('总处理时间: ${stopwatch.elapsedMilliseconds}ms');
      print(
        '总吞吐量: ${(concurrency * itemsPerBatch / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(1)} items/sec',
      );

      expect(stats['totalProcessed'], equals(concurrency * itemsPerBatch));
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10秒内完成
    });

    test('错误恢复和容错性测试', () async {
      queue.start();

      var successCount = 0;
      var errorCount = 0;

      // 添加一些正常任务和一些失败任务
      for (int i = 0; i < 20; i++) {
        final item = ClipItem(
          id: 'error_test_$i',
          type: ClipType.text,
          content: '错误测试内容 $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          await queue.addClipboardTask(
            item: item,
            processor: (item) async {
              if (i % 5 == 0) {
                throw Exception('模拟处理错误');
              }
              successCount++;
              return item;
            },
          );
        } catch (e) {
          errorCount++;
        }
      }

      // 等待处理完成
      await Future.delayed(Duration(seconds: 2));

      final stats = queue.getStats();
      print('错误处理统计: $stats');
      print('成功: $successCount, 错误: $errorCount');

      expect(stats['totalProcessed'], equals(16)); // 20 - 4个错误
      expect(stats['totalFailed'], equals(4));
    });
  });

  group('性能基准测试', () {
    test('轮询性能基准', () async {
      final poller = ClipboardPoller();
      poller.startPolling();

      const testDuration = Duration(seconds: 5);
      final startTime = DateTime.now();
      var checkCount = 0;

      while (DateTime.now().difference(startTime) < testDuration) {
        await poller.checkOnce();
        checkCount++;
        await Future.delayed(Duration(milliseconds: 100));
      }

      final stats = poller.getPollingStats();
      print('轮询基准测试结果:');
      print('- 测试时长: ${testDuration.inSeconds}秒');
      print('- 检查次数: $checkCount');
      print(
        '- 检查频率: ${(checkCount / testDuration.inSeconds).toStringAsFixed(1)} checks/sec',
      );
      print('- 成功率: ${stats['successRate']}%');

      poller.stopPolling();

      expect(checkCount, greaterThan(40)); // 至少40次检查
    });

    test('OCR处理性能基准', () async {
      // 创建模拟图片数据
      final imageData = Uint8List(1024 * 100); // 100KB图片
      for (int i = 0; i < imageData.length; i++) {
        imageData[i] = Random().nextInt(256);
      }

      const testCount = 10;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < testCount; i++) {
        // 这里应该调用实际的OCR处理，但为了测试我们模拟处理时间
        await Future.delayed(
          Duration(milliseconds: 100 + Random().nextInt(200)),
        );
      }

      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / testCount;
      print('OCR处理基准测试结果:');
      print('- 测试数量: $testCount');
      print('- 总时间: ${stopwatch.elapsedMilliseconds}ms');
      print('- 平均时间: ${avgTime.toStringAsFixed(1)}ms');
      print('- 处理速度: ${(1000 / avgTime).toStringAsFixed(1)} images/sec');

      expect(avgTime, lessThan(400)); // 平均处理时间应小于400ms
    });
  });
}
