import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/theme_tokens.dart';

import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The root application widget of ClipFlow Pro.
/// Provides router configuration and light/dark themes.
class ClipFlowProApp extends ConsumerWidget {
  const ClipFlowProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: ClipConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: router,
      // localizationsDelegates: S.localizationsDelegates,
      // supportedLocales: S.supportedLocales,
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
