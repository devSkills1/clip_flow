// ignore_for_file: public_member_api_docs
// Reason: Internal service module with documented API interfaces in separate files, avoid_setters_without_getters
/*
  解释忽略的诊断：
  - public_member_api_docs：该文件属于内部服务实现，不对外暴露公共 API，发布前会在核心公共接口处补全文档。
  - avoid_setters_without_getters：我们刻意仅暴露写入入口（setter）以便 Provider 推送最新用户偏好，
    保持字段只读于类内部，避免对外暴露不必要的读取接口造成耦合。
*/

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理服务
///
/// 提供统一的窗口状态管理和高级窗口操作功能，同时集成屏幕信息服务
class WindowManagementService {
  WindowManagementService._private();

  static final WindowManagementService _instance =
      WindowManagementService._private();
  static WindowManagementService get instance => _instance;

  bool _isInitialized = false;
  WindowState _currentState = WindowState.normal;
  _WindowEventListener? _eventListener;

  // ScreenService constants and methods
  static const MethodChannel _screenChannel = MethodChannel(
    'clipboard_service',
  );

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
        const ui.Size(
          ClipConstants.minWindowWidth,
          ClipConstants.minWindowHeight,
        ),
      );
      await windowManager.setMaximumSize(
        const ui.Size(
          ClipConstants.maxWindowWidth,
          ClipConstants.maxWindowHeight,
        ),
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
    _eventListener = _WindowEventListener();
    windowManager.addListener(_eventListener!);
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

      await windowManager.setSize(ui.Size(clampedWidth, clampedHeight));

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

  /// 窗口操作包装器（减少重复的错误处理）
  Future<T> _executeWindowOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    bool enableLogging = true,
  }) async {
    try {
      final result = await operation();
      if (enableLogging) {
        await Log.i('$operationName - 操作成功', tag: 'WindowManagementService');
      }
      return result;
    } on Exception catch (e, stackTrace) {
      await Log.e(
        '$operationName - 操作失败',
        error: e,
        stackTrace: stackTrace,
        tag: 'WindowManagementService',
      );
      rethrow;
    }
  }

  /// 统一的窗口尺寸设置方法
  Future<void> _setWindowConstraints({
    required double width,
    required double height,
    bool enableLogging = false,
  }) async {
    await windowManager.setMinimumSize(ui.Size(width, height));
    await windowManager.setMaximumSize(ui.Size(width, height));
    await windowManager.setSize(ui.Size(width, height));

    if (enableLogging) {
      await Log.i(
        '窗口约束设置完成: ${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)}',
        tag: 'WindowManagementService',
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

  /// 统一的窗口配置方法（替代 setupWindow 和 applyUISettings）
  Future<void> configureWindow(
    UiMode uiMode, {
    BuildContext? context,
    bool enableLogging = true,
    bool applyDelay = true,
    UserPreferences? userPreferences,
  }) async {
    await _executeWindowOperation(
      'UI窗口管理 - 窗口配置',
      () async {
        switch (uiMode) {
          case UiMode.traditional:
            await _configureTraditionalWindow(
              enableLogging: enableLogging,
              applyDelay: applyDelay,
            );
          case UiMode.appSwitcher:
            await _configureAppSwitcherMode(
              context,
              enableLogging: enableLogging,
              applyDelay: applyDelay,
              userPreferences: userPreferences,
            );
        }
      },
    );
  }

  /// 启动时设置窗口（保持向后兼容）
  Future<void> setupWindow(UiMode uiMode) async {
    await configureWindow(uiMode, enableLogging: false, applyDelay: false);
  }

  /// UI模式应用窗口设置（保持向后兼容）
  Future<void> applyUISettings(
    UiMode uiMode, {
    required BuildContext context,
    UserPreferences? userPreferences,
  }) async {
    await configureWindow(
      uiMode,
      context: context,
      userPreferences: userPreferences,
    );
  }

  /// 统一的传统模式窗口配置
  Future<void> _configureTraditionalWindow({
    bool enableLogging = true,
    bool applyDelay = true,
  }) async {
    const traditionalWidth = ClipConstants.minWindowWidth;
    const traditionalHeight = ClipConstants.minWindowHeight;

    if (enableLogging) {
      await Log.i(
        '配置传统模式窗口: ${traditionalWidth}x$traditionalHeight',
        tag: 'WindowManagementService',
      );
    }

    // 使用统一的约束设置方法
    await _setWindowConstraints(
      width: traditionalWidth,
      height: traditionalHeight,
      enableLogging: enableLogging,
    );

    await windowManager.setTitle(ClipConstants.appName);

    // 应用延迟和居中（修复约束竞争条件）
    if (applyDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await center();
  }

  /// 统一的应用切换器模式窗口配置
  Future<void> _configureAppSwitcherMode(
    BuildContext? context, {
    bool enableLogging = true,
    bool applyDelay = true,
    UserPreferences? userPreferences,
  }) async {
    // 获取屏幕尺寸和用户偏好宽度
    final screenInfo = await getMainScreenInfo();

    // 使用用户自定义宽度或默认计算宽度
    final appSwitcherWidth =
        userPreferences?.appSwitcherWindowWidth ??
        screenInfo.screenWidth * ClipConstants.appSwitcherWidthRatio;

    const appSwitcherHeight = ClipConstants.appSwitcherWindowHeight;

    if (enableLogging) {
      await Log.i(
        '配置应用切换器窗口: ${appSwitcherWidth.toStringAsFixed(0)}x${appSwitcherHeight.toStringAsFixed(0)}',
        tag: 'WindowManagementService',
      );
    }

    // 使用统一的约束设置方法
    await _setWindowConstraints(
      width: appSwitcherWidth,
      height: appSwitcherHeight,
      enableLogging: enableLogging,
    );

    await windowManager.setTitle('应用切换器 - ${ClipConstants.appName}');

    // 应用延迟和居中（修复约束竞争条件）
    if (applyDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await center();
  }

  // ========== 集成的 ScreenService 静态方法 ==========

  /// 获取物理屏幕尺寸信息
  static Future<ScreenInfoResponse> getPhysicalScreenSize() async {
    try {
      final result = await _screenChannel.invokeMethod('getPhysicalScreenSize');
      if (result == null) {
        throw Exception('Failed to get screen size information');
      }

      // 安全的类型转换
      final resultMap = result is Map
          ? Map<String, dynamic>.from(result.cast<String, dynamic>())
          : throw Exception('Expected Map but got ${result.runtimeType}');
      return ScreenInfoResponse.fromMap(resultMap);
    } on PlatformException catch (e) {
      throw Exception('Failed to get screen size: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting screen size: $e');
    }
  }

  /// 获取主屏幕信息
  static Future<ScreenInfo> getMainScreenInfo() async {
    final response = await getPhysicalScreenSize();
    return response.mainDisplay;
  }

  /// 获取所有屏幕信息
  static Future<List<ScreenInfo>> getAllScreenInfo() async {
    final response = await getPhysicalScreenSize();
    return response.allDisplays;
  }

  /// 获取屏幕数量
  static Future<int> getDisplayCount() async {
    final response = await getPhysicalScreenSize();
    return response.displayCount;
  }

  /// 获取主屏幕物理分辨率
  static Future<AppSize> getMainScreenPhysicalResolution() async {
    final screenInfo = await getMainScreenInfo();
    return AppSize(screenInfo.physicalWidth, screenInfo.physicalHeight);
  }

  /// 获取主屏幕逻辑分辨率
  static Future<AppSize> getMainScreenLogicalResolution() async {
    final screenInfo = await getMainScreenInfo();
    return AppSize(screenInfo.screenWidth, screenInfo.screenHeight);
  }

  /// 获取主屏幕缩放因子
  static Future<double> getMainScreenScaleFactor() async {
    final screenInfo = await getMainScreenInfo();
    return screenInfo.scaleFactor;
  }

  /// 获取主屏幕物理尺寸（毫米）
  static Future<AppSize> getMainScreenPhysicalSizeMM() async {
    final screenInfo = await getMainScreenInfo();
    return AppSize(screenInfo.physicalWidthMM, screenInfo.physicalHeightMM);
  }

  /// 获取主屏幕对角线尺寸（毫米）
  static Future<double> getMainScreenDiagonalMM() async {
    final screenInfo = await getMainScreenInfo();
    return screenInfo.diagonalMM;
  }

  /// 检查是否为多显示器配置
  static Future<bool> isMultiDisplay() async {
    final count = await getDisplayCount();
    return count > 1;
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      // 正确移除存储的监听器引用
      if (_eventListener != null) {
        windowManager.removeListener(_eventListener!);
        _eventListener = null;
      }
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

/// 窗口事件监听器
///
/// 处理窗口关闭、最小化等事件，并根据用户设置决定是否最小化到托盘
class AppWindowListener with WindowListener {
  AppWindowListener(this._trayService, {this.onSaveAppSwitcherWidth});
  final TrayService _trayService;
  final void Function(double)? onSaveAppSwitcherWidth;
  UserPreferences? _userPreferences;

  /// 更新用户偏好设置（仅写入，外部不需要读取以降低耦合）
  set userPreferences(UserPreferences? preferences) {
    _userPreferences = preferences;
  }

  @override
  Future<void> onWindowClose() async {
    await Log.i('onWindowClose triggered');
    final shouldMinimizeToTray =
        _userPreferences?.minimizeToTray ?? _trayService.shouldMinimizeToTray;

    await Log.i('onWindowClose shouldMinimizeToTray=$shouldMinimizeToTray');

    if (shouldMinimizeToTray) {
      // 路径：用户选择最小化到托盘。保持 preventClose=true，避免杀进程。
      try {
        await _trayService.hideWindow();
        await Log.i('Window minimized to tray on close');
      } on Exception catch (e, stackTrace) {
        await Log.e(
          'Failed to minimize to tray on close: $e',
          error: e,
          stackTrace: stackTrace,
        );
        // 失败时不销毁应用，避免误杀。尝试直接隐藏窗口作为兜底。
        try {
          await windowManager.hide();
        } on Exception catch (e) {
          // 忽略隐藏失败的异常，避免中断关闭事件处理流程
          await Log.e('Fallback hide failed: $e', error: e);
        }
      }
      return;
    }

    // 路径：用户未开启最小化到托盘，执行正常退出
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
      await Log.i('Application closed normally');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Error handling window close (exit path): $e',
        error: e,
        stackTrace: stackTrace,
      );
      // 出错时保证应用退出
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    }
  }

  @override
  Future<void> onWindowMinimize() async {
    try {
      await Log.i('onWindowMinimize triggered');
      // 优先使用最新的用户偏好；若为空则回退到 TrayService 的设置（其默认值为 true）
      final shouldMinimizeToTray =
          _userPreferences?.minimizeToTray ?? _trayService.shouldMinimizeToTray;

      await Log.i(
        'onWindowMinimize shouldMinimizeToTray='
        '$shouldMinimizeToTray',
      );

      if (shouldMinimizeToTray) {
        // 最小化到托盘而不是任务栏
        await _trayService.hideWindow();
        await Log.i('Window minimized to tray');
      }
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Error handling window minimize: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> onWindowFocus() async {
    await Log.i('Window focused');
  }

  @override
  Future<void> onWindowBlur() async {
    await Log.i('Window blurred');
  }

  @override
  Future<void> onWindowResize() async {
    await Log.d('Window resize event received');

    // 只在 AppSwitcher 模式下保存窗口宽度
    if (_userPreferences?.uiMode == UiMode.appSwitcher) {
      try {
        final size = await windowManager.getSize();
        final width = size.width;

        await Log.d('Saving AppSwitcher window width: $width');

        // 使用回调保存窗口宽度
        onSaveAppSwitcherWidth?.call(width);
      } on Exception catch (e, stackTrace) {
        await Log.e(
          'Failed to save window width',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}

// ========== 必需的类定义 ==========

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

// ========== ScreenService 集成的类和方法 ==========

/// 屏幕信息数据类
class ScreenInfo {
  const ScreenInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.visibleWidth,
    required this.visibleHeight,
    required this.scaleFactor,
    required this.physicalWidth,
    required this.physicalHeight,
    required this.physicalWidthMM,
    required this.physicalHeightMM,
    required this.diagonalMM,
    required this.colorSpace,
    required this.isMain,
  });

  factory ScreenInfo.fromMap(Map<String, dynamic> map) {
    try {
      return ScreenInfo(
        screenWidth: _toDouble(map['screenWidth']),
        screenHeight: _toDouble(map['screenHeight']),
        visibleWidth: _toDouble(map['visibleWidth']),
        visibleHeight: _toDouble(map['visibleHeight']),
        scaleFactor: _toDouble(map['scaleFactor']),
        physicalWidth: _toDouble(map['physicalWidth']),
        physicalHeight: _toDouble(map['physicalHeight']),
        physicalWidthMM: _toDouble(map['physicalWidthMM']),
        physicalHeightMM: _toDouble(map['physicalHeightMM']),
        diagonalMM: _toDouble(map['diagonalMM']),
        colorSpace: map['colorSpace']?.toString() ?? 'unknown',
        isMain: map['isMain'] as bool? ?? false,
      );
    } catch (e) {
      Log.e('📏 [ScreenInfo.fromMap] 解析失败: $e', tag: 'WindowManagementService');
      Log.e('📏 [ScreenInfo.fromMap] 数据: $map', tag: 'WindowManagementService');
      rethrow;
    }
  }
  final double screenWidth;
  final double screenHeight;
  final double visibleWidth;
  final double visibleHeight;
  final double scaleFactor;
  final double physicalWidth;
  final double physicalHeight;
  final double physicalWidthMM;
  final double physicalHeightMM;
  final double diagonalMM;
  final String colorSpace;
  final bool isMain;

  /// 安全的双精度转换
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'visibleWidth': visibleWidth,
      'visibleHeight': visibleHeight,
      'scaleFactor': scaleFactor,
      'physicalWidth': physicalWidth,
      'physicalHeight': physicalHeight,
      'physicalWidthMM': physicalWidthMM,
      'physicalHeightMM': physicalHeightMM,
      'diagonalMM': diagonalMM,
      'colorSpace': colorSpace,
      'isMain': isMain,
    };
  }

  @override
  String toString() {
    return 'ScreenInfo('
        'screenSize: ${screenWidth}x$screenHeight, '
        'visibleSize: ${visibleWidth}x$visibleHeight, '
        'scaleFactor: $scaleFactor, '
        'physicalSize: ${physicalWidthMM}x${physicalHeightMM}mm, '
        'diagonal: ${diagonalMM.toStringAsFixed(1)}mm, '
        'isMain: $isMain)';
  }
}

/// 所有屏幕信息数据类
class ScreenInfoResponse {
  const ScreenInfoResponse({
    required this.mainDisplay,
    required this.allDisplays,
    required this.displayCount,
  });

  factory ScreenInfoResponse.fromMap(Map<String, dynamic> map) {
    try {
      Log.d(
        '📏 [ScreenInfoResponse.fromMap] 开始解析数据',
        tag: 'WindowManagementService',
      );
      Log.d(
        '📏 [ScreenInfoResponse.fromMap] mainDisplay 类型: ${map['mainDisplay']?.runtimeType}',
        tag: 'WindowManagementService',
      );

      final mainDisplayData = map['mainDisplay'];
      if (mainDisplayData == null) {
        throw Exception('mainDisplay data is null');
      }

      final mainDisplay = ScreenInfo.fromMap(
        Map<String, dynamic>.from(mainDisplayData as Map),
      );
      Log.d(
        '📏 [ScreenInfoResponse.fromMap] 主屏幕解析成功: ${mainDisplay.physicalWidth}x${mainDisplay.physicalHeight}',
        tag: 'WindowManagementService',
      );

      final allDisplaysData = map['allDisplays'] as List? ?? [];
      final allDisplays = allDisplaysData
          .map(
            (display) =>
                ScreenInfo.fromMap(Map<String, dynamic>.from(display as Map)),
          )
          .toList();

      final displayCount = map['displayCount'] as int? ?? allDisplays.length;

      Log.d(
        '📏 [ScreenInfoResponse.fromMap] 解析完成，显示器数量: $displayCount',
        tag: 'WindowManagementService',
      );

      return ScreenInfoResponse(
        mainDisplay: mainDisplay,
        allDisplays: allDisplays,
        displayCount: displayCount,
      );
    } catch (e) {
      Log.e(
        '📏 [ScreenInfoResponse.fromMap] 解析失败: $e',
        tag: 'WindowManagementService',
      );
      rethrow;
    }
  }
  final ScreenInfo mainDisplay;
  final List<ScreenInfo> allDisplays;
  final int displayCount;

  @override
  String toString() {
    return 'ScreenInfoResponse('
        'displayCount: $displayCount, '
        'mainDisplay: $mainDisplay, '
        'allDisplays: $allDisplays)';
  }
}

/// 尺寸类
class AppSize {
  const AppSize(this.width, this.height);
  final double width;
  final double height;

  @override
  String toString() =>
      '${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}';

  double get diagonal => math.sqrt(width * width + height * height);
}
