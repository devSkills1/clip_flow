// ignore_for_file: public_member_api_docs, no_default_cases
// Public member documentation is handled inline for clarity.
// Switch statements use exhaustive patterns without default cases.
import 'dart:async';
import 'dart:io';

import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/debug/clipboard_debug_page.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/enhanced_search_bar.dart'
    as search;
import 'package:clip_flow_pro/features/home/presentation/widgets/responsive_home_layout.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 增强版首页 - 解决所有布局溢出和性能问题
class EnhancedHomePage extends ConsumerStatefulWidget {
  /// 创建增强版首页
  const EnhancedHomePage({super.key});

  @override
  ConsumerState<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends ConsumerState<EnhancedHomePage>
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
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    try {
      // 从数据库加载历史记录
      final recentItems = await DatabaseService.instance.getAllClipItems(
        limit: 100,
      );
      if (recentItems.isEmpty) return;

      final notifier = ref.read(clipboardHistoryProvider.notifier);

      for (final dbItem in recentItems) {
        ClipItem? validItem;

        switch (dbItem.type) {
          case ClipType.text:
          case ClipType.html:
          case ClipType.rtf:
          case ClipType.color:
          case ClipType.url:
          case ClipType.email:
          case ClipType.json:
          case ClipType.xml:
          case ClipType.code:
            validItem = dbItem;

          case ClipType.image:
          case ClipType.file:
          case ClipType.audio:
          case ClipType.video:
            var filePath = dbItem.filePath ?? dbItem.content;

            if (dbItem.type == ClipType.image &&
                (filePath == null || filePath.isEmpty)) {
              filePath = await _findImageFileForItem(dbItem);
            }

            if (filePath != null && await _isFileValid(filePath)) {
              validItem = dbItem;
            } else {
              await DatabaseService.instance.deleteClipItem(dbItem.id);
            }
        }

        if (validItem != null) {
          notifier.addItem(validItem);
        }
      }
    } on Exception catch (e) {
      // 静默失败，避免阻塞UI
      unawaited(Log.e('Error loading initial data: $e'));
    }
  }

  Future<bool> _isFileValid(String filePath) async {
    if (filePath.isEmpty) return false;
    return PathService.instance.fileExists(filePath);
  }

  Future<String?> _findImageFileForItem(ClipItem dbItem) async {
    try {
      final documentsDir = await PathService.instance.getDocumentsDirectory();
      final mediaImagesDir = Directory('${documentsDir.path}/media/images');

      if (!mediaImagesDir.existsSync()) return null;

      final targetTime = dbItem.createdAt;
      final targetIdPrefix = dbItem.id.substring(0, 8);

      final files = await mediaImagesDir.list().toList();

      for (final file in files) {
        if (file is! File) continue;

        final fileName = file.path.split('/').last;

        if (fileName.contains(targetIdPrefix) ||
            fileName.contains(targetTime.millisecondsSinceEpoch.toString())) {
          return file.path;
        }
      }

      return null;
    } on Exception catch (e) {
      await Log.e('Error finding image file for item: $e');
      return null;
    }
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
            // 侧边栏
            _buildSidebar(),

            // 主内容区域
            Expanded(
              child: Column(
                children: [
                  // 顶部搜索栏
                  _buildSearchBar(),

                  // 快速筛选
                  _buildQuickFilters(filterOption, displayMode),

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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 应用标题
          _buildAppHeader(),

          // 筛选选项
          Expanded(
            child: _buildFilterSidebar(),
          ),

          // 底部操作
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo或图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.content_paste,
              size: 24,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 16),

          // 应用名称
          Text(
            'ClipFlow Pro',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          // 副标题
          Text(
            '智能剪贴板管理器',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    final filterOption = ref.watch(filterTypeProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildFilterSectionTitle('类型筛选'),
        _buildTypeFilterOptions(filterOption),

        const SizedBox(height: 24),

        _buildFilterSectionTitle('显示模式'),
        _buildDisplayModeOptions(),
      ],
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
        ),
      ),
    );
  }

  Widget _buildTypeFilterOptions(FilterOption currentFilter) {
    final typeOptions = [
      search.FilterOption.all,
      search.FilterOption.text,
      search.FilterOption.richTextUnion,
      search.FilterOption.image,
      search.FilterOption.file,
      search.FilterOption.color,
    ];

    return Column(
      children: typeOptions.map((option) {
        final isSelected = _getFilterOptionValue(option.value) == currentFilter;
        return _buildFilterTile(option, isSelected);
      }).toList(),
    );
  }

  Widget _buildFilterTile(search.FilterOption option, bool isSelected) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        option.icon,
        size: 20,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        option.label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.1,
      ),
      onTap: () {
        final filterValue = _getFilterOptionValue(option.value);
        ref.read(filterTypeProvider.notifier).state = filterValue;
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  search.FilterOption _getClassFilterOption(FilterOption enumOption) {
    switch (enumOption) {
      case FilterOption.all:
        return search.FilterOption.all;
      case FilterOption.text:
        return search.FilterOption.text;
      case FilterOption.richTextUnion:
        return search.FilterOption.richTextUnion;
      case FilterOption.rtf:
        return search.FilterOption.rtf;
      case FilterOption.html:
        return search.FilterOption.html;
      case FilterOption.code:
        return search.FilterOption.code;
      case FilterOption.image:
        return search.FilterOption.image;
      case FilterOption.color:
        return search.FilterOption.color;
      case FilterOption.file:
        return search.FilterOption.file;
      case FilterOption.audio:
        return search.FilterOption.audio;
      case FilterOption.video:
        return search.FilterOption.video;
    }
  }

  FilterOption _getFilterOptionValue(String value) {
    switch (value) {
      case 'all':
        return FilterOption.all;
      case 'text':
        return FilterOption.text;
      case 'rich':
        return FilterOption.richTextUnion;
      case 'image':
        return FilterOption.image;
      case 'file':
        return FilterOption.file;
      case 'color':
        return FilterOption.color;
      case 'recent':
      case 'favorites':
      case 'images':
        return FilterOption.all; // 这些特殊筛选项暂时归类为全部
      default:
        return FilterOption.all;
    }
  }

  Widget _buildDisplayModeOptions() {
    final displayMode = ref.watch(displayModeProvider);

    return Row(
      children: [
        Expanded(
          child: _buildModeTile(
            '紧凑',
            Icons.view_list,
            DisplayMode.compact,
            displayMode == DisplayMode.compact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildModeTile(
            '网格',
            Icons.grid_view,
            DisplayMode.normal,
            displayMode == DisplayMode.normal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildModeTile(
            '预览',
            Icons.view_module,
            DisplayMode.preview,
            displayMode == DisplayMode.preview,
          ),
        ),
      ],
    );
  }

  Widget _buildModeTile(
    String label,
    IconData icon,
    DisplayMode mode,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        ref.read(displayModeProvider.notifier).state = mode;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    if (!kReleaseMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ClipboardDebugPage(),
              ),
            );
          },
          icon: const Icon(Icons.bug_report_outlined),
          label: const Text('调试'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: search.EnhancedSearchBar(
        controller: _searchController,
        hintText: '搜索剪贴板内容...',
        onChanged: (query) {
          ref.read(searchQueryProvider.notifier).state = query;
        },
        onClear: () {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).state = '';
        },
        onSubmitted: (query) {
          // 可以添加搜索提交逻辑
        },
        suggestions: _getSearchSuggestions(),
        onSuggestionSelected: (suggestion) {
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

  Widget _buildQuickFilters(
    FilterOption filterOption,
    DisplayMode displayMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: search.QuickFilterChips(
              filters: _getQuickFilterOptions(),
              selectedFilter: _getClassFilterOption(filterOption),
              onFilterSelected: (filter) {
                ref.read(filterTypeProvider.notifier).state =
                    _getFilterOptionValue(filter.value);
              },
            ),
          ),
          const SizedBox(width: 16),
          search.DisplayModeToggle(
            displayMode: displayMode,
            onModeChanged: (mode) {
              ref.read(displayModeProvider.notifier).state = mode;
            },
          ),
        ],
      ),
    );
  }

  List<search.FilterOption> _getQuickFilterOptions() {
    return [
      search.FilterOption.all,
      search.FilterOption.recent,
      search.FilterOption.favorites,
      search.FilterOption.images,
      search.FilterOption.text,
    ];
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
          onPressed: () {
            // 显示使用提示
          },
          icon: const Icon(Icons.help_outline),
          label: const Text('使用指南'),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(S? l10n) {
    return EnhancedEmptyState(
      title: '未找到匹配内容',
      subtitle: '尝试使用其他关键词或调整筛选条件',
      icon: Icons.search_off,
      actions: [
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).state = '';
          },
          icon: const Icon(Icons.clear),
          label: const Text('清除搜索'),
        ),
      ],
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

    return items.where((item) {
      switch (filterOption) {
        case FilterOption.text:
          return item.type == ClipType.text;
        case FilterOption.richTextUnion:
          return item.type == ClipType.rtf ||
              item.type == ClipType.html ||
              item.type == ClipType.code;
        case FilterOption.rtf:
          return item.type == ClipType.rtf;
        case FilterOption.html:
          return item.type == ClipType.html;
        case FilterOption.code:
          return item.type == ClipType.code;
        case FilterOption.image:
          return item.type == ClipType.image;
        case FilterOption.color:
          return item.type == ClipType.color;
        case FilterOption.file:
          return item.type == ClipType.file;
        case FilterOption.audio:
          return item.type == ClipType.audio;
        case FilterOption.video:
          return item.type == ClipType.video;
        default:
          return true;
      }
    }).toList();
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
    // 复制到剪贴板
    ref.read(clipboardServiceProvider).setClipboardContent(item);

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.of(context)?.snackCopiedPrefix(_getItemPreview(item)) ??
              I18nFallbacks.common.snackCopiedPrefix(_getItemPreview(item)),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _onDeleteItem(ClipItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogDeleteTitle ?? I18nFallbacks.common.deleteTitle,
        ),
        content: Text(
          S.of(context)?.dialogDeleteContent(_getItemPreview(item)) ??
              '${I18nFallbacks.common.deleteContentPrefix}'
                  '${_getItemPreview(item)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)?.actionCancel ?? I18nFallbacks.common.actionCancel,
            ),
          ),
          FilledButton(
            onPressed: () {
              // 先移除内存
              ref.read(clipboardHistoryProvider.notifier).removeItem(item.id);
              // 再尝试删除数据库记录
              try {
                ref.read(clipRepositoryProvider).delete(item.id);
              } on Exception {
                // 忽略删除异常
              }
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(
              S.of(context)?.actionDelete ?? I18nFallbacks.common.actionDelete,
            ),
          ),
        ],
      ),
    );
  }

  String _getItemPreview(ClipItem item) {
    switch (item.type) {
      case ClipType.image:
        final width = item.originWidth ?? (item.metadata['width'] as int? ?? 0);
        final height =
            item.originHeight ?? (item.metadata['height'] as int? ?? 0);
        final format = item.metadata['format'] as String?;
        return '${I18nFallbacks.common.labelImage} '
            '($width x $height, ${format ?? I18nFallbacks.common.unknown})';
      case ClipType.file:
        final fileName =
            item.metadata['fileName'] as String? ??
            I18nFallbacks.common.unknown;
        return '${I18nFallbacks.common.labelFile}: $fileName';
      case ClipType.color:
        final colorHex = item.metadata['colorHex'] as String? ?? '#000000';
        return '${I18nFallbacks.common.labelColor}: $colorHex';
      default:
        final content = item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }
}
