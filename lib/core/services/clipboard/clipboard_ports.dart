import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:flutter/foundation.dart';

/// 剪贴板服务端口接口
///
/// 定义剪贴板服务的核心能力，包括：
/// - 剪贴板内容监听
/// - 剪贴板内容设置
/// - 轮询控制
/// - 状态查询
abstract class ClipboardServicePort {
  /// 剪贴板变更流
  Stream<ClipItem> get clipboardStream;

  /// 初始化剪贴板服务
  Future<void> initialize();

  /// 停止剪贴板服务
  Future<void> dispose();

  /// 设置剪贴板内容
  Future<bool> setClipboardContent(ClipItem item);

  /// 获取当前剪贴板内容类型
  Future<ClipType?> getCurrentClipboardType();

  /// 检查剪贴板是否有内容
  Future<bool> hasClipboardContent();

  /// 清空剪贴板
  Future<bool> clearClipboard();

  /// 获取轮询状态
  bool get isPolling;

  /// 获取当前轮询间隔
  Duration get currentPollingInterval;

  /// 暂停轮询
  void pausePolling();

  /// 恢复轮询
  void resumePolling();

  /// 获取轮询器统计信息
  Map<String, dynamic> getPollingStats();
}

/// 剪贴板处理器端口接口
///
/// 负责处理和转换剪贴板内容，包括：
/// - 内容缓存和去重
/// - 元数据提取
/// - 文件保存和管理
/// - 图片处理和缩略图生成
/// - 富文本内容处理
abstract class ClipboardProcessorPort {
  /// 处理剪贴板内容并创建 ClipItem
  Future<ClipItem?> processClipboardContent();

  /// 清理缓存
  void clearCache();

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats();

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics();
}

/// 剪贴板轮询器端口接口
///
/// 负责管理剪贴板的轮询检测，包括：
/// - 自适应轮询间隔调整
/// - 平台特定的剪贴板序列检查
/// - 轮询状态管理
/// - 性能优化的轮询策略
/// - 智能调度和资源管理
abstract class ClipboardPollerPort {
  /// 开始轮询
  void startPolling({
    VoidCallback? onClipboardChanged,
    void Function(String error)? onError,
  });

  /// 停止轮询
  void stopPolling();

  /// 暂停轮询
  void pausePolling();

  /// 恢复轮询
  void resumePolling();

  /// 手动触发一次检查
  Future<bool> checkOnce();

  /// 获取当前轮询间隔
  Duration get currentInterval;

  /// 获取轮询状态
  bool get isPolling;

  /// 是否处于空闲模式
  bool get isIdleMode;

  /// 获取轮询统计信息
  Map<String, dynamic> getPollingStats();

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics();

  /// 重置统计信息
  void resetStats();
}

/// 剪贴板检测器端口接口
///
/// 负责检测剪贴板内容类型
abstract class ClipboardDetectorPort {
  /// 检测内容类型
  ClipType detectContentType(String content);

  /// 检测文件类型
  ClipType detectFileType(String filePath);
}
