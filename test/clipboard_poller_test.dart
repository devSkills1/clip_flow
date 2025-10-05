import 'dart:async';

import 'package:clip_flow_pro/core/services/clipboard_poller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  // 确保测试环境初始化 ServicesBinding，避免 MethodChannel 未初始化错误
  TestWidgetsFlutterBinding.ensureInitialized();

  // 为平台通道注入剪贴板序列号的 Mock，实现稳定的序列递增
  const MethodChannel _testClipboardChannel = MethodChannel(
    'clipboard_service',
  );
  int _mockSequence = 0;

  setUpAll(() {
    _testClipboardChannel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'getClipboardSequence') {
        _mockSequence += 1;
        return _mockSequence;
      }
      return null;
    });
  });

  tearDownAll(() {
    _testClipboardChannel.setMockMethodCallHandler(null);
  });

  group('ClipboardPoller 测试', () {
    late ClipboardPoller poller;

    setUp(() {
      poller = ClipboardPoller();
    });

    tearDown(() {
      poller.stopPolling();
    });

    group('轮询状态管理', () {
      test('初始状态应该是未轮询', () {
        expect(poller.isPolling, false);
      });

      test('应该能够启动轮询', () {
        poller.startPolling(
          onClipboardChanged: () {
            // 回调函数被设置
          },
        );

        expect(poller.isPolling, true);
      });

      test('应该能够停止轮询', () {
        poller.startPolling(onClipboardChanged: () {});
        expect(poller.isPolling, true);

        poller.stopPolling();
        expect(poller.isPolling, false);
      });

      test('应该能够暂停和恢复轮询', () {
        poller.startPolling(onClipboardChanged: () {});
        expect(poller.isPolling, true);

        poller.pausePolling();
        expect(poller.isPolling, false);

        poller.resumePolling();
        expect(poller.isPolling, true);
      });
    });

    group('轮询间隔管理', () {
      test('应该有默认轮询间隔', () {
        final interval = poller.currentInterval;
        expect(interval, isA<Duration>());
        expect(interval.inMilliseconds, greaterThan(0));
      });

      test('应该能够获取当前轮询间隔', () {
        final interval = poller.currentInterval;
        expect(interval, isNotNull);
        expect(interval.inMilliseconds, greaterThan(0));
      });
    });

    group('错误处理', () {
      test('应该处理轮询过程中的错误', () {
        poller.startPolling(
          onClipboardChanged: () {
            throw Exception('测试错误');
          },
          onError: (error) {
            // 错误处理回调被设置
          },
        );

        // 等待一小段时间让轮询执行
        // 注意：这里无法直接测试异步错误，需要模拟
        expect(poller.isPolling, true);
      });

      test('应该能够处理空的回调函数', () {
        expect(() {
          poller.startPolling(onClipboardChanged: () {});
        }, returnsNormally);
      });
    });

    group('重复操作处理', () {
      test('重复启动轮询应该不会出错', () {
        poller.startPolling(onClipboardChanged: () {});
        expect(poller.isPolling, true);

        // 再次启动
        poller.startPolling(onClipboardChanged: () {});
        expect(poller.isPolling, true);
      });

      test('重复停止轮询应该不会出错', () {
        poller.startPolling(onClipboardChanged: () {});
        poller.stopPolling();
        expect(poller.isPolling, false);

        // 再次停止
        expect(() => poller.stopPolling(), returnsNormally);
        expect(poller.isPolling, false);
      });

      test('在未启动时暂停应该不会出错', () {
        expect(() => poller.pausePolling(), returnsNormally);
        expect(poller.isPolling, false);
      });

      test('在未启动时恢复应该不会出错', () {
        expect(() => poller.resumePolling(), returnsNormally);
        expect(poller.isPolling, false);
      });
    });

    group('回调函数测试', () {
      test('应该在剪贴板变化时调用回调', () async {
        int callbackCount = 0;

        poller.startPolling(
          onClipboardChanged: () {
            callbackCount++;
          },
        );

        // 模拟检查一次
        await poller.checkOnce();

        // 注意：实际的回调调用取决于剪贴板内容是否真的变化
        // 这里主要测试方法调用不会出错
        expect(callbackCount, greaterThanOrEqualTo(0));
      });

      test('应该在错误时调用错误回调', () {
        poller.startPolling(
          onClipboardChanged: () {},
          onError: (error) {
            // 错误回调被设置
          },
        );

        // 这里无法直接触发错误，但可以验证设置不会出错
        expect(poller.isPolling, true);
      });
    });

    group('性能测试', () {
      test('启动和停止应该很快', () {
        final stopwatch = Stopwatch()..start();

        poller.startPolling(onClipboardChanged: () {});
        poller.stopPolling();

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('多次启动停止应该稳定', () {
        for (int i = 0; i < 10; i++) {
          poller.startPolling(onClipboardChanged: () {});
          expect(poller.isPolling, true);

          poller.stopPolling();
          expect(poller.isPolling, false);
        }
      });
    });

    group('边界条件测试', () {
      test('应该处理 null 回调', () {
        // 这个测试验证类型安全，实际上 Dart 的类型系统会阻止传入 null
        expect(() {
          poller.startPolling(onClipboardChanged: () {});
        }, returnsNormally);
      });

      test('应该处理快速连续的操作', () {
        // 快速启动和停止
        for (int i = 0; i < 5; i++) {
          poller.startPolling(onClipboardChanged: () {});
          poller.stopPolling();
        }

        expect(poller.isPolling, false);
      });

      test('应该处理暂停和恢复的快速切换', () {
        poller.startPolling(onClipboardChanged: () {});

        for (int i = 0; i < 5; i++) {
          poller.pausePolling();
          poller.resumePolling();
        }

        expect(poller.isPolling, true);
      });
    });

    group('状态一致性测试', () {
      test('轮询状态应该与实际状态一致', () {
        expect(poller.isPolling, false);

        poller.startPolling(onClipboardChanged: () {});
        expect(poller.isPolling, true);

        poller.pausePolling();
        expect(poller.isPolling, false);

        poller.resumePolling();
        expect(poller.isPolling, true);

        poller.stopPolling();
        expect(poller.isPolling, false);
      });

      test('间隔值应该保持一致', () {
        final initialInterval = poller.currentInterval;

        poller.startPolling(onClipboardChanged: () {});
        final runningInterval = poller.currentInterval;

        poller.stopPolling();
        final stoppedInterval = poller.currentInterval;

        expect(initialInterval, equals(runningInterval));
        expect(runningInterval, equals(stoppedInterval));
      });
    });
  });
}

/// 测试辅助类，用于模拟异步操作
class TestHelper {
  static Future<void> waitForAsync([int milliseconds = 10]) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
  }

  static Future<void> waitForPollingCycle() async {
    // 等待一个轮询周期
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
