// ignore_for_file: public_member_api_docs, no_default_cases
// Public member documentation is handled inline for clarity.
// Switch statements use exhaustive patterns without default cases.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/basic_sidebar.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/enhanced_search_bar.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/responsive_home_layout.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final validItems = <ClipItem>[];

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
          validItems.add(validItem);
        }
      }

      // 一次性设置所有有效项目，保持数据库返回的顺序（最新在前）
      if (validItems.isNotEmpty) {
        notifier.items = validItems;
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
    final isFavorite = item.isFavorite;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isFavorite ? Icons.warning_amber : Icons.delete_outline,
              color: isFavorite
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(isFavorite ? '删除收藏项目？' : '确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFavorite) ...[
              const Text(
                '这是一个收藏的项目！删除后将无法恢复。',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Text('你确定要继续删除吗？'),
            ] else ...[
              const Text('确定要删除这个项目吗？'),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete(item);
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('删除'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
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
        final colorHex = item.content ?? AppColors.defaultColorHex;
        return '${I18nFallbacks.common.labelColor}: $colorHex';
      default:
        final content = item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }

  Future<void> _onItemFavoriteToggle(ClipItem item) async {
    try {
      // 先更新数据库
      await ref
          .read(clipRepositoryProvider)
          .updateFavoriteStatus(
            id: item.id,
            isFavorite: !item.isFavorite,
          );

      // 数据库更新成功后再更新内存
      ref.read(clipboardHistoryProvider.notifier).toggleFavorite(item.id);

      // 静默完成收藏状态切换，不显示 SnackBar 减少打扰
    } on Exception catch (e) {
      // 错误处理 - 不更新内存状态
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('收藏操作失败：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// 处理OCR文本点击复制
  Future<void> _onOcrTextTap(ClipItem item) async {
    // 详细的调试信息
    await Log.d(
      'OCR text tap triggered',
      tag: 'HomePage',
      fields: {
        'itemId': item.id,
        'itemType': item.type.name,
        'hasOcrText': item.ocrText != null,
        'ocrTextLength': item.ocrText?.length ?? 0,
        'ocrTextId': item.ocrTextId,
        'ocrTextPreview':
            item.ocrText?.substring(
              0,
              math.min(50, item.ocrText?.length ?? 0),
            ) ??
            '',
      },
    );

    if (item.type != ClipType.image) {
      await Log.w(
        'OCR tap on non-image item',
        tag: 'HomePage',
        fields: {
          'itemId': item.id,
          'itemType': item.type.name,
        },
      );
      _showOcrErrorMessage('只能对图片类型进行OCR操作');
      return;
    }

    if (item.ocrText == null || item.ocrText!.isEmpty) {
      await Log.w(
        'No OCR text available',
        tag: 'HomePage',
        fields: {
          'itemId': item.id,
          'hasOcrText': item.ocrText != null,
        },
      );
      _showOcrErrorMessage('该图片没有可用的OCR文本');
      return;
    }

    try {
      await Log.d(
        'Copying OCR text to clipboard',
        tag: 'HomePage',
        fields: {
          'itemId': item.id,
          'ocrTextId': item.ocrTextId,
          'textLength': item.ocrText!.length,
        },
      );

      // 直接复制OCR文本到剪贴板
      await Clipboard.setData(ClipboardData(text: item.ocrText!));

      // 更新数据库中对应的OCR文本记录（如果存在ocrTextId）
      if (item.ocrTextId != null) {
        await _updateOcrTextRecord(item);
      }

      await Log.i(
        'OCR text copied successfully',
        tag: 'HomePage',
        fields: {
          'itemId': item.id,
          'ocrTextId': item.ocrTextId,
          'textLength': item.ocrText!.length,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ OCR文本已复制到剪贴板 (${item.ocrText!.length}字符)',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      await Log.e('OCR copy operation failed', tag: 'HomePage', error: e);
      _showOcrErrorMessage('OCR复制错误：$e');
    }
  }

  /// 更新OCR文本记录的时间戳
  Future<void> _updateOcrTextRecord(ClipItem imageItem) async {
    try {
      final database = DatabaseService.instance;

      // 获取OCR文本记录
      final ocrRecord = await database.getClipItemById(imageItem.ocrTextId!);
      if (ocrRecord != null) {
        // 更新OCR文本记录的时间戳
        final updatedOcrRecord = ocrRecord.copyWith(updatedAt: DateTime.now());
        await database.updateClipItem(updatedOcrRecord);

        await Log.d(
          'Updated OCR text record timestamp',
          tag: 'HomePage',
          fields: {
            'ocrTextId': imageItem.ocrTextId,
            'imageId': imageItem.id,
          },
        );
      }
    } on Exception catch (e) {
      await Log.e(
        'Failed to update OCR text record',
        tag: 'HomePage',
        error: e,
      );
      // 不阻止复制操作，只记录错误
    }
  }

  /// 显示OCR错误消息
  void _showOcrErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $message'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

  /// 执行实际的删除操作
  Future<void> _performDelete(ClipItem item) async {
    // 先尝试删除数据库记录
    try {
      await ref.read(clipRepositoryProvider).delete(item.id);

      // 数据库删除成功后，再移除内存
      ref.read(clipboardHistoryProvider.notifier).removeItem(item.id);

      // 静默完成删除，不显示成功提示减少打扰
    } on Exception catch (e) {
      // 删除失败时显示错误，不移除内存状态
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
