// Public member documentation is handled inline for clarity.
// Switch statements use exhaustive patterns without default cases.
import 'dart:async';

import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
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

    return Scaffold(
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
                  // 顶部搜索栏
                  _buildSearchBar(),

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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: EnhancedSearchBar(
        controller: _searchController,
        hintText: '搜索剪贴板内容...',
        onChanged: (String query) {
          ref.read(searchQueryProvider.notifier).state = query;
        },
        onClear: () {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).state = '';
        },
        onSubmitted: (String query) {
          // 可以添加搜索提交逻辑
        },
        suggestions: _getSearchSuggestions(),
        onSuggestionSelected: (String suggestion) {
          _searchController.text = suggestion;
          ref.read(searchQueryProvider.notifier).state = suggestion;
        },
      ),
    );
  }

  List<String> _getSearchSuggestions() {
    // 从历史记录中获取搜索建议
    final history = ref.read(clipboardHistoryProvider);
    final suggestions = <String>[];

    for (final item in history.take(10)) {
      if (item.content != null && item.content!.length < 50) {
        suggestions.add(item.content!);
      }
    }

    return suggestions.toSet().toList();
  }

  Widget _buildContentArea(
    String searchQuery,
    List<ClipItem> filteredItems,
    DisplayMode displayMode,
    S? l10n,
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

  Widget _buildEmptyState(S? l10n) {
    return EnhancedEmptyState(
      title: l10n?.homeEmptyTitle ?? I18nFallbacks.home.emptyTitle,
      subtitle: l10n?.homeEmptySubtitle ?? I18nFallbacks.home.emptySubtitle,
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

  Widget _buildEmptySearchState(S? l10n) {
    return const EnhancedEmptyState(
      title: '未找到匹配内容',
      subtitle: '尝试使用其他关键词或调整筛选条件',
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
