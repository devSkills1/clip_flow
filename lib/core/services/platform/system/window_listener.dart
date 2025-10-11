// ignore_for_file: public_member_api_docs, avoid_setters_without_getters
/*
  解释忽略的诊断：
  - public_member_api_docs：该文件属于内部服务实现，不对外暴露公共 API，发布前会在核心公共接口处补全文档。
  - avoid_setters_without_getters：我们刻意仅暴露写入入口（setter）以便 Provider 推送最新用户偏好，
    保持字段只读于类内部，避免对外暴露不必要的读取接口造成耦合。
*/

import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/platform/ui_tray/tray_service.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口事件监听器
///
/// 处理窗口关闭、最小化等事件，并根据用户设置决定是否最小化到托盘
class AppWindowListener with WindowListener {
  AppWindowListener(this._trayService);
  final TrayService _trayService;
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
}
