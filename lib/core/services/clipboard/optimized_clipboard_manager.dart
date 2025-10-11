import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_poller.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_processor.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/performance/async_processing_queue.dart';
import 'package:clip_flow_pro/core/services/storage/database_service.dart';

/// 优化的剪贴板管理器
///
/// 整合所有性能优化，包括：
/// - 快速轮询机制
/// - 异步处理队列
/// - 批量数据库操作
/// - 智能缓存
/// - 防抖和去重
class OptimizedClipboardManager {
  /// 工厂构造：返回单例实例
  factory OptimizedClipboardManager() => _instance;

  /// 私有构造：单例内部初始化
  OptimizedClipboardManager._internal();

  /// 单例实例
  static final OptimizedClipboardManager _instance =
      OptimizedClipboardManager._internal();

  /// 剪贴板轮询器
  final ClipboardPoller _poller = ClipboardPoller();

  /// 剪贴板处理器
  final ClipboardProcessor _processor = ClipboardProcessor();

  /// 异步处理队列
  final AsyncProcessingQueue _processingQueue = AsyncProcessingQueue(
    maxConcurrentTasks: 2,
    maxQueueSize: 50,
  );

  final DatabaseService _database = DatabaseService.instance;

  // 批量写入缓存
  final List<ClipItem> _writeBuffer = [];
  Timer? _batchWriteTimer;
  static const Duration _batchWriteDelay = Duration(milliseconds: 500);

  // 性能监控
  int _totalClipsDetected = 0;
  int _totalClipsProcessed = 0;
  int _totalClipsSaved = 0;
  DateTime? _lastClipTime;

  /// 初始化管理器
  Future<void> initialize() async {
    await _database.initialize();
    _processingQueue.start();
  }

  /// 启动剪贴板监控
  void startMonitoring() {
    _poller.startPolling(
      onClipboardChanged: _handleClipboardChange,
      onError: _handleError,
    );
  }

  /// 停止剪贴板监控
  void stopMonitoring() {
    _poller.stopPolling();
    _processingQueue.stop();
    _batchWriteTimer?.cancel();
    _batchWriteTimer = null;

    // 保存剩余的批量数据
    if (_writeBuffer.isNotEmpty) {
      _flushWriteBuffer();
    }
  }

  /// 处理剪贴板变化
  Future<void> _handleClipboardChange() async {
    try {
      _totalClipsDetected++;
      _lastClipTime = DateTime.now();

      await Log.d(
        'Clipboard change detected',
        tag: 'OptimizedClipboardManager',
        fields: {
          'totalDetected': _totalClipsDetected,
          'isRapidCopyMode':
              _poller.getPollingStats()['isRapidCopyMode'] ?? false,
        },
      );

      // 处理剪贴板内容
      final clipItem = await _processor.processClipboardContent();
      if (clipItem == null) return;

      _totalClipsProcessed++;

      // 添加到异步处理队列
      await _addToProcessingQueue(clipItem);
    } on Exception catch (e) {
      await Log.e(
        'Failed to handle clipboard change',
        tag: 'OptimizedClipboardManager',
        error: e,
      );
    }
  }

  /// 添加到处理队列
  Future<void> _addToProcessingQueue(ClipItem item) async {
    // 根据类型设置优先级
    final Priority priority;
    switch (item.type) {
      case ClipType.image:
      case ClipType.video:
        priority = Priority.low; // 图片和视频处理较慢，降低优先级
      case ClipType.file:
      case ClipType.rtf:
      case ClipType.html:
      case ClipType.audio:
        priority = Priority.normal;
      case ClipType.code:
      case ClipType.text:
      case ClipType.json:
      case ClipType.xml:
        priority = Priority.high; // 文本处理较快，提高优先级
      case ClipType.url:
      case ClipType.color:
      case ClipType.email:
        priority = Priority.normal;
    }

    final processedItem = await _processingQueue.addClipboardTask(
      item: item,
      processor: _processClipItem,
      priority: priority,
    );

    if (processedItem != null) {
      await _addToWriteBuffer(processedItem);
    }
  }

  /// 处理剪贴板项目（OCR等耗时操作）
  Future<ClipItem?> _processClipItem(ClipItem item) async {
    try {
      await Log.d(
        'Processing clip item',
        tag: 'OptimizedClipboardManager',
        fields: {
          'id': item.id,
          'type': item.type.name,
        },
      );

      // 如果是图片且需要OCR，这里已经由ClipboardProcessor处理过了
      // 所以直接返回项目
      return item;
    } on Exception catch (e) {
      await Log.e(
        'Failed to process clip item',
        tag: 'OptimizedClipboardManager',
        error: e,
        fields: {'id': item.id},
      );
      return null;
    }
  }

  /// 添加到写入缓冲区
  Future<void> _addToWriteBuffer(ClipItem item) async {
    _writeBuffer.add(item);

    // 如果缓冲区满了或者这是高优先级项目，立即写入
    if (_writeBuffer.length >= 10 || item.type == ClipType.text) {
      _scheduleBatchWrite();
    } else {
      // 否则延迟批量写入
      _scheduleBatchWrite();
    }
  }

  /// 调度批量写入
  void _scheduleBatchWrite() {
    _batchWriteTimer?.cancel();
    _batchWriteTimer = Timer(_batchWriteDelay, _flushWriteBuffer);
  }

  /// 刷新写入缓冲区
  Future<void> _flushWriteBuffer() async {
    if (_writeBuffer.isEmpty) return;

    final itemsToWrite = List<ClipItem>.from(_writeBuffer);
    _writeBuffer.clear();

    try {
      await Log.d(
        'Flushing write buffer',
        tag: 'OptimizedClipboardManager',
        fields: {'count': itemsToWrite.length},
      );

      // 批量写入数据库
      await _batchInsertItems(itemsToWrite);
      _totalClipsSaved += itemsToWrite.length;

      await Log.d(
        'Write buffer flushed successfully',
        tag: 'OptimizedClipboardManager',
        fields: {'count': itemsToWrite.length},
      );
    } on Exception catch (e) {
      await Log.e(
        'Failed to flush write buffer',
        tag: 'OptimizedClipboardManager',
        error: e,
        fields: {'count': itemsToWrite.length},
      );

      // 如果批量写入失败，尝试单独写入
      for (final item in itemsToWrite) {
        try {
          await _database.insertClipItem(item);
          _totalClipsSaved++;
        } on Exception catch (itemError) {
          await Log.e(
            'Failed to save individual item',
            tag: 'OptimizedClipboardManager',
            error: itemError,
            fields: {'id': item.id},
          );
        }
      }
    }
  }

  /// 批量插入剪贴板项目
  Future<void> _batchInsertItems(List<ClipItem> items) async {
    if (items.isEmpty) return;

    // 使用数据库的批量插入功能
    final stopwatch = Stopwatch()..start();

    try {
      await _database.batchInsertClipItems(items);

      stopwatch.stop();

      await Log.d(
        'Batch insert completed',
        tag: 'OptimizedClipboardManager',
        fields: {
          'count': items.length,
          'duration': stopwatch.elapsedMilliseconds,
          'avgTimePerItem': stopwatch.elapsedMilliseconds / items.length,
        },
      );
    } on Exception catch (e) {
      stopwatch.stop();
      await Log.e(
        'Batch insert failed',
        tag: 'OptimizedClipboardManager',
        error: e,
        fields: {
          'count': items.length,
          'duration': stopwatch.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  /// 处理错误
  void _handleError(String error) {
    Log.e(
      'Clipboard monitoring error',
      tag: 'OptimizedClipboardManager',
      error: Exception(error),
    );
  }

  /// 获取综合性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    final pollerStats = _poller.getPollingStats();
    final queueStats = _processingQueue.getStats();
    final processorStats = _processor.getPerformanceMetrics();

    final processingRate = _totalClipsDetected > 0
        ? (_totalClipsProcessed / _totalClipsDetected * 100)
        : 0.0;

    final saveRate = _totalClipsProcessed > 0
        ? (_totalClipsSaved / _totalClipsProcessed * 100)
        : 0.0;

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'detection': {
        'totalDetected': _totalClipsDetected,
        'totalProcessed': _totalClipsProcessed,
        'processingRate': processingRate.toStringAsFixed(1),
        'lastClipTime': _lastClipTime?.toIso8601String(),
        ...pollerStats,
      },
      'processing': {
        'queue': queueStats,
        'processor': processorStats,
      },
      'storage': {
        'totalSaved': _totalClipsSaved,
        'saveRate': saveRate.toStringAsFixed(1),
        'writeBufferSize': _writeBuffer.length,
        'batchWriteActive': _batchWriteTimer?.isActive ?? false,
      },
      'overall': {
        'efficiency': {
          'detectionToProcessing': processingRate.toStringAsFixed(1),
          'processingToStorage': saveRate.toStringAsFixed(1),
          'overall': (processingRate * saveRate / 100).toStringAsFixed(1),
        },
      },
    };
  }

  /// 重置统计信息
  void resetStats() {
    _totalClipsDetected = 0;
    _totalClipsProcessed = 0;
    _totalClipsSaved = 0;
    _lastClipTime = null;
    _poller.resetStats();
    _processingQueue.resetStats();
  }

  /// 强制刷新所有缓冲区
  Future<void> flushAllBuffers() async {
    await _flushWriteBuffer();
  }

  /// 检查是否在快速复制模式
  bool get isRapidCopyMode =>
      (_poller.getPollingStats()['isRapidCopyMode'] as bool?) ?? false;

  /// 获取当前轮询间隔
  Duration get currentPollingInterval => Duration(
    milliseconds:
        (_poller.getPollingStats()['currentInterval'] as int?) ?? 1000,
  );

  /// 获取队列状态
  Map<String, dynamic> get queueStatus => _processingQueue.getStats();

  /// 公共方法：添加剪贴板项目到处理队列（用于测试）
  Future<void> addToProcessingQueue(ClipItem item) async {
    await _addToProcessingQueue(item);
  }

  /// 销毁管理器
  Future<void> dispose() async {
    stopMonitoring();
    await flushAllBuffers();
  }
}
