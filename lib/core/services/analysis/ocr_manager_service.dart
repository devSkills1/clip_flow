import 'dart:async';
import 'dart:collection';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/models/ocr_enhanced_clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_copy_service.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_ports.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_ports.dart';
import 'package:clip_flow_pro/core/services/deduplication_service.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';

/// OCR管理器实现
/// 负责OCR功能的队列管理、缓存和批量处理
class OCRManagerService implements OCRManagerPort {
  /// 创建OCR管理器实例
  factory OCRManagerService() => _instance;

  /// 私有构造函数
  OCRManagerService._internal();

  /// 单例实例
  static final OCRManagerService _instance = OCRManagerService._internal();

  /// OCR服务
  OCRServicePort? _ocrService;

  /// 数据库服务
  DatabaseService _databaseService;

  /// 剪贴板服务
  ClipboardServicePort? _clipboardService;

  /// 处理队列（按优先级排序）
  final Queue<OCRTask> _queue = Queue();

  /// 正在处理的任务
  final Set<String> _processingItems = {};

  /// OCR结果缓存
  final Map<String, OCREnhancedClipItem> _cache = {};

  /// 队列状态控制器
  final StreamController<OCRQueueStatus> _statusController =
      StreamController.broadcast();

  /// 处理结果流控制器
  final StreamController<OCREnhancedClipItem> _resultController =
      StreamController.broadcast();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否正在处理队列
  bool _isProcessing = false;

  /// 统计信息
  OCRStatistics? _statistics;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 获取依赖服务 - 暂时使用空实现，后续需要注入实际的服务
      // _ocrService = OCRService();
      _databaseService = DatabaseService.instance;
      // _clipboardService = ClipboardService();

      // 初始化OCR服务
      if (_ocrService != null) {
        await _ocrService!.initialize();
      }

      // 恢复未完成的任务
      await _restorePendingTasks();

      // 启动队列处理器
      _startQueueProcessor();

      _isInitialized = true;
      await Log.i('OCR Manager initialized successfully');
    } on Exception catch (e) {
      await Log.e('Failed to initialize OCR Manager', error: e);
      rethrow;
    }
  }

  @override
  Future<OCREnhancedClipItem> enqueueForOCR(
    ClipItem item, {
    OCRPriority priority = OCRPriority.normal,
    String? language,
  }) async {
    if (!_isInitialized) {
      throw StateError('OCR Manager not initialized');
    }

    // 只处理图片类型
    if (item.type != ClipType.image) {
      throw ArgumentError('Only image items can be processed by OCR');
    }

    // 检查是否已经有OCR结果
    final cached = await getCachedOCRText(item.id);
    if (cached != null && cached.isNotEmpty) {
      await Log.d('OCR text already cached', tag: 'OCRManager', fields: {
        'itemId': item.id,
      });
      return OCREnhancedClipItem.fromClipItem(item.copyWith(ocrText: cached));
    }

    // 创建增强项
    final enhancedItem = OCREnhancedClipItem.fromClipItem(item);

    // 创建OCR任务
    final task = OCRTask(
      id: _generateTaskId(item.id),
      itemId: item.id,
      priority: priority,
      language: language,
      createdAt: DateTime.now(),
      item: enhancedItem,
    );

    // 加入队列
    _insertTaskByPriority(task);

    // 保存到数据库
    await _saveTaskToDatabase(task);

    // 触发队列处理
    _processQueue();

    await Log.i('Item enqueued for OCR', tag: 'OCRManager', fields: {
      'itemId': item.id,
      'priority': priority.name,
    });

    return enhancedItem;
  }

  @override
  Stream<OCREnhancedClipItem> batchProcessOCR(
    List<ClipItem> items, {
    String? language,
  }) async* {
    await Log.i('Starting batch OCR processing', tag: 'OCRManager', fields: {
      'count': items.length,
    });

    final futures = <Future<OCREnhancedClipItem>>[];

    for (final item in items) {
      if (item.type == ClipType.image) {
        final future = enqueueForOCR(
          item,
          priority: OCRPriority.low,
          language: language,
        );
        futures.add(future);
      }
    }

    // 使用Stream.fromFuture转换
    for (final future in futures) {
      try {
        final result = await future;
        yield result;
      } on Exception catch (e) {
        await Log.e('Batch OCR item failed', tag: 'OCRManager', error: e);
        // 继续处理其他项
      }
    }
  }

  @override
  Future<String?> getCachedOCRText(String itemId) async {
    // 先检查内存缓存
    if (_cache.containsKey(itemId)) {
      return _cache[itemId]?.ocrText;
    }

    // 检查数据库
    try {
      final item = await _databaseService.getClipItem(itemId);
      if (item?.ocrText != null && item!.ocrText!.isNotEmpty) {
        // 更新内存缓存
        final enhanced = OCREnhancedClipItem.fromClipItem(item);
        _cache[itemId] = enhanced;
        return item.ocrText;
      }
    } on Exception catch (e) {
      await Log.e('Failed to get cached OCR text', tag: 'OCRManager', error: e);
    }

    return null;
  }

  @override
  Future<OCRProcessingStatus> getProcessingStatus(String itemId) async {
    // 检查是否正在处理
    if (_processingItems.contains(itemId)) {
      return OCRProcessingStatus.processing;
    }

    // 检查队列
    final task = _queue.cast<OCRTask?>().firstWhere(
      (t) => t?.itemId == itemId,
      orElse: () => null,
    );

    if (task != null) {
      return OCRProcessingStatus.pending;
    }

    // 检查是否已完成
    final cached = await getCachedOCRText(itemId);
    if (cached != null) {
      return OCRProcessingStatus.completed;
    }

    return OCRProcessingStatus.pending;
  }

  @override
  Future<void> cleanCache({Duration? olderThan}) async {
    final cutoff = olderThan != null
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 7));

    final keysToRemove = <String>[];

    _cache.forEach((key, value) {
      if (value.ocrTimestamp != null && value.ocrTimestamp!.isBefore(cutoff)) {
        keysToRemove.add(key);
      }
    });

    // 清理内存缓存
    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    // 清理数据库中的OCR缓存
    try {
      await _databaseService.clearOCRCache();
    } on Exception catch (e) {
      await Log.e('Failed to clean OCR cache from database', error: e);
    }

    await Log.i('OCR cache cleaned', tag: 'OCRManager', fields: {
      'removedCount': keysToRemove.length,
    });
  }

  @override
  Future<void> warmupEngine() async {
    if (!_ocrService.isSupported) {
      await Log.w('OCR not supported on this platform');
      return;
    }

    try {
      // 创建测试图片数据
      final testImageData = _createTestImage();

      // 预热OCR引擎
      await _ocrService.recognizeText(testImageData);

      await Log.i('OCR engine warmed up successfully');
    } on Exception catch (e) {
      await Log.e('Failed to warm up OCR engine', error: e);
    }
  }

  @override
  Future<OCRStatistics> getStatistics() async {
    if (_statistics != null) {
      return _statistics!;
    }

    // 从数据库获取统计信息
    try {
      final stats = await _databaseService.getOCRStatistics();
      _statistics = stats;
      return stats;
    } on Exception catch (e) {
      await Log.e('Failed to get OCR statistics', error: e);
      // 返回默认统计
      return const OCRStatistics(
        totalProcessed: 0,
        successCount: 0,
        failureCount: 0,
        averageProcessingTime: 0,
        cacheHits: 0,
        cacheMisses: 0,
        imageTypeDistribution: {},
        topLanguages: [],
      );
    }
  }

  @override
  OCRQueueStatus getQueueStatus() {
    return OCRQueueStatus(
      pendingCount: _queue.length,
      processingCount: _processingItems.length,
      completedCount: _statistics?.successCount ?? 0,
      failedCount: _statistics?.failureCount ?? 0,
      estimatedWaitTime: _calculateEstimatedWaitTime(),
    );
  }

  /// 获取队列状态流
  Stream<OCRQueueStatus> get queueStatusStream => _statusController.stream;

  /// 获取处理结果流
  Stream<OCREnhancedClipItem> get resultStream => _resultController.stream;

  /// 私有方法

  /// 恢复未完成的任务
  Future<void> _restorePendingTasks() async {
    try {
      final pendingItems = await _databaseService.getItemsPendingOCR();

      for (final item in pendingItems) {
        final task = OCRTask(
          id: _generateTaskId(item.id),
          itemId: item.id,
          priority: OCRPriority.normal,
          createdAt: item.updatedAt,
          item: OCREnhancedClipItem.fromClipItem(item),
        );
        _queue.add(task);
      }

      await Log.i('Restored ${pendingItems.length} pending OCR tasks');
    } on Exception catch (e) {
      await Log.e('Failed to restore pending tasks', error: e);
    }
  }

  /// 启动队列处理器
  void _startQueueProcessor() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      _processQueue();
    });
  }

  /// 处理队列
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty || _processingItems.length >= 3) {
      return;
    }

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && _processingItems.length < 3) {
        final task = _queue.removeFirst();
        if (task != null) {
          unawaited(_processTask(task));
        }
      }
    } finally {
      _isProcessing = false;
      _updateQueueStatus();
    }
  }

  /// 处理单个任务
  Future<void> _processTask(OCRTask task) async {
    _processingItems.add(task.itemId);

    try {
      await Log.d('Processing OCR task', tag: 'OCRManager', fields: {
        'taskId': task.id,
        'itemId': task.itemId,
      });

      // 更新状态为处理中
      await _updateTaskStatus(task.itemId, OCRProcessingStatus.processing);

      // 获取图片数据
      final imageData = await _getImageData(task.item.imageItem);

      // 执行OCR
      final ocrText = await _ocrService.recognizeText(
        imageData,
        language: task.language,
      );

      // 创建带OCR结果的增强项
      final enhancedItem = task.item.withOCRResult(
        ocrText: ocrText,
        language: task.language,
        confidence: 0.95, // TODO: 从OCR服务获取实际置信度
      );

      // 更新缓存
      _cache[task.itemId] = enhancedItem;

      // 保存到数据库
      await _databaseService.updateClipItem(enhancedItem.toStorageItem());

      // 发送结果
      _resultController.add(enhancedItem);

      // 更新统计
      _updateStatistics(success: true);

      await Log.i('OCR task completed', tag: 'OCRManager', fields: {
        'taskId': task.id,
        'textLength': ocrText.length,
      });
    } on Exception catch (e) {
      await Log.e('OCR task failed', tag: 'OCRManager', error: e);

      // 更新状态为失败
      await _updateTaskStatus(task.itemId, OCRProcessingStatus.failed);

      // 更新统计
      _updateStatistics(success: false);

      // 重试逻辑
      if (task.retryCount < 3) {
        task.retryCount++;
        _queue.add(task);
        await Log.d('Task queued for retry', tag: 'OCRManager', fields: {
          'taskId': task.id,
          'retryCount': task.retryCount,
        });
      }
    } finally {
      _processingItems.remove(task.itemId);
      _updateQueueStatus();
    }
  }

  /// 按优先级插入任务
  void _insertTaskByPriority(OCRTask task) {
    if (_queue.isEmpty) {
      _queue.add(task);
      return;
    }

    // 找到合适的插入位置
    final queueList = _queue.toList();
    int insertIndex = queueList.length;

    for (int i = 0; i < queueList.length; i++) {
      if (task.priority.index > queueList[i].priority.index) {
        insertIndex = i;
        break;
      }
    }

    if (insertIndex == queueList.length) {
      _queue.add(task);
    } else {
      queueList.insert(insertIndex, task);
      _queue.clear();
      _queue.addAll(queueList);
    }
  }

  /// 更新队列状态
  void _updateQueueStatus() {
    _statusController.add(getQueueStatus());
  }

  /// 更新任务状态
  Future<void> _updateTaskStatus(
    String itemId,
    OCRProcessingStatus status,
  ) async {
    try {
      await _databaseService.updateOCRStatus(itemId, status);
    } on Exception catch (e) {
      await Log.e('Failed to update OCR status', error: e);
    }
  }

  /// 获取图片数据
  Future<Uint8List> _getImageData(ClipItem item) async {
    if (item.filePath != null) {
      final file = File(item.filePath!);
      return await file.readAsBytes();
    }

    if (item.thumbnail != null) {
      return Uint8List.fromList(item.thumbnail!);
    }

    throw Exception('No image data available');
  }

  /// 生成任务ID
  String _generateTaskId(String itemId) {
    return 'ocr_task_${itemId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 保存任务到数据库
  Future<void> _saveTaskToDatabase(OCRTask task) async {
    // 实现数据库保存逻辑
    // 这里可以添加到ocr_queue表
  }

  /// 计算预估等待时间
  int _calculateEstimatedWaitTime() {
    if (_queue.isEmpty) return 0;

    // 假设每个任务平均处理时间为3秒
    return (_queue.length * 3);
  }

  /// 更新统计信息
  void _updateStatistics({required bool success}) {
    final current = _statistics ?? const OCRStatistics(
      totalProcessed: 0,
      successCount: 0,
      failureCount: 0,
      averageProcessingTime: 0,
      cacheHits: 0,
      cacheMisses: 0,
      imageTypeDistribution: {},
      topLanguages: [],
    );

    _statistics = OCRStatistics(
      totalProcessed: current.totalProcessed + 1,
      successCount: current.successCount + (success ? 1 : 0),
      failureCount: current.failureCount + (success ? 0 : 1),
      averageProcessingTime: current.averageProcessingTime, // TODO: 计算实际平均值
      cacheHits: current.cacheHits,
      cacheMisses: current.cacheMisses,
      imageTypeDistribution: Map.from(current.imageTypeDistribution),
      topLanguages: List.from(current.topLanguages),
    );
  }

  /// 创建测试图片
  Uint8List _createTestImage() {
    // 创建一个简单的测试图片
    // 实际实现中应该创建一个包含已知文本的图片
    return Uint8List.fromList([]);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _resultController.close();
    await _ocrService.dispose();
  }
}

/// OCR任务
class OCRTask {
  final String id;
  final String itemId;
  final OCRPriority priority;
  final String? language;
  final DateTime createdAt;
  final OCREnhancedClipItem item;
  int retryCount = 0;

  OCRTask({
    required this.id,
    required this.itemId,
    required this.priority,
    required this.createdAt,
    required this.item,
    this.language,
  });
}

/// 用于不等待Future的辅助函数
void unawaited(Future<void> future) {
  // 故意不等待
}