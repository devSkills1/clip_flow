import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/platform/system/permission_service.dart';
import 'package:clip_flow_pro/core/services/storage/path_service.dart';
import 'package:flutter/services.dart';

import 'package:clip_flow_pro/core/services/clipboard/clipboard_detector.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_poller.dart';
import 'package:clip_flow_pro/core/services/clipboard/clipboard_processor.dart';

/// 剪贴板服务协调器
///
/// 协调 ClipboardDetector、ClipboardPoller 和 ClipboardProcessor 三个组件，
/// 提供统一的剪贴板监听和处理接口。
class ClipboardService {
  /// 工厂构造：返回剪贴板服务单例
  factory ClipboardService() => _instance;

  /// 私有构造：单例内部初始化
  ClipboardService._internal() {
    _detector = ClipboardDetector();
    _poller = ClipboardPoller();
    _processor = ClipboardProcessor();
  }

  /// 单例实例
  static final ClipboardService _instance = ClipboardService._internal();

  /// 获取剪贴板服务单例
  static ClipboardService get instance => _instance;

  // 子组件
  late final ClipboardDetector _detector;
  late final ClipboardPoller _poller;
  late final ClipboardProcessor _processor;

  final StreamController<ClipItem> _clipboardController =
      StreamController<ClipItem>.broadcast();

  /// 剪贴板变更流（广播）
  ///
  /// 订阅该流以获取新的剪贴项事件。
  Stream<ClipItem> get clipboardStream => _clipboardController.stream;

  bool _isInitialized = false;
  // 关闭保护：避免在关闭后继续向流推送事件
  bool _isShuttingDown = false;

  /// 初始化剪贴板服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isShuttingDown = false;

      // 检查剪贴板权限
      final permissionStatus = await PermissionService.instance.checkPermission(
        PermissionType.clipboard,
      );

      if (permissionStatus != PermissionStatus.granted) {
        await Log.w(
          'Clipboard permission not granted: $permissionStatus',
          tag: 'clipboard_service',
        );
        // 即使权限未授予，也继续初始化，但会在操作时进行检查
      }

      // 启动轮询器，监听剪贴板变化
      _poller.startPolling(
        onClipboardChanged: _handleClipboardChange,
        onError: (error) => Log.e(
          'ClipboardService polling error',
          tag: 'clipboard_service',
          error: error,
        ),
      );

      _isInitialized = true;
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService initialization failed',
        tag: 'clipboard_service',
        error: e,
      );
      rethrow;
    }
  }

  /// 停止剪贴板服务
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // 标记正在关闭，避免回调期间继续推送事件
      _isShuttingDown = true;
      _isInitialized = false;
      _poller.stopPolling();
      await _clipboardController.close();
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService dispose failed',
        tag: 'clipboard_service',
        error: e,
      );
    }
  }

  /// 处理剪贴板变化
  Future<void> _handleClipboardChange() async {
    // 关闭或未初始化状态下直接忽略
    if (_isShuttingDown || !_isInitialized) return;

    try {
      // 检查剪贴板权限（使用缓存，避免重复弹框）
      final permissionStatus = await PermissionService.instance.checkPermission(
        PermissionType.clipboard,
      );

      if (permissionStatus != PermissionStatus.granted) {
        await Log.d(
          'Clipboard access denied, skipping change handling',
          tag: 'clipboard_service',
        );
        return;
      }

      // 使用处理器处理剪贴板内容
      final clipItem = await _processor.processClipboardContent();

      if (clipItem != null) {
        _clipboardController.add(clipItem);
      }
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService handle clipboard change failed',
        tag: 'clipboard_service',
        error: e,
      );
    }
  }

  /// 设置剪贴板内容
  Future<bool> setClipboardContent(ClipItem item) async {
    try {
      switch (item.type) {
        case ClipType.text:
        case ClipType.code:
        case ClipType.json:
        case ClipType.xml:
        case ClipType.url:
        case ClipType.email:
        case ClipType.color:
          await Clipboard.setData(ClipboardData(text: item.content ?? ''));

        case ClipType.html:
          // HTML 内容设置为富文本
          await _setRichTextContent(item.content ?? '');

        case ClipType.rtf:
          // RTF 内容设置为富文本
          await _setRichTextContent(item.content ?? '');

        case ClipType.image:
          if (item.filePath != null) {
            await _setImageFromFile(item.filePath!);
          }

        case ClipType.file:
          if (item.filePath != null) {
            await _setFileContent(item.filePath!);
          }

        case ClipType.audio:
          if (item.filePath != null) {
            await _setFileContent(item.filePath!);
          }

        case ClipType.video:
          if (item.filePath != null) {
            await _setFileContent(item.filePath!);
          }
      }

      return true;
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService set clipboard content failed',
        tag: 'clipboard_service',
        error: e,
      );
      return false;
    }
  }

  /// 设置富文本内容
  Future<void> _setRichTextContent(String content) async {
    const platform = MethodChannel('clipboard_service');
    await platform.invokeMethod('setRichText', {'content': content});
  }

  /// 设置图片文件到剪贴板
  Future<void> _setImageFromFile(String filePath) async {
    // 使用PathService将路径转换为绝对路径
    final absolutePath = await PathService.instance.resolveAbsolutePath(
      filePath,
    );

    // 检查文件是否存在
    if (!await PathService.instance.fileExists(filePath)) {
      await Log.e(
        'Image file not found for clipboard copy',
        tag: 'clipboard_service',
        fields: {
          'path': absolutePath,
          'sourcePath': filePath,
        },
      );
      return;
    }

    const platform = MethodChannel('clipboard_service');
    await platform.invokeMethod('setClipboardFile', {
      'filePath': absolutePath,
    });
  }

  /// 设置文件到剪贴板
  Future<void> _setFileContent(String filePath) async {
    // 使用PathService将路径转换为绝对路径
    final absolutePath = await PathService.instance.resolveAbsolutePath(
      filePath,
    );

    // 检查文件是否存在
    if (!await PathService.instance.fileExists(filePath)) {
      await Log.e(
        'File not found for clipboard copy',
        tag: 'clipboard_service',
        fields: {
          'path': absolutePath,
          'sourcePath': filePath,
        },
      );
      return;
    }

    const platform = MethodChannel('clipboard_service');
    // 与原生 macOS 插件对齐的方法名：setClipboardFile
    await platform.invokeMethod('setClipboardFile', {
      'filePath': absolutePath,
    });
  }

  /// 获取当前剪贴板内容类型
  Future<ClipType?> getCurrentClipboardType() async {
    try {
      // 检查剪贴板权限
      final permissionStatus = await PermissionService.instance.checkPermission(
        PermissionType.clipboard,
      );

      if (permissionStatus != PermissionStatus.granted) {
        await Log.d(
          'Clipboard access denied for type check',
          tag: 'clipboard_service',
        );
        return null;
      }

      const platform = MethodChannel('clipboard_service');
      final result = await platform.invokeMethod<Map<Object?, Object?>>(
        'getClipboardData',
      );

      if (result == null) return null;

      final data = result.cast<String, dynamic>();
      return _detector.detectContentType(data.toString());
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService get clipboard type failed',
        tag: 'clipboard_service',
        error: e,
      );
      return null;
    }
  }

  /// 检查剪贴板是否有内容
  Future<bool> hasClipboardContent() async {
    try {
      // 检查剪贴板权限
      final permissionStatus = await PermissionService.instance.checkPermission(
        PermissionType.clipboard,
      );

      if (permissionStatus != PermissionStatus.granted) {
        await Log.d(
          'Clipboard access denied for content check',
          tag: 'clipboard_service',
        );
        return false;
      }

      const platform = MethodChannel('clipboard_service');
      final result = await platform.invokeMethod<bool>('hasClipboardContent');
      return result ?? false;
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService check clipboard content failed',
        tag: 'clipboard_service',
        error: e,
      );
      return false;
    }
  }

  /// 清空剪贴板
  Future<bool> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      return true;
    } on Exception catch (e) {
      await Log.e(
        'ClipboardService clear clipboard failed',
        tag: 'clipboard_service',
        error: e,
      );
      return false;
    }
  }

  /// 获取轮询状态
  bool get isPolling => _poller.isPolling;

  /// 获取当前轮询间隔
  Duration get currentPollingInterval => _poller.currentInterval;

  /// 暂停轮询
  void pausePolling() {
    _poller.pausePolling();
  }

  /// 恢复轮询
  void resumePolling() {
    _poller.resumePolling();
  }

  /// 测试用方法：检测内容类型
  ClipType detectContentTypeForTesting(String content) {
    return _detector.detectContentType(content);
  }

  /// 获取轮询器统计信息
  Map<String, dynamic> getPollingStats() {
    return _poller.getPollingStats();
  }
}
