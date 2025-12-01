import 'dart:async';
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/theme_tokens.dart';
import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:clip_flow_pro/shared/widgets/performance_overlay.dart'
    as custom;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// The root application widget of ClipFlow Pro.
/// Provides router configuration and light/dark themes.
class ClipFlowProApp extends ConsumerStatefulWidget {
  /// Creates the root application widget.
  const ClipFlowProApp({super.key});

  @override
  ConsumerState<ClipFlowProApp> createState() => _ClipFlowProAppState();
}

class _ClipFlowProAppState extends ConsumerState<ClipFlowProApp> {
  @override
  void initState() {
    super.initState();
    // 初始注册窗口监听器，确保 preventClose 生效时能正确处理关闭事件
    final initialListener = ref.read(windowListenerProvider);
    windowManager.addListener(initialListener);
    // 窗口监听器内部（Provider）已监听用户偏好变化，这里不再使用 ref.listen，避免运行时限制

    // 注册toggleWindow快捷键回调
    _registerToggleWindowCallback();
  }

  /// 注册toggleWindow快捷键回调
  void _registerToggleWindowCallback() {
    ref.read(hotkeyServiceProvider).registerActionCallback(
      HotkeyAction.toggleWindow,
      () {
        unawaited(
          ref
              .read(trayServiceProvider)
              .when(
                data: (trayService) => trayService.toggleWindow(),
                loading: () {
                  // TrayService还在初始化中，忽略此次快捷键
                  unawaited(Log.i('TrayService is initializing', tag: 'tray'));
                },
                error: (error, stackTrace) {
                  // 记录错误但不阻塞用户操作
                  unawaited(
                    Log.e(
                      'TrayService error',
                      tag: 'tray',
                      error: error,
                      stackTrace: stackTrace,
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  @override
  void dispose() {
    // 组件销毁时移除监听器
    try {
      final currentListener = ref.read(windowListenerProvider);
      windowManager.removeListener(currentListener);
    } on Exception catch (_) {}
    super.dispose();
  }

  @override
  /// Builds the root MaterialApp with routing, theming, and localization.
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final userPreferences = ref.watch(userPreferencesProvider);

    // 初始化托盘服务（异步）
    // 保持窗口监听器 Provider 存活，以便其内部监听用户偏好变化并更新监听器实例
    ref
      ..watch(trayServiceProvider)
      ..watch(windowListenerProvider);
    // 窗口监听器的注册在 initState 中完成，避免在 build 中重复注册

    // 根据用户偏好设置确定locale
    Locale locale;
    switch (userPreferences.language) {
      case 'en_US':
        locale = const Locale('en');
      case 'zh_CN':
      default:
        locale = const Locale('zh');
    }

    return MaterialApp.router(
      title: ClipConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // 性能监控覆盖层（启用时显示，支持 release）
            if (userPreferences.showPerformanceOverlay)
              const custom.PerformanceOverlay(),
          ],
        );
      },
    );
  }
}

// Cached theme instances to avoid rebuilding ThemeData on each widget rebuild.
/// Material 3 light theme used across the app.
final ThemeData _lightTheme = (() {
  final colorScheme = ColorScheme.fromSeed(seedColor: ThemeTokens.seedColor);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: ThemeTokens.primaryFontFamily,

    // AppBar主题
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    // Card主题
    cardTheme: CardThemeData(
      elevation: 1,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
      ),
    ),

    // FilledButton主题
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // OutlinedButton主题
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // TextButton主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // InputDecoration主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.s16,
        vertical: Spacing.s12,
      ),
    ),

    // NavigationBar主题
    navigationBarTheme: NavigationBarThemeData(
      elevation: 1,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    // Divider主题
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),
  );
})();

/// Material 3 dark theme used across the app.
final ThemeData _darkTheme = (() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: ThemeTokens.seedColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: ThemeTokens.primaryFontFamily,

    // AppBar主题
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    // Card主题
    cardTheme: CardThemeData(
      elevation: 1,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
      ),
    ),

    // FilledButton主题
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // OutlinedButton主题
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // TextButton主题
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        ),
      ),
    ),

    // InputDecoration主题
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.s16,
        vertical: Spacing.s12,
      ),
    ),

    // NavigationBar主题
    navigationBarTheme: NavigationBarThemeData(
      elevation: 1,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),

    // Divider主题
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),
  );
})();
