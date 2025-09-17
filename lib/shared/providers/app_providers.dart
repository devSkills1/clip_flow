import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/features/home/presentation/pages/home_page.dart';
import 'package:clip_flow_pro/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 主题模式提供者
/// App theme mode provider (system/light/dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// 路由提供者
/// Global router provider with the app route table.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

// 剪贴板历史提供者
/// Clipboard history state provider backed by [ClipboardHistoryNotifier].
final clipboardHistoryProvider =
    StateNotifierProvider<ClipboardHistoryNotifier, List<ClipItem>>((ref) {
      return ClipboardHistoryNotifier();
    });

/// Manages clipboard items: add/remove/favorite/search with size capping.
class ClipboardHistoryNotifier extends StateNotifier<List<ClipItem>> {
  ClipboardHistoryNotifier() : super([]);

  /// Adds a new item or updates timestamp if duplicated by content.
  void addItem(ClipItem item) {
    // 避免重复添加相同内容
    final existingIndex = state.indexWhere(
      (existing) =>
          String.fromCharCodes(existing.content) ==
          String.fromCharCodes(item.content),
    );

    if (existingIndex != -1) {
      // 更新现有项目的时间戳
      final updatedItem = state[existingIndex].copyWith(
        updatedAt: DateTime.now(),
      );
      state = [
        updatedItem,
        ...state
            .asMap()
            .entries
            .where((e) => e.key != existingIndex)
            .map((e) => e.value),
      ];
    } else {
      // 添加新项目到列表开头
      state = [item, ...state];

      // 限制历史记录数量
      if (state.length > 500) {
        state = state.take(500).toList();
      }
    }
  }

  /// Removes item by [id].
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Toggles favorite flag by [id].
  void toggleFavorite(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
  }

  /// Clears all history items.
  void clearHistory() {
    state = [];
  }

  /// Returns items marked as favorite.
  List<ClipItem> getFavorites() {
    return state.where((item) => item.isFavorite).toList();
  }

  /// Filters items by [type].
  List<ClipItem> getByType(ClipType type) {
    return state.where((item) => item.type == type).toList();
  }

  /// Full-text search by content and tags.
  List<ClipItem> search(String query) {
    if (query.isEmpty) return state;

    final lowercaseQuery = query.toLowerCase();
    return state.where((item) {
      final content = String.fromCharCodes(item.content).toLowerCase();
      final tags =
          (item.metadata['tags'] as List?)
              ?.map((tag) => tag.toString().toLowerCase())
              .join(' ') ??
          '';

      return content.contains(lowercaseQuery) || tags.contains(lowercaseQuery);
    }).toList();
  }
}

// 搜索查询提供者
/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

// 筛选类型提供者
/// Current filter type.
final filterTypeProvider = StateProvider<ClipType?>((ref) => null);

// 显示模式提供者 (紧凑/默认/预览)
/// Display density modes for UI lists/grids.
enum DisplayMode { compact, normal, preview }

/// Current display mode state.
final displayModeProvider = StateProvider<DisplayMode>(
  (ref) => DisplayMode.normal,
);

// 用户偏好设置提供者
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier();
    });

/// Immutable user preferences model with JSON (de)serialization helpers.
class UserPreferences {
  UserPreferences({
    this.autoStart = false,
    this.minimizeToTray = true,
    this.globalHotkey = 'Cmd+Shift+V',
    this.maxHistoryItems = 500,
    this.enableEncryption = true,
    this.enableOCR = true,
    this.language = 'zh_CN',
    this.defaultDisplayMode = DisplayMode.normal,
  });

  /// Creates [UserPreferences] from JSON map.
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      autoStart: (json['autoStart'] as bool?) ?? false,
      minimizeToTray: (json['minimizeToTray'] as bool?) ?? true,
      globalHotkey: (json['globalHotkey'] as String?) ?? 'Cmd+Shift+V',
      maxHistoryItems: (json['maxHistoryItems'] as int?) ?? 500,
      enableEncryption: (json['enableEncryption'] as bool?) ?? true,
      enableOCR: (json['enableOCR'] as bool?) ?? true,
      language: (json['language'] as String?) ?? 'zh_CN',
      defaultDisplayMode: DisplayMode.values.firstWhere(
        (e) => e.name == (json['defaultDisplayMode'] as String?),
        orElse: () => DisplayMode.normal,
      ),
    );
  }
  final bool autoStart;
  final bool minimizeToTray;
  final String globalHotkey;
  final int maxHistoryItems;
  final bool enableEncryption;
  final bool enableOCR;
  final String language;
  final DisplayMode defaultDisplayMode;

  /// Returns a new instance with selected fields overridden.
  UserPreferences copyWith({
    bool? autoStart,
    bool? minimizeToTray,
    String? globalHotkey,
    int? maxHistoryItems,
    bool? enableEncryption,
    bool? enableOCR,
    String? language,
    DisplayMode? defaultDisplayMode,
  }) {
    return UserPreferences(
      autoStart: autoStart ?? this.autoStart,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      globalHotkey: globalHotkey ?? this.globalHotkey,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      enableOCR: enableOCR ?? this.enableOCR,
      language: language ?? this.language,
      defaultDisplayMode: defaultDisplayMode ?? this.defaultDisplayMode,
    );
  }

  /// Serializes preferences to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'minimizeToTray': minimizeToTray,
      'globalHotkey': globalHotkey,
      'maxHistoryItems': maxHistoryItems,
      'enableEncryption': enableEncryption,
      'enableOCR': enableOCR,
      'language': language,
      'defaultDisplayMode': defaultDisplayMode.name,
    };
  }
}

/// Manages and updates [UserPreferences] state.
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(UserPreferences());

  /// Replaces current preferences with [preferences].
  void updatePreferences(UserPreferences preferences) {
    state = preferences;
  }

  /// Toggles auto start preference.
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }

  /// Toggles minimize-to-tray preference.
  void toggleMinimizeToTray() {
    state = state.copyWith(minimizeToTray: !state.minimizeToTray);
  }

  /// Sets the global shortcut hotkey.
  void setGlobalHotkey(String hotkey) {
    state = state.copyWith(globalHotkey: hotkey);
  }

  /// Sets the maximum number of history items to retain.
  void setMaxHistoryItems(int maxItems) {
    state = state.copyWith(maxHistoryItems: maxItems);
  }

  /// Toggles encryption feature.
  void toggleEncryption() {
    state = state.copyWith(enableEncryption: !state.enableEncryption);
  }

  /// Toggles OCR feature.
  void toggleOCR() {
    state = state.copyWith(enableOCR: !state.enableOCR);
  }

  /// Sets display language code (e.g. 'zh_CN').
  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  /// Sets default display mode.
  void setDefaultDisplayMode(DisplayMode mode) {
    state = state.copyWith(defaultDisplayMode: mode);
  }
}
