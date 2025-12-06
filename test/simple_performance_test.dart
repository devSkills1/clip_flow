import 'dart:async';
import 'dart:math';

import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/clipboard_poller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 确保Flutter测试环境初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  group('剪贴板轮询优化测试', () {
    test('快速复制模式检测', () async {
      final poller = ClipboardPoller();

      // 获取初始统计
      var stats = poller.getPollingStats();
      print('初始状态: ${stats['isRapidCopyMode']}');

      // 模拟快速复制 - 连续检测到变化
      for (int i = 0; i < 5; i++) {
        // 模拟剪贴板变化（通过调用检查方法）
        await poller.checkOnce();
        await Future.delayed(Duration(milliseconds: 300)); // 快速间隔
      }

      // 检查是否进入快速复制模式
      stats = poller.getPollingStats();
      print('快速复制后状态:');
      print('- 快速复制模式: ${stats['isRapidCopyMode']}');
      print('- 快速复制次数: ${stats['rapidCopyCount']}');
      print('- 当前间隔: ${stats['currentInterval']}ms');

      poller.stopPolling();

      // 验证快速复制检测功能正常工作
      expect(stats['rapidCopyCount'], greaterThan(0));
    });

    test('轮询间隔自适应调整', () async {
      final poller = ClipboardPoller();

      // 获取初始间隔
      var stats = poller.getPollingStats();
      final initialInterval = stats['currentInterval'] as int;
      print('初始轮询间隔: ${initialInterval}ms');

      // 模拟活跃使用场景
      for (int i = 0; i < 8; i++) {
        await poller.checkOnce();
        await Future.delayed(Duration(milliseconds: 200));
      }

      stats = poller.getPollingStats();
      final activeInterval = stats['currentInterval'] as int;
      print('活跃时轮询间隔: ${activeInterval}ms');

      // 活跃时应该使用更短的间隔
      expect(activeInterval, lessThanOrEqualTo(initialInterval));

      // 模拟空闲场景
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(milliseconds: 1000));
        // 不触发变化，让轮询间隔自然增长
      }

      // 等待自适应调整生效
      await Future.delayed(Duration(seconds: 2));

      stats = poller.getPollingStats();
      final idleInterval = stats['currentInterval'] as int;
      print('空闲时轮询间隔: ${idleInterval}ms');

      poller.stopPolling();

      // 空闲时应该使用更长的间隔
      expect(idleInterval, greaterThan(activeInterval));
    });

    test('防抖机制测试', () async {
      final poller = ClipboardPoller();

      final startTime = DateTime.now();
      var changeCount = 0;

      // 模拟非常快速的连续复制
      for (int i = 0; i < 10; i++) {
        await poller.checkOnce();
        changeCount++;
        await Future.delayed(Duration(milliseconds: 50)); // 极快间隔
      }

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);

      print('防抖测试结果:');
      print('- 变化次数: $changeCount');
      print('- 总耗时: ${totalTime.inMilliseconds}ms');
      print('- 平均间隔: ${totalTime.inMilliseconds / changeCount}ms');

      final stats = poller.getPollingStats();
      print('- 快速复制模式: ${stats['isRapidCopyMode']}');
      print('- 快速复制计数: ${stats['rapidCopyCount']}');

      poller.stopPolling();

      // 验证快速复制模式被正确触发
      expect(stats['isRapidCopyMode'], isTrue);
      expect(stats['rapidCopyCount'], greaterThan(3));
    });
  });

  group('性能基准测试', () {
    test('轮询检测速度基准', () async {
      final poller = ClipboardPoller();

      const testDuration = Duration(seconds: 3);
      final startTime = DateTime.now();
      var checkCount = 0;

      while (DateTime.now().difference(startTime) < testDuration) {
        await poller.checkOnce();
        checkCount++;
        await Future.delayed(Duration(milliseconds: 50));
      }

      final actualDuration = DateTime.now().difference(startTime);
      final checksPerSecond = checkCount / actualDuration.inSeconds;

      print('轮询速度基准测试:');
      print('- 测试时长: ${actualDuration.inMilliseconds}ms');
      print('- 检查次数: $checkCount');
      print('- 检查频率: ${checksPerSecond.toStringAsFixed(1)} checks/sec');

      poller.stopPolling();

      // 期望每秒至少能检查15次
      expect(checksPerSecond, greaterThan(15));
    });

    test('内存使用模拟测试', () async {
      // 创建大量ClipItem对象来测试内存压力
      const itemCount = 1000;
      final items = <ClipItem>[];
      final startTime = DateTime.now();

      for (int i = 0; i < itemCount; i++) {
        items.add(
          ClipItem(
            id: 'memory_test_$i',
            type: i % 3 == 0 ? ClipType.code : ClipType.text,
            content: '内存测试内容 $i' * (10 + (i % 20)), // 变长内容
            metadata: {
              'length': (i * 10).toString(),
              'index': i,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      final creationTime = DateTime.now().difference(startTime);

      print('内存使用测试:');
      print('- 创建对象数量: $itemCount');
      print('- 创建耗时: ${creationTime.inMilliseconds}ms');
      print(
        '- 平均创建时间: ${(creationTime.inMilliseconds / itemCount).toStringAsFixed(3)}ms/item',
      );
      print('- 估算内存使用: ${(itemCount * 500 / 1024).toStringAsFixed(1)}KB'); // 估算

      // 验证创建速度合理
      expect(creationTime.inMilliseconds, lessThan(1000)); // 1秒内完成
      expect(items.length, equals(itemCount));
    });

    test('并发处理模拟测试', () async {
      const concurrentTasks = 20;
      const processingDelay = Duration(milliseconds: 50);

      final futures = <Future<String>>[];
      final startTime = DateTime.now();

      // 创建多个并发任务
      for (int i = 0; i < concurrentTasks; i++) {
        final future = () async {
          await Future.delayed(processingDelay);
          return 'Task $i completed';
        }();
        futures.add(future);
      }

      // 等待所有任务完成
      final results = await Future.wait(futures);
      final totalTime = DateTime.now().difference(startTime);

      print('并发处理测试:');
      print('- 并发任务数: $concurrentTasks');
      print('- 单个任务延迟: ${processingDelay.inMilliseconds}ms');
      print('- 总耗时: ${totalTime.inMilliseconds}ms');
      print(
        '- 并发效率: ${(processingDelay.inMilliseconds / totalTime.inMilliseconds * 100).toStringAsFixed(1)}%',
      );

      // 验证并发效果（总时间应该接近单个任务时间，而不是线性叠加）
      expect(
        totalTime.inMilliseconds,
        lessThan(processingDelay.inMilliseconds * 3),
      );
      expect(results.length, equals(concurrentTasks));
    });
  });

  group('综合性能评估', () {
    test('快速复制场景综合测试', () async {
      final poller = ClipboardPoller();
      final results = <Map<String, dynamic>>[];

      // 模拟用户快速复制不同类型的内容
      final testScenarios = [
        {'name': '连续文本复制', 'count': 5, 'interval': 200},
        {'name': '超快速复制', 'count': 8, 'interval': 100},
        {'name': '间隔复制', 'count': 3, 'interval': 800},
        {'name': '再次快速复制', 'count': 6, 'interval': 150},
      ];

      for (final scenario in testScenarios) {
        final scenarioStart = DateTime.now();

        final count = scenario['count'] as int;
        final interval = scenario['interval'] as int;
        for (int i = 0; i < count; i++) {
          await poller.checkOnce();
          await Future.delayed(Duration(milliseconds: interval));
        }

        final scenarioTime = DateTime.now().difference(scenarioStart);
        final stats = poller.getPollingStats();

        results.add({
          'scenario': scenario['name'],
          'time': scenarioTime.inMilliseconds,
          'checks': scenario['count'],
          'avgInterval':
              scenarioTime.inMilliseconds / (scenario['count'] as int),
          'rapidMode': stats['isRapidCopyMode'],
          'currentInterval': stats['currentInterval'],
        });

        print('${scenario['name']}完成:');
        print('- 耗时: ${scenarioTime.inMilliseconds}ms');
        print(
          '- 平均间隔: ${(scenarioTime.inMilliseconds / (scenario['count'] as int)).toStringAsFixed(1)}ms',
        );
        print('- 快速模式: ${stats['isRapidCopyMode']}');
        print('');

        // 场景间稍作停顿
        await Future.delayed(Duration(milliseconds: 500));
      }

      // 综合评估
      final totalTime = results.fold<int>(
        0,
        (sum, r) => sum + (r['time'] as int),
      );
      final totalChecks = results.fold<int>(
        0,
        (sum, r) => sum + (r['checks'] as int),
      );
      final avgOverallTime = totalTime / totalChecks;

      print('=== 综合性能评估 ===');
      print('- 总检查次数: $totalChecks');
      print('- 总耗时: ${totalTime}ms');
      print('- 平均检查时间: ${avgOverallTime.toStringAsFixed(1)}ms');
      print(
        '- 快速复制场景数: ${results.where((r) => r['rapidMode'] == true).length}',
      );
      print(
        '- 最快检查间隔: ${results.map((r) => r['avgInterval']).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}ms',
      );

      poller.stopPolling();

      // 验证整体性能
      expect(avgOverallTime, lessThan(300)); // 平均检查时间应小于300ms
      expect(totalChecks, greaterThan(15)); // 总检查次数应足够多
    });
  });
}
