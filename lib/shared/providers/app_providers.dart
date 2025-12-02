// ignore_for_file: public_member_api_docs - 内部依赖注入配置文件，不需要对外暴露API文档
// 该文件包含应用级别的Provider定义，主要用于内部状态管理，不作为公共API使用
import 'dart:async';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/routes.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard/index.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/operations/index.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/features/appswitcher/presentation/pages/app_switcher_page.dart';
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
/// 动态主页组件，根据UI模式切换不同的页面
class DynamicHomePage extends ConsumerWidget {
  const DynamicHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接读取uiModeProvider，确保使用预加载的值避免闪动
    final uiMode = ref.watch(uiModeProvider);

    switch (uiMode) {
      case UiMode.traditional:
        return const HomePage();
      case UiMode.appSwitcher:
        return const AppSwitcherPage();
    }
  }
}

/// 全局路由器提供者，定义应用路由表与初始路由。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DynamicHomePage(),
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
      final preferences = ref.read(userPreferencesProvider);
      final notifier = ClipboardHistoryNotifier(
        DatabaseService.instance,
        maxHistoryItems: preferences.maxHistoryItems,
      );
      // 预加载数据库中的最近记录，避免 AppSwitcher 首屏没有数据
      unawaited(notifier.preloadFromDatabase());

      // 监听用户偏好中的最大历史条数变化
      ref.listen<UserPreferences>(userPreferencesProvider, (previous, next) {
        if (previous?.maxHistoryItems != next.maxHistoryItems) {
          notifier.updateMaxHistoryLimit(next.maxHistoryItems);
        }
      });
      return notifier;
    });

//// 剪贴板历史通知器
/// 管理剪贴项：新增/删除/收藏/搜索，并限制列表大小。
class ClipboardHistoryNotifier extends StateNotifier<List<ClipItem>> {
  /// 使用空列表初始化历史记录。
  ClipboardHistoryNotifier(
    this._databaseService, {
    required int maxHistoryItems,
  })  : _maxHistoryItems = _normalizeLimit(maxHistoryItems),
        super([]);

  final DatabaseService _databaseService;
  int _maxHistoryItems;

  /// 从数据库预加载最近的剪贴项到内存状态（按创建时间倒序）
  Future<void> preloadFromDatabase({int? limit}) async {
    try {
      // 使用传入的 limit 或默认的 _maxHistoryItems
      final effectiveLimit = _normalizeLimit(limit ?? _maxHistoryItems);
      
      // 先清理数据库中超出限制的旧记录
      await _databaseService.cleanupExcessItems(_maxHistoryItems);
      
      // 从数据库获取指定数量的记录
      // 由于数据库查询已经使用了 limit，返回的结果不会超过 effectiveLimit
      final items = await _databaseService.getAllClipItems(limit: effectiveLimit);
      if (items.isNotEmpty) {
        // 直接使用查询结果，无需再次截断
        state = items;
        unawaited(
          Log.d(
            'Preloaded ${items.length} items into clipboard history',
            tag: 'ClipboardHistoryNotifier',
          ),
        );
      }
    } on Exception catch (e) {
      unawaited(
        Log.w(
          'Failed to preload history',
          tag: 'ClipboardHistoryNotifier',
          error: e,
        ),
      );
    }
  }

  /// 添加新项目；若内容重复则仅更新其时间戳并前置。
  void addItem(ClipItem item) {
    // 避免重复添加相同内容
    // 使用内容哈希作为去重键，确保相同内容的不同复制也能被识别
    final existingIndex = state.indexWhere(
      (existing) => existing.id == item.id,
    );

    if (existingIndex != -1) {
      // 更新现有项目并移动到顶部
      final updatedItem = state[existingIndex].copyWith(
        updatedAt: DateTime.now(),
        // 合并新项目的元数据
        metadata: {...state[existingIndex].metadata, ...item.metadata},
      );
      state = [
        updatedItem,
        ...state
            .asMap()
            .entries
            .where((e) => e.key != existingIndex)
            .map((e) => e.value),
      ];

      unawaited(
        Log.d(
          'Moved existing item to top: ${item.id} (${item.type})',
          tag: 'ClipboardHistoryNotifier',
        ),
      );
    } else {
      // 添加新项目到列表开头
      state = [item, ...state];
      unawaited(
        Log.d(
          'Added new item to top: ${item.id} (${item.type})',
          tag: 'ClipboardHistoryNotifier',
        ),
      );
    }

    // 无论是更新还是添加，都需要执行限制检查
    // 防止在频繁更新现有项时内存超出限制
    _enforceHistoryLimit();
  }

  /// 更新最大历史记录条数，并立即应用限制。
  void updateMaxHistoryLimit(int newLimit) {
    final normalized = _normalizeLimit(newLimit);
    if (normalized == _maxHistoryItems) {
      return;
    }
    _maxHistoryItems = normalized;
    _enforceHistoryLimit();
    
    // 同时清理数据库中超出限制的旧记录
    unawaited(
      _databaseService.cleanupExcessItems(normalized).then((_) {
        Log.d(
          'Database cleanup completed after limit update',
          tag: 'ClipboardHistoryNotifier',
          fields: {'newLimit': normalized},
        );
      }).catchError((error) {
        Log.w(
          'Database cleanup failed after limit update',
          tag: 'ClipboardHistoryNotifier',
          error: error,
        );
      }),
    );
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

  /// 批量设置历史项目。
  set items(List<ClipItem> items) {
    state = items;
  }

  /// 获取当前历史项目列表。
  List<ClipItem> get items => state;

  /// 清空所有历史项目（保留收藏的项目）。
  Future<void> clearHistory() async {
    try {
      // 清空数据库（保留收藏的项目）
      await _databaseService.clearAllClipItemsExceptFavorites();

      // 只从内存中移除非收藏的项目
      state = state.where((item) => item.isFavorite).toList();
    } on Exception catch (e) {
      // 即使数据库清空失败，也只保留收藏的项目
      state = state.where((item) => item.isFavorite).toList();
      // 可以在这里添加错误日志
      unawaited(
        Log.e(
          'Failed to clear history (excluding favorites)',
          tag: 'ClipboardHistoryNotifier',
          error: e,
        ),
      );
    }
  }

  /// 清空所有历史项目（包括收藏的项目）。
  Future<void> clearHistoryIncludingFavorites() async {
    try {
      // 清空数据库
      await _databaseService.clearAllClipItems();
      // 清空内存状态
      state = [];
    } on Exception catch (e) {
      // 即使数据库清空失败，也清空内存状态
      state = [];
      // 可以在这里添加错误日志
      unawaited(
        Log.e(
          'Failed to clear history (including favorites)',
          tag: 'ClipboardHistoryNotifier',
          error: e,
        ),
      );
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

  /// 确保历史记录数量不超过限制，优先保留收藏项。
  void _enforceHistoryLimit() {
    if (state.length <= _maxHistoryItems) {
      return;
    }

    final favorites = state.where((item) => item.isFavorite).toList();
    if (favorites.length >= _maxHistoryItems) {
      state = favorites.take(_maxHistoryItems).toList();
      return;
    }

    final remainingSlots = _maxHistoryItems - favorites.length;
    final nonFavorites = state.where((item) => !item.isFavorite).toList();
    final nonFavoriteLimit = remainingSlots > 0 ? remainingSlots : 0;
    final remainingNonFavorites =
        nonFavorites.take(nonFavoriteLimit).toList();

    state = [...favorites, ...remainingNonFavorites];
  }

  static int _normalizeLimit(int limit) {
    return limit <= 0 ? 1 : limit;
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

//// UI 模式（传统剪贴板/应用切换器）
/// UI 界面模式枚举，用于切换不同的UI风格。
enum UiMode { traditional, appSwitcher }

//// 显示模式提供者
/// 当前 UI 显示模式（紧凑/默认/预览）的状态提供者。
final displayModeProvider = StateProvider<DisplayMode>(
  (ref) => DisplayMode.normal,
);

//// UI 模式提供者
/// 当前 UI 界面模式（传统剪贴板/应用切换器）的状态提供者。
/// 从 userPreferencesProvider 中读取状态，确保同步。
final uiModeProvider = Provider<UiMode>(
  (ref) => ref.watch(userPreferencesProvider).uiMode,
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
    this.maxHistoryItems = ClipConstants.maxHistoryItems,
    this.enableEncryption = true,
    this.enableOCR = true,
    this.ocrLanguage = 'auto',
    this.ocrMinConfidence = 0.5,
    this.language = 'zh_CN',
    this.uiMode = UiMode.traditional,
    this.isDeveloperMode = false,
    this.showPerformanceOverlay = false,
    this.autoHideEnabled = true,
    this.appSwitcherWindowWidth,
    this.autoHideTimeoutSeconds = 3,
  });

  /// 从 JSON Map 创建 [UserPreferences] 实例。
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      autoStart: (json['autoStart'] as bool?) ?? false,
      minimizeToTray: (json['minimizeToTray'] as bool?) ?? true,
      globalHotkey: (json['globalHotkey'] as String?) ?? 'Cmd+Shift+V',
      maxHistoryItems: (json['maxHistoryItems'] as int?) ?? ClipConstants.maxHistoryItems,
      enableEncryption: (json['enableEncryption'] as bool?) ?? true,
      enableOCR: (json['enableOCR'] as bool?) ?? true,
      ocrLanguage: (json['ocrLanguage'] as String?) ?? 'auto',
      ocrMinConfidence: ((json['ocrMinConfidence'] as num?) ?? 0.5).toDouble(),
      language: (json['language'] as String?) ?? 'zh_CN',
      uiMode: UiMode.values.firstWhere(
        (e) => e.name == (json['uiMode'] as String?),
        orElse: () => UiMode.traditional,
      ),
      isDeveloperMode: (json['isDeveloperMode'] as bool?) ?? false,
      showPerformanceOverlay:
          (json['showPerformanceOverlay'] as bool?) ?? false,
      autoHideEnabled: (json['autoHideEnabled'] as bool?) ?? true,
      appSwitcherWindowWidth: json['appSwitcherWindowWidth'] as double?,
      autoHideTimeoutSeconds: (json['autoHideTimeoutSeconds'] as int?) ?? 3,
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

  /// OCR 识别语言（包含 'auto' 自动识别）
  final String ocrLanguage;

  /// OCR 最小置信度阈值 (0.0 - 1.0)
  final double ocrMinConfidence;

  /// 显示语言代码（如 'zh_CN'）
  final String language;

  /// UI 界面模式（传统剪贴板/应用切换器）
  final UiMode uiMode;

  /// 是否启用开发者模式
  final bool isDeveloperMode;

  /// 是否显示性能监控覆盖层
  final bool showPerformanceOverlay;

  /// 是否启用自动隐藏
  final bool autoHideEnabled;

  /// AppSwitcher 模式的窗口宽度（null 表示使用默认计算值）
  final double? appSwitcherWindowWidth;

  /// 自动隐藏超时时间（秒）
  final int autoHideTimeoutSeconds;

  /// 返回复制的新实例，并按需覆盖指定字段。
  UserPreferences copyWith({
    bool? autoStart,
    bool? minimizeToTray,
    String? globalHotkey,
    int? maxHistoryItems,
    bool? enableEncryption,
    bool? enableOCR,
    String? ocrLanguage,
    double? ocrMinConfidence,
    String? language,
    UiMode? uiMode,
    bool? isDeveloperMode,
    bool? showPerformanceOverlay,
    bool? autoHideEnabled,
    double? appSwitcherWindowWidth,
    int? autoHideTimeoutSeconds,
  }) {
    return UserPreferences(
      autoStart: autoStart ?? this.autoStart,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      globalHotkey: globalHotkey ?? this.globalHotkey,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      enableOCR: enableOCR ?? this.enableOCR,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      ocrMinConfidence: ocrMinConfidence ?? this.ocrMinConfidence,
      language: language ?? this.language,
      uiMode: uiMode ?? this.uiMode,
      isDeveloperMode: isDeveloperMode ?? this.isDeveloperMode,
      showPerformanceOverlay:
          showPerformanceOverlay ?? this.showPerformanceOverlay,
      autoHideEnabled: autoHideEnabled ?? this.autoHideEnabled,
      appSwitcherWindowWidth:
          appSwitcherWindowWidth ?? this.appSwitcherWindowWidth,
      autoHideTimeoutSeconds:
          autoHideTimeoutSeconds ?? this.autoHideTimeoutSeconds,
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
      'ocrLanguage': ocrLanguage,
      'ocrMinConfidence': ocrMinConfidence,
      'language': language,
      'uiMode': uiMode.name,
      'isDeveloperMode': isDeveloperMode,
      'showPerformanceOverlay': showPerformanceOverlay,
      'autoHideEnabled': autoHideEnabled,
      'appSwitcherWindowWidth': appSwitcherWindowWidth,
      'autoHideTimeoutSeconds': autoHideTimeoutSeconds,
    };
  }
}

//// 用户偏好通知器
/// 管理并更新 [UserPreferences] 状态。
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  /// 使用默认偏好初始化。
  UserPreferencesNotifier() : super(UserPreferences()) {
    unawaited(_loadPreferences());
  }

  /// 使用传入的初始偏好进行初始化。
  /// 此构造函数不会再次触发异步偏好加载，避免冷启动阶段的 UI 模式闪动。
  UserPreferencesNotifier.withInitial(UserPreferences initial)
    : super(initial) {
    // 完全同步初始化，不触发任何异步操作
    // 确保UI模式状态稳定，避免首屏闪动
    unawaited(
      Log.d(
        'UserPreferencesNotifier initialized with UI mode: ${initial.uiMode}',
        tag: 'UserPreferences',
      ),
    );

    // 延迟同步开机自启动状态，避免影响首屏渲染
    unawaited(Future.microtask(_syncAutostartStatus));
  }

  /// 偏好设置持久化服务
  final PreferencesService _preferencesService = PreferencesService();

  /// 当前偏好读取器。
  UserPreferences get preferences => state;

  /// 用 [preferences] 替换当前偏好。
  set preferences(UserPreferences preferences) {
    state = preferences;
    unawaited(_savePreferences());
  }

  /// 加载保存的偏好设置
  Future<void> _loadPreferences() async {
    try {
      final loadedPreferences = await _preferencesService.loadPreferences();
      state = loadedPreferences;

      // 同步开机自启动状态
      await _syncAutostartStatus();
    } on Exception catch (e) {
      // 如果加载失败，保持默认设置
      unawaited(
        Log.e('Failed to load user preferences', tag: 'providers', error: e),
      );
    }
  }

  /// 同步开机自启动状态
  /// 检查系统实际的开机自启动状态，与用户偏好设置保持一致
  Future<void> _syncAutostartStatus() async {
    try {
      final autostartService = AutostartService.instance;
      if (!autostartService.isSupported) {
        return; // 不支持的平台直接返回
      }

      final systemEnabled = await autostartService.isEnabled();
      final preferenceEnabled = state.autoStart;

      if (systemEnabled != preferenceEnabled) {
        // 系统状态与偏好设置不一致，以系统状态为准
        state = state.copyWith(autoStart: systemEnabled);
        await _savePreferences();
        unawaited(
          Log.i(
            '同步开机自启动状态: 系统=${systemEnabled ? "启用" : "禁用"}',
            tag: 'UserPreferences',
          ),
        );
      }
    } on Exception catch (e) {
      unawaited(
        Log.w('同步开机自启动状态失败', tag: 'UserPreferences', error: e),
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
  Future<void> toggleAutoStart() async {
    final newValue = !state.autoStart;

    try {
      final autostartService = AutostartService.instance;

      if (autostartService.isSupported) {
        // 先调用系统服务
        if (newValue) {
          await autostartService.enable();
        } else {
          await autostartService.disable();
        }
        unawaited(
          Log.i(
            '开机自启动${newValue ? "启用" : "禁用"}成功',
            tag: 'UserPreferences',
          ),
        );
      }

      // 更新状态并保存
      state = state.copyWith(autoStart: newValue);
      await _savePreferences();
    } on Exception catch (e) {
      // 如果系统调用失败，不更新状态
      unawaited(
        Log.e(
          '开机自启动${newValue ? "启用" : "禁用"}失败',
          tag: 'UserPreferences',
          error: e,
        ),
      );
      rethrow; // 重新抛出异常，让UI层处理
    }
  }

  /// 切换"最小化到托盘"偏好。
  void toggleMinimizeToTray() {
    state = state.copyWith(minimizeToTray: !state.minimizeToTray);
    unawaited(_savePreferences());

    // 更新托盘服务的用户偏好设置
    TrayService().userPreferences = state;
  }

  /// 设置自动隐藏开关。
  void setAutoHideEnabled(bool enabled) {
    state = state.copyWith(autoHideEnabled: enabled);
    unawaited(_savePreferences());
  }

  /// 设置全局快捷键。
  void setGlobalHotkey(String hotkey) {
    state = state.copyWith(globalHotkey: hotkey);
    unawaited(_savePreferences());
  }

  /// 设置历史记录的最大保留条数。
  void setMaxHistoryItems(int maxItems) {
    state = state.copyWith(maxHistoryItems: maxItems);
    unawaited(_savePreferences());
  }

  /// 切换"启用加密"偏好。
  void toggleEncryption() {
    state = state.copyWith(enableEncryption: !state.enableEncryption);
    unawaited(_savePreferences());
  }

  /// 切换"启用 OCR"偏好。
  void toggleOCR() {
    state = state.copyWith(enableOCR: !state.enableOCR);
    unawaited(_savePreferences());
  }

  /// 设置显示语言代码（例如 'zh_CN'）。
  void setLanguage(String language) {
    state = state.copyWith(language: language);
    unawaited(_savePreferences());
  }

  /// 设置 OCR 识别语言（如 'auto', 'en-US', 'zh-Hans' 等）。
  void setOcrLanguage(String language) {
    state = state.copyWith(ocrLanguage: language);
    unawaited(_savePreferences());
  }

  /// 设置 OCR 最小置信度阈值 (0.0 - 1.0)。
  void setOcrMinConfidence(double value) {
    // 约束到合法区间
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(ocrMinConfidence: clamped);
    unawaited(_savePreferences());
  }

  /// 切换开发者模式。
  void toggleDeveloperMode() {
    state = state.copyWith(isDeveloperMode: !state.isDeveloperMode);
    unawaited(_savePreferences());
  }

  /// 切换性能监控覆盖层。
  void togglePerformanceOverlay() {
    state = state.copyWith(
      showPerformanceOverlay: !state.showPerformanceOverlay,
    );
    unawaited(_savePreferences());
  }

  /// 设置UI界面模式。
  void setUiMode(UiMode mode) {
    state = state.copyWith(uiMode: mode);
    unawaited(_savePreferences());
  }

  /// 保存 AppSwitcher 模式的窗口宽度
  void setAppSwitcherWindowWidth(double? width) {
    state = state.copyWith(appSwitcherWindowWidth: width);
    unawaited(_savePreferences());
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
/// 订阅 ClipboardManager 的 UI 层事件流（ClipItem）。
final clipboardStreamProvider = StreamProvider<ClipItem>((ref) {
  // 使用单例实例，确保与 main.dart 中初始化的是同一个实例
  final manager = ClipboardManager();
  return manager.uiStream;
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

/// 托盘服务提供者
/// 提供全局单例的 TrayService，并监听用户偏好设置变化。
final trayServiceProvider = FutureProvider<TrayService>((ref) async {
  final trayService = TrayService();
  final userPreferences = ref.watch(userPreferencesProvider);

  // 设置托盘交互回调
  trayService.onTrayInteraction = () {
    // ignore: avoid_print
    print('🔍 [AppProviders] onTrayInteraction triggered');
    ref.read(windowActivationSourceProvider.notifier).state =
        WindowActivationSource.tray;
    ref.read(autoHideServiceProvider).stopMonitoring();
  };

  // 设置窗口显示/隐藏回调
  trayService.onWindowShown = () {
    final source = ref.read(windowActivationSourceProvider);
    // ignore: avoid_print
    print('🔍 [AppProviders] onWindowShown triggered. Source: $source');
    final autoHideEnabled = ref.read(userPreferencesProvider).autoHideEnabled;
    if (autoHideEnabled) {
      ref.read(autoHideServiceProvider).startMonitoring();
    } else {
      ref.read(autoHideServiceProvider).stopMonitoring();
    }
  };

  trayService.onWindowHidden = () {
    // ignore: avoid_print
    print('🔍 [AppProviders] onWindowHidden triggered');
    ref.read(autoHideServiceProvider).stopMonitoring();
  };

  // 初始化托盘服务
  await trayService.initialize(userPreferences);

  // 监听用户偏好设置变化
  ref.listen<UserPreferences>(userPreferencesProvider, (previous, next) {
    trayService.userPreferences = next;
  });

  return trayService;
});

/// 窗口激活来源提供者
/// 记录窗口是通过快捷键唤起还是托盘图标唤起
final windowActivationSourceProvider = StateProvider<WindowActivationSource>(
  (ref) => WindowActivationSource.none,
);

/// 自动隐藏服务提供者
final autoHideServiceProvider = Provider<AutoHideService>((ref) {
  final service = AutoHideService(ref);
  final preferences = ref.read(userPreferencesProvider);
  if (preferences.autoHideEnabled) {
    service.startMonitoring();
  }

  ref.listen<UserPreferences>(userPreferencesProvider, (previous, next) {
    final previousValue = previous?.autoHideEnabled ?? false;
    final nextValue = next.autoHideEnabled;
    if (previousValue != nextValue) {
      if (nextValue) {
        service.startMonitoring();
      } else {
        service.stopMonitoring();
      }
      return;
    }

    if (nextValue &&
        previous?.autoHideTimeoutSeconds != next.autoHideTimeoutSeconds) {
      service.startMonitoring();
    }
  });

  return service;
});

/// 窗口监听器提供者
/// 提供全局单例的 AppWindowListener，用于处理窗口事件。
final windowListenerProvider = Provider<AppWindowListener>((ref) {
  final trayService = TrayService();
  final windowListener = AppWindowListener(
    trayService,
    onSaveAppSwitcherWidth: (width) {
      // 保存 AppSwitcher 窗口宽度
      ref
          .read(userPreferencesProvider.notifier)
          .setAppSwitcherWindowWidth(width);
    },
  );

  // 监听用户偏好变化并更新窗口监听器
  ref.listen(userPreferencesProvider, (previous, next) {
    windowListener.userPreferences = next;
  });

  // 初始化用户偏好
  final userPreferences = ref.read(userPreferencesProvider);
  windowListener.userPreferences = userPreferences;

  return windowListener;
});
