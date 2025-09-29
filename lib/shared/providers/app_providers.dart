// ignore_for_file: public_member_api_docs - 内部依赖注入配置文件，不需要对外暴露API文档
// 该文件包含应用级别的Provider定义，主要用于内部状态管理，不作为公共API使用
import 'dart:async';

import 'package:clip_flow_pro/core/constants/routes.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:clip_flow_pro/core/services/database_service.dart';
import 'package:clip_flow_pro/core/services/hotkey_service.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/preferences_service.dart';
import 'package:clip_flow_pro/features/home/data/repositories/clip_repository_impl.dart';
import 'package:clip_flow_pro/features/home/domain/repositories/clip_repository.dart';
import 'package:clip_flow_pro/features/home/presentation/pages/home_page.dart';
import 'package:clip_flow_pro/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

//// 主题模式提供者
/// 应用主题模式（系统/浅色/深色）的状态提供者。
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

//// 路由提供者
/// 全局路由器提供者，定义应用路由表与初始路由。
final clipRepositoryProvider = Provider<ClipRepository>((ref) {
  return ClipRepositoryImpl(DatabaseService.instance);
});
//// 路由提供者
/// 全局路由器提供者，定义应用路由表与初始路由。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

//// 剪贴板历史提供者
/// 基于 [ClipboardHistoryNotifier] 的剪贴板历史状态提供者。
final clipboardHistoryProvider =
    StateNotifierProvider<ClipboardHistoryNotifier, List<ClipItem>>((ref) {
      return ClipboardHistoryNotifier(DatabaseService.instance);
    });

//// 剪贴板历史通知器
/// 管理剪贴项：新增/删除/收藏/搜索，并限制列表大小。
class ClipboardHistoryNotifier extends StateNotifier<List<ClipItem>> {
  /// 使用空列表初始化历史记录。
  ClipboardHistoryNotifier(this._databaseService) : super([]);

  final DatabaseService _databaseService;

  /// 添加新项目；若内容重复则仅更新其时间戳并前置。
  void addItem(ClipItem item) {
    // 避免重复添加相同内容
    // 以唯一的 id 作为去重键，避免不同类型/相同文本被误判为重复
    final existingIndex = state.indexWhere(
      (existing) => existing.id == item.id,
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

  /// 按 [id] 移除项目。
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// 按 [id] 切换收藏状态。
  void toggleFavorite(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
  }

  /// 清空所有历史项目。
  Future<void> clearHistory() async {
    try {
      // 清空数据库
      await _databaseService.clearAllClipItems();
      // 清空内存状态
      state = [];
    } on Exception catch (_) {
      // 即使数据库清空失败，也清空内存状态
      state = [];
      // 可以在这里添加错误日志
    }
  }

  /// 获取已收藏的项目列表。
  List<ClipItem> getFavorites() {
    return state.where((item) => item.isFavorite).toList();
  }

  /// 按 [type] 过滤项目。
  List<ClipItem> getByType(ClipType type) {
    return state.where((item) => item.type == type).toList();
  }

  /// 按内容、标签和OCR文本进行全文搜索。
  List<ClipItem> search(String query) {
    if (query.isEmpty) return state;

    final lowercaseQuery = query.toLowerCase();
    return state.where((item) {
      final content = (item.content ?? '').toLowerCase();
      final tags =
          (item.metadata['tags'] as List?)
              ?.map((tag) => tag.toString().toLowerCase())
              .join(' ') ??
          '';

      // 搜索OCR文本
      final ocrText = (item.ocrText ?? '').toLowerCase();

      return content.contains(lowercaseQuery) ||
          tags.contains(lowercaseQuery) ||
          ocrText.contains(lowercaseQuery);
    }).toList();
  }
}

//// 搜索查询提供者
/// 当前搜索关键字的状态提供者。
final searchQueryProvider = StateProvider<String>((ref) => '');

//// 数据库搜索结果提供者
/// 基于搜索查询从数据库获取搜索结果的异步提供者。
// ignore: specify_nonobvious_property_types - 类型已通过泛型参数明确指定
final databaseSearchProvider = FutureProvider.family<List<ClipItem>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];

    try {
      final databaseService = DatabaseService.instance;
      return await databaseService.searchClipItems(query, limit: 100);
    } on Exception catch (e) {
      // 记录搜索失败的错误并返回空列表
      await Log.w(
        'Database search failed',
        fields: {'query': query, 'error': e.toString()},
        tag: 'DatabaseSearchProvider',
      );
      return [];
    }
  },
);

//// 筛选选项定义（包含联合筛选：富文本=RTF+HTML+Code）
/// UI 的筛选项（而非底层 ClipType），用于表示“全部/文本/富文本(联合)/RTF/HTML/代码/图片/颜色/文件/音频/视频”。
enum FilterOption {
  all,
  text,
  richTextUnion, // RTF + HTML + Code
  rtf,
  html,
  code,
  image,
  color,
  file,
  audio,
  video,
}

//// 筛选类型提供者（UI 层）
/// 当前剪贴类型筛选的状态提供者（使用 FilterOption 支持联合筛选）。
final filterTypeProvider = StateProvider<FilterOption>(
  (ref) => FilterOption.all,
);

//// 显示模式（紧凑/默认/预览）
/// UI 列表/网格的显示密度枚举。
enum DisplayMode { compact, normal, preview }

//// 显示模式提供者
/// 当前 UI 显示模式（紧凑/默认/预览）的状态提供者。
final displayModeProvider = StateProvider<DisplayMode>(
  (ref) => DisplayMode.normal,
);

//// 用户偏好设置提供者
/// 提供用户偏好状态与更新方法的通知器提供者。
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier();
    });

//// 用户偏好数据模型
/// 不可变的用户偏好设置，并提供 JSON 序列化/反序列化。
class UserPreferences {
  /// 构造函数：提供默认值。
  UserPreferences({
    this.autoStart = false,
    this.minimizeToTray = true,
    this.globalHotkey = 'Cmd+Shift+V',
    this.maxHistoryItems = 500,
    this.enableEncryption = true,
    this.enableOCR = true,
    this.language = 'zh_CN',
    this.defaultDisplayMode = DisplayMode.normal,
    this.isDeveloperMode = false,
    this.showPerformanceOverlay = false,
  });

  /// 从 JSON Map 创建 [UserPreferences] 实例。
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
      isDeveloperMode: (json['isDeveloperMode'] as bool?) ?? false,
      showPerformanceOverlay:
          (json['showPerformanceOverlay'] as bool?) ?? false,
    );
  }

  /// 是否开机自启动
  final bool autoStart;

  /// 关闭窗口是否最小化到托盘
  final bool minimizeToTray;

  /// 全局快捷键
  final String globalHotkey;

  /// 历史记录最大保留条数
  final int maxHistoryItems;

  /// 是否启用加密
  final bool enableEncryption;

  /// 是否启用 OCR
  final bool enableOCR;

  /// 显示语言代码（如 'zh_CN'）
  final String language;

  /// 默认显示模式
  final DisplayMode defaultDisplayMode;

  /// 是否启用开发者模式
  final bool isDeveloperMode;

  /// 是否显示性能监控覆盖层
  final bool showPerformanceOverlay;

  /// 返回复制的新实例，并按需覆盖指定字段。
  UserPreferences copyWith({
    bool? autoStart,
    bool? minimizeToTray,
    String? globalHotkey,
    int? maxHistoryItems,
    bool? enableEncryption,
    bool? enableOCR,
    String? language,
    DisplayMode? defaultDisplayMode,
    bool? isDeveloperMode,
    bool? showPerformanceOverlay,
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
      isDeveloperMode: isDeveloperMode ?? this.isDeveloperMode,
      showPerformanceOverlay:
          showPerformanceOverlay ?? this.showPerformanceOverlay,
    );
  }

  /// 序列化为 JSON Map。
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
      'isDeveloperMode': isDeveloperMode,
      'showPerformanceOverlay': showPerformanceOverlay,
    };
  }
}

//// 用户偏好通知器
/// 管理并更新 [UserPreferences] 状态。
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  /// 使用默认偏好初始化。
  UserPreferencesNotifier() : super(UserPreferences()) {
    _loadPreferences();
  }

  /// 偏好设置持久化服务
  final PreferencesService _preferencesService = PreferencesService();

  /// 当前偏好读取器。
  UserPreferences get preferences => state;

  /// 用 [preferences] 替换当前偏好。
  set preferences(UserPreferences preferences) {
    state = preferences;
    _savePreferences();
  }

  /// 加载保存的偏好设置
  Future<void> _loadPreferences() async {
    try {
      final loadedPreferences = await _preferencesService.loadPreferences();
      state = loadedPreferences;
    } on Exception catch (e) {
      // 如果加载失败，保持默认设置
      unawaited(
        Log.e('Failed to load user preferences', tag: 'providers', error: e),
      );
    }
  }

  /// 保存当前偏好设置
  Future<void> _savePreferences() async {
    try {
      await _preferencesService.savePreferences(state);
    } on Exception catch (e) {
      unawaited(
        Log.e('Failed to save user preferences', tag: 'providers', error: e),
      );
    }
  }

  /// 切换"开机自启动"偏好。
  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
    _savePreferences();
  }

  /// 切换"最小化到托盘"偏好。
  void toggleMinimizeToTray() {
    state = state.copyWith(minimizeToTray: !state.minimizeToTray);
    _savePreferences();
  }

  /// 设置全局快捷键。
  void setGlobalHotkey(String hotkey) {
    state = state.copyWith(globalHotkey: hotkey);
    _savePreferences();
  }

  /// 设置历史记录的最大保留条数。
  void setMaxHistoryItems(int maxItems) {
    state = state.copyWith(maxHistoryItems: maxItems);
    _savePreferences();
  }

  /// 切换"启用加密"偏好。
  void toggleEncryption() {
    state = state.copyWith(enableEncryption: !state.enableEncryption);
    _savePreferences();
  }

  /// 切换"启用 OCR"偏好。
  void toggleOCR() {
    state = state.copyWith(enableOCR: !state.enableOCR);
    _savePreferences();
  }

  /// 设置显示语言代码（例如 'zh_CN'）。
  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _savePreferences();
  }

  /// 设置默认显示模式。
  void setDefaultDisplayMode(DisplayMode mode) {
    state = state.copyWith(defaultDisplayMode: mode);
    _savePreferences();
  }

  /// 切换开发者模式。
  void toggleDeveloperMode() {
    state = state.copyWith(isDeveloperMode: !state.isDeveloperMode);
    _savePreferences();
  }

  /// 切换性能监控覆盖层。
  void togglePerformanceOverlay() {
    state = state.copyWith(
      showPerformanceOverlay: !state.showPerformanceOverlay,
    );
    _savePreferences();
  }
}

//// 剪贴板服务提供者
/// 提供全局单例的 ClipboardService，并在首次读取时初始化轮询监听。
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService.instance;
  // 初始化剪贴板监听（幂等）
  unawaited(service.initialize());
  return service;
});

//// 剪贴板流提供者
/// 订阅剪贴板变更事件流（ClipItem）。
final clipboardStreamProvider = StreamProvider<ClipItem>((ref) {
  final service = ref.watch(clipboardServiceProvider);
  return service.clipboardStream;
});

//// 偏好设置服务提供者
/// 提供全局单例的 PreferencesService。
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

//// 快捷键服务提供者
/// 提供全局单例的 HotkeyService，使用已在main.dart中初始化的实例。
final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  // 使用静态实例，避免重复创建和初始化
  return _hotkeyServiceInstance;
});

// 全局快捷键服务实例，在main.dart中初始化
late final HotkeyService _hotkeyServiceInstance;

/// 设置全局快捷键服务实例
void setHotkeyServiceInstance(HotkeyService instance) {
  _hotkeyServiceInstance = instance;
}
