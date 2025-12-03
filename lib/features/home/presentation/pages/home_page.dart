// Public member documentation is handled inline for clarity.
// Switch statements use exhaustive patterns without default cases.
import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/platform/system/window_listener.dart';
import 'package:clip_flow_pro/core/utils/clip_item_card_util.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/basic_sidebar.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/responsive_home_layout.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/search_bar.dart'
    show EnhancedSearchBar;
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:clip_flow_pro/shared/widgets/window_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 增强版首页 - 解决所有布局溢出和性能问题
class HomePage extends ConsumerStatefulWidget {
  /// 创建增强版首页
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String? _lastSearchQuery;
  Set<ClipType> _selectedTypes = <ClipType>{};
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupWindow();

    // 在页面初始化时检查并启动自动隐藏监控
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final autoHideEnabled = ref.read(userPreferencesProvider).autoHideEnabled;
      if (autoHideEnabled) {
        ref.read(autoHideServiceProvider).startMonitoring();
        unawaited(
          Log.i(
            'HomePage initialized, auto-hide monitoring started',
            tag: 'HomePage',
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  /// 设置传统模式窗口
  Future<void> _setupWindow() async {
    // 等待一帧以确保context已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // 使用WindowManagementService统一处理窗口设置
        await WindowManagementService.instance.applyUISettings(
          UiMode.traditional,
          context: context,
        );
      }
    });
  }

  /// 处理用户交互，重置自动隐藏定时器
  void _onUserInteraction() {
    ref.read(autoHideServiceProvider).onUserInteraction();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final clipboardHistory = ref.watch(clipboardHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterOption = ref.watch(filterTypeProvider);
    final displayMode = ref.watch(displayModeProvider);

    // 监听剪贴板流
    ref.listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
      next.whenData((clipItem) async {
        await Log.d(
          'UI received clipboard item: ${clipItem.type} - ID: ${clipItem.id}',
          tag: 'HomePage',
        );
        if (clipItem.type == ClipType.image) {
          await Log.d(
            'Image item details - hasContent: ${clipItem.content != null}, hasFilePath: ${clipItem.filePath != null}',
            tag: 'HomePage',
          );
        }
        ref.read(clipboardHistoryProvider.notifier).addItem(clipItem);
      });
    });

    // 搜索查询变化时更新筛选
    if (searchQuery != _lastSearchQuery) {
      _lastSearchQuery = searchQuery;
      _updateAdvancedFilters();
    }

    final filteredItems = _applyFilters(
      clipboardHistory,
      filterOption,
      searchQuery,
    );

    // 包装在 MouseRegion 和 Listener 中以捕获用户交互
    return MouseRegion(
      onHover: (_) => _onUserInteraction(),
      child: Listener(
        onPointerDown: (_) => _onUserInteraction(),
        onPointerMove: (_) => _onUserInteraction(),
        onPointerSignal: (_) => _onUserInteraction(), // 捕获滚动事件
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              children: [
                // 基础侧边栏 - 简单稳定
                const BasicSidebar(),

                // 主内容区域
                Expanded(
                  child: Column(
                    children: [
                      // 自定义窗口头部
                      _buildWindowHeader(l10n),

                      // 主内容区域
                      Expanded(
                        child: _buildContentArea(
                          searchQuery,
                          filteredItems,
                          displayMode,
                          l10n,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ), // 关闭 Scaffold
      ), // 关闭 Listener
    ); // 关闭 MouseRegion
  }

  Widget _buildWindowHeader(S l10n) {
    return ModernWindowHeader(
      title: l10n.appName,
      subtitle: l10n.homeTitle,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actions: [
        _buildModeSwitchAction(l10n),
      ],
      compact: true,
      showTitle: false,
      showLeading: false,
      center: _buildSearchField(l10n),
    );
  }

  Widget _buildModeSwitchAction(S l10n) {
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.space_dashboard_rounded, size: 18),
      label: Text(l10n.headerActionOpenAppSwitcher),
      onPressed: () async {
        await _switchToAppSwitcher();
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }

  Future<void> _switchToAppSwitcher() async {
    ref.read(userPreferencesProvider.notifier).setUiMode(UiMode.appSwitcher);
    if (!mounted) {
      return;
    }
    await WindowManagementService.instance.applyUISettings(
      UiMode.appSwitcher,
      context: context,
      userPreferences: ref.read(userPreferencesProvider),
    );
  }

  Widget _buildSearchField(S l10n) {
    return EnhancedSearchBar(
      controller: _searchController,
      hintText: l10n.searchHint,
      onChanged: (String query) {
        ref.read(searchQueryProvider.notifier).state = query;
      },
      onClear: () {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      },
      onSubmitted: (String query) {},
      dense: true,
    );
  }

  Widget _buildContentArea(
    String searchQuery,
    List<ClipItem> filteredItems,
    DisplayMode displayMode,
    S l10n,
  ) {
    // 如果有搜索查询，使用搜索结果
    if (searchQuery.isNotEmpty) {
      final searchResult = ref.watch(databaseSearchProvider(searchQuery));
      return searchResult.when(
        data: (items) {
          final filterOption = ref.watch(filterTypeProvider);
          final filtered = _filterItemsByType(items, filterOption);

          return ResponsiveHomeLayout(
            items: filtered,
            displayMode: displayMode,
            searchQuery: searchQuery,
            onItemTap: _onItemTap,
            onItemDelete: _onDeleteItem,
            onItemFavoriteToggle: _onItemFavoriteToggle,
            onOcrTextTap: _onOcrTextTap,
            enableOcrCopy: ref.watch(userPreferencesProvider).enableOCR,
            emptyWidget: _buildEmptySearchState(l10n),
            scrollController: _scrollController,
          );
        },
        loading: () => const LoadingState(),
        error: (error, stackTrace) => ErrorState(
          message: '搜索时出错：$error',
          onRetry: () {
            // 重试搜索
          },
        ),
      );
    }

    // 正常显示
    return ResponsiveHomeLayout(
      items: filteredItems,
      displayMode: displayMode,
      searchQuery: searchQuery,
      onItemTap: _onItemTap,
      onItemDelete: _onDeleteItem,
      onItemFavoriteToggle: _onItemFavoriteToggle,
      onOcrTextTap: _onOcrTextTap,
      enableOcrCopy: ref.watch(userPreferencesProvider).enableOCR,
      emptyWidget: _buildEmptyState(l10n),
      scrollController: _scrollController,
    );
  }

  Widget _buildEmptyState(S l10n) {
    return EnhancedEmptyState(
      title: l10n.homeEmptyTitle,
      subtitle: l10n.homeEmptySubtitle,
      icon: Icons.content_paste_outlined,
      actions: [
        TextButton.icon(
          onPressed: _showUserGuide,
          icon: const Icon(Icons.help_outline),
          label: const Text('使用指南'),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(S l10n) {
    return EnhancedEmptyState(
      title: l10n.searchEmptyTitle,
      subtitle: l10n.searchEmptySubtitle,
      icon: Icons.search_off,
    );
  }

  List<ClipItem> _applyFilters(
    List<ClipItem> items,
    FilterOption filterOption,
    String searchQuery,
  ) {
    var filtered = _filterItemsByType(items, filterOption);

    // 应用高级筛选
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered
          .where((item) => _selectedTypes.contains(item.type))
          .toList();
    }

    if (_dateRange != null) {
      filtered = filtered.where((item) {
        return item.createdAt.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            item.createdAt.isBefore(
              _dateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return filtered;
  }

  List<ClipItem> _filterItemsByType(
    List<ClipItem> items,
    FilterOption filterOption,
  ) {
    if (filterOption == FilterOption.all) return items;

    // 预定义过滤条件映射，提高性能和可维护性
    final filterMap = {
      FilterOption.text: (ClipItem item) =>
          item.type != ClipType.image &&
          item.type != ClipType.file &&
          item.type != ClipType.color,
      FilterOption.richTextUnion: (ClipItem item) => const {
        ClipType.rtf,
        ClipType.html,
        ClipType.code,
      }.contains(item.type),
      FilterOption.rtf: (ClipItem item) => item.type == ClipType.rtf,
      FilterOption.html: (ClipItem item) => item.type == ClipType.html,
      FilterOption.code: (ClipItem item) => item.type == ClipType.code,
      FilterOption.image: (ClipItem item) => item.type == ClipType.image,
      FilterOption.color: (ClipItem item) => item.type == ClipType.color,
      FilterOption.file: (ClipItem item) => item.type == ClipType.file,
      FilterOption.audio: (ClipItem item) => item.type == ClipType.audio,
      FilterOption.video: (ClipItem item) => item.type == ClipType.video,
    };

    final predicate = filterMap[filterOption] ?? (item) => true;
    return items.where(predicate).toList();
  }

  void _updateAdvancedFilters() {
    // 可以根据搜索内容自动调整高级筛选
    if (_searchController.text.toLowerCase().contains('image') ||
        _searchController.text.toLowerCase().contains('图片')) {
      _selectedTypes = {ClipType.image};
    } else {
      _selectedTypes = <ClipType>{};
    }
  }

  void _onItemTap(ClipItem item) {
    ClipItemUtil.handleItemTap(item, ref, context: context);
  }

  void _onDeleteItem(ClipItem item) {
    ClipItemUtil.handleItemDelete(item, ref, context: context);
  }

  Future<void> _onItemFavoriteToggle(ClipItem item) async {
    await ClipItemUtil.handleFavoriteToggle(item, ref, context: context);
  }

  /// 处理OCR文本点击复制
  Future<void> _onOcrTextTap(ClipItem item) async {
    await ClipItemUtil.handleOcrTextTap(item, ref, context: context);
  }

  void _showUserGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用指南'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideSection(
                '基本使用',
                [
                  '1. 复制任何内容（文字、图片、文件等）',
                  '2. 内容将自动保存到剪贴板历史',
                  '3. 在这里查看和管理所有复制的内容',
                ],
              ),
              const SizedBox(height: 16),
              _buildGuideSection(
                '搜索和筛选',
                [
                  '• 使用搜索框快速查找内容',
                  '• 使用筛选器按类型查看',
                  '• 使用快捷键快速访问',
                ],
              ),
              const SizedBox(height: 16),
              _buildGuideSection(
                '高级功能',
                [
                  '• 收藏重要内容防止被清理',
                  '• 收藏项目删除需要二次确认',
                  '• 导出剪贴板历史',
                  '• 在设置中自定义行为',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
