import 'package:clip_flow/app.dart';
import 'package:clip_flow/core/constants/colors.dart';
import 'package:clip_flow/core/services/clipboard/index.dart';
import 'package:clip_flow/core/services/observability/index.dart';
import 'package:clip_flow/core/services/operations/index.dart';
import 'package:clip_flow/core/services/platform/index.dart';
import 'package:clip_flow/core/services/storage/index.dart';
import 'package:clip_flow/shared/providers/app_providers.dart';
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
    if (modeString == 'compact') {
      resolvedUiMode = UiMode.compact;
    } else if (modeString == 'classic') {
      resolvedUiMode = UiMode.classic;
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
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: false,
    windowButtonVisibility: false,
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
  
  // 执行数据库文件路径修复（方案3：混合修复）
  // 在应用启动时执行一次，修复无效的file_path并清理无效记录
  try {
    final repairReport = await DatabaseService.instance.repairFilePaths();
    await Log.i(
      'Database file path repair completed',
      tag: 'Main',
      fields: repairReport,
    );
  } on Exception catch (e) {
    // 修复失败不影响应用启动
    await Log.w(
      'Database file path repair failed, continuing app startup',
      tag: 'Main',
      error: e,
    );
  }
  
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
      child: const ClipFlowApp(),
    ),
  );
}
