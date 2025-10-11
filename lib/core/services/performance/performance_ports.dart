import 'dart:async';

/// 性能服务端口接口
///
/// 负责性能监控和优化，包括：
/// - 性能指标收集
/// - 性能分析
/// - 优化建议
abstract class PerformanceServicePort {
  /// 记录性能指标
  Future<void> recordMetric(
    String name,
    dynamic value, {
    Map<String, dynamic>? tags,
  });

  /// 获取性能报告
  Future<Map<String, dynamic>> getPerformanceReport();

  /// 获取性能趋势
  Future<List<Map<String, dynamic>>> getPerformanceTrends(
    String metric,
    Duration period,
  );

  /// 分析性能瓶颈
  Future<List<String>> analyzeBottlenecks();

  /// 获取优化建议
  Future<List<String>> getOptimizationSuggestions();

  /// 重置性能数据
  Future<void> resetPerformanceData();
}

/// 异步处理队列端口接口
///
/// 负责异步任务处理，包括：
/// - 任务队列管理
/// - 任务调度
/// - 并发控制
abstract class AsyncProcessingQueuePort {
  /// 添加任务到队列
  Future<void> addTask(Future<void> Function() task, {int priority = 0});

  /// 获取队列状态
  Map<String, dynamic> getQueueStatus();

  /// 暂停队列处理
  void pauseQueue();

  /// 恢复队列处理
  void resumeQueue();

  /// 清空队列
  Future<void> clearQueue();

  /// 设置最大并发数
  void setMaxConcurrency(int maxConcurrency);

  /// 获取队列统计信息
  Map<String, dynamic> getQueueStats();
}
