import 'package:clip_flow_pro/core/services/performance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Monitoring Tests', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService.instance;
    });

    tearDown(() {
      performanceService.stopMonitoring();
    });

    test('should initialize with default values', () {
      final metrics = performanceService.getCurrentMetrics();

      expect(metrics.fps, equals(60.0));
      expect(metrics.memoryUsage, greaterThanOrEqualTo(0.0));
      expect(metrics.cpuUsage, greaterThanOrEqualTo(0.0));
      expect(metrics.jankCount, equals(0));
    });

    test('should start and stop monitoring correctly', () {
      expect(performanceService.isMonitoring, isFalse);

      performanceService.startMonitoring();
      expect(performanceService.isMonitoring, isTrue);

      performanceService.stopMonitoring();
      expect(performanceService.isMonitoring, isFalse);
    });

    test('should provide monitoring overhead information', () {
      final overhead = performanceService.getMonitoringOverhead();

      expect(overhead, isA<Map<String, dynamic>>());
      expect(overhead.containsKey('isActive'), isTrue);
      expect(overhead.containsKey('frameTimesCount'), isTrue);
      expect(overhead.containsKey('maxFrameTimesCount'), isTrue);
      expect(overhead.containsKey('updateInterval'), isTrue);
      expect(overhead.containsKey('isDebugMode'), isTrue);
      expect(overhead.containsKey('isReleaseMode'), isTrue);
    });

    test('should reset jank count', () {
      performanceService.startMonitoring();

      // 模拟一些卡顿
      performanceService.resetJankCount();

      final metrics = performanceService.getCurrentMetrics();
      expect(metrics.jankCount, equals(0));
    });

    test('should record database query time', () {
      const testQueryTime = 25.5;
      performanceService.recordDbQueryTime(testQueryTime);

      final metrics = performanceService.getCurrentMetrics();
      expect(metrics.dbQueryTime, equals(testQueryTime));
    });

    test('should record clipboard capture time', () {
      const testCaptureTime = 15.2;
      performanceService.recordClipboardCaptureTime(testCaptureTime);

      final metrics = performanceService.getCurrentMetrics();
      expect(metrics.clipboardCaptureTime, equals(testCaptureTime));
    });

    test('should handle multiple start/stop cycles', () {
      for (var i = 0; i < 3; i++) {
        performanceService.startMonitoring();
        expect(performanceService.isMonitoring, isTrue);

        performanceService.stopMonitoring();
        expect(performanceService.isMonitoring, isFalse);
      }
    });

    test('should maintain reasonable memory usage', () {
      performanceService.startMonitoring();

      // 等待一些指标收集
      Future.delayed(const Duration(milliseconds: 100));

      final overhead = performanceService.getMonitoringOverhead();
      final frameTimesCount = overhead['frameTimesCount'] as int;
      final maxFrameTimesCount = overhead['maxFrameTimesCount'] as int;

      expect(frameTimesCount, lessThanOrEqualTo(maxFrameTimesCount));
    });
  });

  group('PerformanceMetrics Tests', () {
    test('should create metrics with all required fields', () {
      final now = DateTime.now();
      final metrics = PerformanceMetrics(
        fps: 58.5,
        memoryUsage: 125.3,
        cpuUsage: 12.7,
        jankCount: 2,
        dbQueryTime: 45.2,
        clipboardCaptureTime: 23.1,
        timestamp: now,
      );

      expect(metrics.fps, equals(58.5));
      expect(metrics.memoryUsage, equals(125.3));
      expect(metrics.cpuUsage, equals(12.7));
      expect(metrics.jankCount, equals(2));
      expect(metrics.dbQueryTime, equals(45.2));
      expect(metrics.clipboardCaptureTime, equals(23.1));
      expect(metrics.timestamp, equals(now));
    });
  });
}
