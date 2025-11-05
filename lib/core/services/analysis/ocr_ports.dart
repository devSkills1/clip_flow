import 'dart:async';
import 'dart:typed_data';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/models/ocr_enhanced_clip_item.dart';

/// OCR服务端口接口
///
/// 负责光学字符识别功能，包括：
/// - 图片文本识别
/// - OCR结果管理
/// - 多语言支持
/// - 异步处理队列
abstract class OCRServicePort {
  /// 初始化OCR服务
  Future<void> initialize();

  /// 释放OCR资源
  Future<void> dispose();

  /// 异步识别图片中的文本
  ///
  /// [imageData] 图片二进制数据
  /// [language] 可选的目标语言代码（如 'zh-CN', 'en-US'）
  /// 返回识别的文本内容
  Future<String> recognizeText(Uint8List imageData, {String? language});

  /// 异步识别图片并返回增强结果
  ///
  /// [item] 包含图片的剪贴项
  /// [language] 可选的目标语言代码
  /// 返回包含OCR结果的增强项
  Future<OCREnhancedClipItem> processClipItem(
    ClipItem item, {
    String? language,
    bool forceReprocess = false,
  });

  /// 检查是否支持OCR
  bool get isSupported;

  /// 获取支持的语言列表
  Future<List<String>> getSupportedLanguages();

  /// 设置默认语言
  Future<void> setDefaultLanguage(String language);

  /// 获取OCR队列状态
  OCRQueueStatus getQueueStatus();

  /// 清空OCR处理队列
  Future<void> clearQueue();

  /// 取消特定项目的OCR处理
  Future<void> cancelProcessing(String itemId);
}

/// OCR管理服务端口接口
///
/// 负责OCR功能的高级管理，包括：
/// - OCR处理队列管理
/// - 结果缓存和去重
/// - 批量处理
/// - 性能优化
abstract class OCRManagerPort {
  /// 初始化OCR管理器
  Future<void> initialize();

  /// 添加项目到OCR处理队列
  ///
  /// [item] 需要OCR处理的剪贴项
  /// [priority] 处理优先级
  /// 返回OCR处理任务的Future
  Future<OCREnhancedClipItem> enqueueForOCR(
    ClipItem item, {
    OCRPriority priority = OCRPriority.normal,
    String? language,
  });

  /// 批量OCR处理
  ///
  /// [items] 需要处理的剪贴项列表
  /// [language] 可选的目标语言
  /// 返回处理结果流
  Stream<OCREnhancedClipItem> batchProcessOCR(
    List<ClipItem> items, {
    String? language,
  });

  /// 检查OCR结果是否已缓存
  ///
  /// [itemId] 剪贴项ID
  /// 返回缓存的OCR文本（如果有）
  Future<String?> getCachedOCRText(String itemId);

  /// 获取OCR处理状态
  ///
  /// [itemId] 剪贴项ID
  /// 返回当前处理状态
  Future<OCRProcessingStatus> getProcessingStatus(String itemId);

  /// 清理OCR缓存
  ///
  /// [olderThan] 清理早于此时间的缓存
  Future<void> cleanCache({Duration? olderThan});

  /// 预热OCR引擎
  /// 预加载OCR模型以减少首次处理延迟
  Future<void> warmupEngine();

  /// 获取OCR统计信息
  Future<OCRStatistics> getStatistics();
}

/// OCR复制服务端口接口
///
/// 负责OCR相关的复制功能，包括：
/// - 智能复制策略
/// - 格式化输出
/// - 复制历史记录
abstract class OCRCopyServicePort {
  /// 复制图片内容
  ///
  /// [item] OCR增强的剪贴项
  /// 将图片复制到剪贴板
  Future<void> copyImage(OCREnhancedClipItem item);

  /// 复制OCR文本
  ///
  /// [item] OCR增强的剪贴项
  /// [format] 文本格式（纯文本、带格式等）
  /// 将OCR识别的文本复制到剪贴板
  Future<void> copyOCRText(
    OCREnhancedClipItem item, {
    OCRTextFormat format = OCRTextFormat.plain,
  });

  /// 智能复制
  ///
  /// [item] OCR增强的剪贴项
  /// [type] 复制类型
  /// 根据类型智能复制内容
  Future<void> smartCopy(
    OCREnhancedClipItem item, {
    OCRCopyType type = OCRCopyType.both,
  });

  /// 获取复制历史
  ///
  /// 返回最近的复制记录
  Future<List<OCRCopyRecord>> getCopyHistory({int limit = 10});

  /// 清空复制历史
  Future<void> clearCopyHistory();
}

/// OCR处理优先级
enum OCRPriority {
  /// 低优先级（后台处理）
  low,

  /// 普通优先级
  normal,

  /// 高优先级（用户主动触发）
  high,

  /// 紧急优先级（立即处理）
  urgent,
}

/// OCR队列状态
class OCRQueueStatus {
  /// 队列中的任务数
  final int pendingCount;

  /// 正在处理的任务数
  final int processingCount;

  /// 已完成的任务数（会话期间）
  final int completedCount;

  /// 失败的任务数（会话期间）
  final int failedCount;

  /// 队列是否被暂停
  final bool isPaused;

  /// 预估等待时间（秒）
  final int estimatedWaitTime;

  const OCRQueueStatus({
    required this.pendingCount,
    required this.processingCount,
    required this.completedCount,
    required this.failedCount,
    this.isPaused = false,
    this.estimatedWaitTime = 0,
  });
}

/// OCR统计信息
class OCRStatistics {
  /// 总处理数
  final int totalProcessed;

  /// 成功数
  final int successCount;

  /// 失败数
  final int failureCount;

  /// 平均处理时间（毫秒）
  final int averageProcessingTime;

  /// 缓存命中数
  final int cacheHits;

  /// 缓存未命中数
  final int cacheMisses;

  /// 当前处理的图片类型分布
  final Map<String, int> imageTypeDistribution;

  /// 最常用的语言
  final List<String> topLanguages;

  const OCRStatistics({
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    required this.averageProcessingTime,
    required this.cacheHits,
    required this.cacheMisses,
    required this.imageTypeDistribution,
    required this.topLanguages,
  });

  /// 计算成功率
  double get successRate {
    if (totalProcessed == 0) return 0.0;
    return successCount / totalProcessed;
  }

  /// 计算缓存命中率
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    if (total == 0) return 0.0;
    return cacheHits / total;
  }
}

/// OCR文本格式
enum OCRTextFormat {
  /// 纯文本
  plain,

  /// 带格式的文本（保留换行、空格等）
  formatted,

  /// JSON格式（包含元数据）
  json,

  /// Markdown格式
  markdown,
}

/// OCR复制记录
class OCRCopyRecord {
  /// 记录ID
  final String id;

  /// 复制时间
  final DateTime timestamp;

  /// 复制类型
  final OCRCopyType copyType;

  /// 源项目ID
  final String sourceItemId;

  /// 复制的内容摘要
  final String contentSummary;

  /// 复制是否成功
  final bool success;

  /// 错误信息（如果有）
  final String? error;

  const OCRCopyRecord({
    required this.id,
    required this.timestamp,
    required this.copyType,
    required this.sourceItemId,
    required this.contentSummary,
    this.success = true,
    this.error,
  });
}