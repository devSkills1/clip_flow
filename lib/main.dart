import 'package:clip_flow_pro/app.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/services/clipboard/index.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/operations/index.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  await _runApp();
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局错误处理器
  ErrorHandler.initialize();

  // 初始化快捷键服务 - 需要在窗口设置之前获取UI模式
  final preferencesService = PreferencesService();
  await preferencesService.initialize();
  // 预加载用户偏好，避免首屏 UI 模式闪动
  final loadedPreferences = await preferencesService.loadPreferences();

  // 可选：从平台侧读取启动时希望的 UI 模式（例如通过快捷键唤起 AppSwitcher）
  var resolvedUiMode = loadedPreferences.uiMode;
  try {
    final modeString = await const MethodChannel(
      'clipboard_service',
    ).invokeMethod<String>('getLaunchUiMode');
    if (modeString == 'appSwitcher') {
      resolvedUiMode = UiMode.appSwitcher;
    } else if (modeString == 'traditional') {
      resolvedUiMode = UiMode.traditional;
    }
  } on Exception {
    // 忽略平台调用失败，保持本地偏好
  }

  final initialPreferences = loadedPreferences.copyWith(uiMode: resolvedUiMode);
  final hotkeyService = HotkeyService(preferencesService);
  await hotkeyService.initialize();

  // 设置全局快捷键服务实例
  setHotkeyServiceInstance(hotkeyService);

  // 初始化窗口管理服务
  final windowService = WindowManagementService.instance;
  await windowService.initialize();

  // 使用 WindowManagementService 设置窗口
  await windowService.setupWindow(resolvedUiMode);
  const windowOptions = WindowOptions(
    center: true,
    backgroundColor: Color(AppColors.white),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: false,
    windowButtonVisibility: true,
  );

  /// 主函数
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 使用窗口管理服务显示窗口
    await windowService.showAndFocus();
  });

  // 初始化日志系统
  await Log.init(
    LoggerConfig(
      enableFile: true,
    ),
  );

  // 初始化服务
  await DatabaseService.instance.initialize();
  await EncryptionService.instance.initialize();

  // 使用剪贴板管理器替代基础剪贴板服务
  final clipboardManager = ClipboardManager();
  await clipboardManager.initialize();
  clipboardManager.startMonitoring();

  // 为了兼容性，仍然初始化基础服务（但不再启动监控）
  await ClipboardService.instance.initialize();

  // 初始化自动更新服务
  try {
    await UpdateService().initialize();
    // 安排后台检查更新
    UpdateService().scheduleBackgroundCheck();
  } on Exception catch (e, stackTrace) {
    await Log.e(
      'Failed to initialize UpdateService: $e',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        // 使用预加载的偏好覆盖默认 Provider，避免加载中的 UI 闪动
        userPreferencesProvider.overrideWith(
          (ref) => UserPreferencesNotifier.withInitial(initialPreferences),
        ),
      ],
      child: const ClipFlowProApp(),
    ),
  );
}
