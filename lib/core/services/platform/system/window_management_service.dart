// ignore_for_file: public_member_api_docs
/*
  解释忽略的诊断：
  - public_member_api_docs：该文件属于内部服务实现，不对外暴露公共 API，发布前会在核心公共接口处补全文档。
*/

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理服务
///
/// 提供统一的窗口状态管理和高级窗口操作功能
class WindowManagementService {
  WindowManagementService._private();

  static final WindowManagementService _instance =
      WindowManagementService._private();
  static WindowManagementService get instance => _instance;

  bool _isInitialized = false;
  WindowState _currentState = WindowState.normal;

  /// 获取当前窗口状态
  WindowState get currentState => _currentState;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化窗口管理服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await windowManager.ensureInitialized();
      await _applyDefaultSettings();
      await _setupEventListeners();
      _isInitialized = true;

      await Log.i('WindowManagementService initialized successfully');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to initialize WindowManagementService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 应用默认窗口设置
  Future<void> _applyDefaultSettings() async {
    try {
      // 设置窗口属性
      await windowManager.setPreventClose(true);
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(
        const Size(ClipConstants.minWindowWidth, ClipConstants.minWindowHeight),
      );
      await windowManager.setMaximumSize(
        const Size(ClipConstants.maxWindowWidth, ClipConstants.maxWindowHeight),
      );

      await Log.i('Applied default window settings');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to apply default window settings',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 设置事件监听器
  Future<void> _setupEventListeners() async {
    windowManager.addListener(_WindowEventListener());
  }

  /// 显示并聚焦窗口
  Future<void> showAndFocus() async {
    try {
      if (!await windowManager.isVisible()) {
        await windowManager.show();
      }

      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }

      await windowManager.focus();
      _updateState(WindowState.focused);

      await Log.i('Window shown and focused');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to show and focus window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 隐藏窗口
  Future<void> hide() async {
    try {
      await windowManager.hide();
      _updateState(WindowState.hidden);

      await Log.i('Window hidden');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to hide window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 最小化窗口
  Future<void> minimize() async {
    try {
      await windowManager.minimize();
      _updateState(WindowState.minimized);

      await Log.i('Window minimized');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to minimize window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 恢复窗口
  Future<void> restore() async {
    try {
      await windowManager.restore();
      await windowManager.focus();
      _updateState(WindowState.focused);

      await Log.i('Window restored');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to restore window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 设置窗口大小
  Future<void> setSize(double width, double height) async {
    try {
      // 确保尺寸在限制范围内
      final clampedWidth = width.clamp(
        ClipConstants.minWindowWidth,
        ClipConstants.maxWindowWidth,
      );
      final clampedHeight = height.clamp(
        ClipConstants.minWindowHeight,
        ClipConstants.maxWindowHeight,
      );

      await windowManager.setSize(Size(clampedWidth, clampedHeight));

      await Log.i('Window size set to ${clampedWidth}x$clampedHeight');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to set window size',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 设置窗口位置
  Future<void> setPosition(double x, double y) async {
    try {
      await windowManager.setPosition(Offset(x, y));

      await Log.i('Window position set to ($x, $y)');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to set window position',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 居中窗口
  Future<void> center() async {
    try {
      await windowManager.center();

      await Log.i('Window centered');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to center window',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 设置窗口总是在最前
  Future<void> setAlwaysOnTop({required bool alwaysOnTop}) async {
    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);

      await Log.i('Window always on top set to $alwaysOnTop');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to set always on top',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 获取窗口信息
  Future<WindowInfo> getWindowInfo() async {
    try {
      final bounds = await windowManager.getBounds();
      final isVisible = await windowManager.isVisible();
      final isMinimized = await windowManager.isMinimized();
      final isMaximized = await windowManager.isMaximized();
      final isFocused = await windowManager.isFocused();
      final isAlwaysOnTop = await windowManager.isAlwaysOnTop();

      return WindowInfo(
        bounds: bounds,
        isVisible: isVisible,
        isMinimized: isMinimized,
        isMaximized: isMaximized,
        isFocused: isFocused,
        isAlwaysOnTop: isAlwaysOnTop,
      );
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to get window info',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 更新窗口状态
  void _updateState(WindowState newState) {
    final oldState = _currentState;
    _currentState = newState;

    if (oldState != newState) {
      Log.d('Window state changed from $oldState to $newState');
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      windowManager.removeListener(_WindowEventListener());
      _isInitialized = false;

      await Log.i('WindowManagementService disposed');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to dispose WindowManagementService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// 窗口状态枚举
enum WindowState {
  normal,
  focused,
  minimized,
  maximized,
  hidden,
}

/// 窗口信息
class WindowInfo {
  const WindowInfo({
    required this.bounds,
    required this.isVisible,
    required this.isMinimized,
    required this.isMaximized,
    required this.isFocused,
    required this.isAlwaysOnTop,
  });

  final Rect bounds;
  final bool isVisible;
  final bool isMinimized;
  final bool isMaximized;
  final bool isFocused;
  final bool isAlwaysOnTop;

  @override
  String toString() {
    return 'WindowInfo('
        'bounds: $bounds, '
        'isVisible: $isVisible, '
        'isMinimized: $isMinimized, '
        'isMaximized: $isMaximized, '
        'isFocused: $isFocused, '
        'isAlwaysOnTop: $isAlwaysOnTop'
        ')';
  }
}

/// 窗口事件监听器
class _WindowEventListener with WindowListener {
  @override
  Future<void> onWindowEvent(String eventName) async {
    await Log.d('Window event: $eventName');
  }

  @override
  Future<void> onWindowClose() async {
    await Log.d('Window close event received');
    // 这里不处理关闭逻辑，让 AppWindowListener 处理
  }

  @override
  Future<void> onWindowMinimize() async {
    await Log.d('Window minimize event received');
    WindowManagementService.instance._updateState(WindowState.minimized);
  }

  @override
  Future<void> onWindowMaximize() async {
    await Log.d('Window maximize event received');
    WindowManagementService.instance._updateState(WindowState.maximized);
  }

  @override
  Future<void> onWindowUnmaximize() async {
    await Log.d('Window unmaximize event received');
    WindowManagementService.instance._updateState(WindowState.normal);
  }

  @override
  Future<void> onWindowRestore() async {
    await Log.d('Window restore event received');
    WindowManagementService.instance._updateState(WindowState.normal);
  }

  Future<void> onWindowShow() async {
    await Log.d('Window show event received');
  }

  Future<void> onWindowHide() async {
    await Log.d('Window hide event received');
    WindowManagementService.instance._updateState(WindowState.hidden);
  }

  @override
  Future<void> onWindowFocus() async {
    await Log.d('Window focus event received');
    WindowManagementService.instance._updateState(WindowState.focused);
  }

  @override
  Future<void> onWindowBlur() async {
    await Log.d('Window blur event received');
    WindowManagementService.instance._updateState(WindowState.normal);
  }
}
