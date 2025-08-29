import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/clip_item.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

// 主题模式提供者
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// 路由提供者
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

// 剪贴板历史提供者
final clipboardHistoryProvider = StateNotifierProvider<ClipboardHistoryNotifier, List<ClipItem>>((ref) {
  return ClipboardHistoryNotifier();
});

class ClipboardHistoryNotifier extends StateNotifier<List<ClipItem>> {
  ClipboardHistoryNotifier() : super([]);

  void addItem(ClipItem item) {
    // 避免重复添加相同内容
    final existingIndex = state.indexWhere((existing) => 
        String.fromCharCodes(existing.content) == String.fromCharCodes(item.content));
    
    if (existingIndex != -1) {
      // 更新现有项目的时间戳
      final updatedItem = state[existingIndex].copyWith(updatedAt: DateTime.now());
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

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void toggleFavorite(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
  }

  void clearHistory() {
    state = [];
  }

  List<ClipItem> getFavorites() {
    return state.where((item) => item.isFavorite).toList();
  }

  List<ClipItem> getByType(ClipType type) {
    return state.where((item) => item.type == type).toList();
  }

  List<ClipItem> search(String query) {
    if (query.isEmpty) return state;
    
    final lowercaseQuery = query.toLowerCase();
    return state.where((item) {
      final content = String.fromCharCodes(item.content).toLowerCase();
      final tags = (item.metadata['tags'] as List<dynamic>?)
          ?.map((tag) => tag.toString().toLowerCase())
          .join(' ') ?? '';
      
      return content.contains(lowercaseQuery) || tags.contains(lowercaseQuery);
    }).toList();
  }
}

// 搜索查询提供者
final searchQueryProvider = StateProvider<String>((ref) => '');

// 筛选类型提供者
final filterTypeProvider = StateProvider<ClipType?>((ref) => null);

// 显示模式提供者 (紧凑/默认/预览)
enum DisplayMode { compact, normal, preview }

final displayModeProvider = StateProvider<DisplayMode>((ref) => DisplayMode.normal);

// 用户偏好设置提供者
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});

class UserPreferences {
  final bool autoStart;
  final bool minimizeToTray;
  final String globalHotkey;
  final int maxHistoryItems;
  final bool enableEncryption;
  final bool enableOCR;
  final String language;
  final DisplayMode defaultDisplayMode;

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

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      autoStart: json['autoStart'] ?? false,
      minimizeToTray: json['minimizeToTray'] ?? true,
      globalHotkey: json['globalHotkey'] ?? 'Cmd+Shift+V',
      maxHistoryItems: json['maxHistoryItems'] ?? 500,
      enableEncryption: json['enableEncryption'] ?? true,
      enableOCR: json['enableOCR'] ?? true,
      language: json['language'] ?? 'zh_CN',
      defaultDisplayMode: DisplayMode.values.firstWhere(
        (e) => e.name == json['defaultDisplayMode'],
        orElse: () => DisplayMode.normal,
      ),
    );
  }
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(UserPreferences());

  void updatePreferences(UserPreferences preferences) {
    state = preferences;
  }

  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }

  void toggleMinimizeToTray() {
    state = state.copyWith(minimizeToTray: !state.minimizeToTray);
  }

  void setGlobalHotkey(String hotkey) {
    state = state.copyWith(globalHotkey: hotkey);
  }

  void setMaxHistoryItems(int maxItems) {
    state = state.copyWith(maxHistoryItems: maxItems);
  }

  void toggleEncryption() {
    state = state.copyWith(enableEncryption: !state.enableEncryption);
  }

  void toggleOCR() {
    state = state.copyWith(enableOCR: !state.enableOCR);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void setDefaultDisplayMode(DisplayMode mode) {
    state = state.copyWith(defaultDisplayMode: mode);
  }
}
