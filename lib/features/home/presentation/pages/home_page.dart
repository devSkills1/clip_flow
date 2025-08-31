import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/constants/clip_constants.dart';
import '../widgets/clip_item_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_sidebar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听剪贴板流
    ref.listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
      next.whenData((clipItem) {
        ref.read(clipboardHistoryProvider.notifier).addItem(clipItem);
      });
    });

    final clipboardHistory = ref.watch(clipboardHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterType = ref.watch(filterTypeProvider);
    final displayMode = ref.watch(displayModeProvider);

    // 过滤和搜索
    List<ClipItem> filteredItems = clipboardHistory;

    if (filterType != null) {
      filteredItems = filteredItems
          .where((item) => item.type == filterType)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredItems = ref
          .read(clipboardHistoryProvider.notifier)
          .search(searchQuery);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // 左侧筛选栏
          FilterSidebar(
            selectedType: filterType,
            onTypeSelected: (type) {
              ref.read(filterTypeProvider.notifier).state = type;
            },
            onDisplayModeChanged: (mode) {
              ref.read(displayModeProvider.notifier).state = mode;
            },
            displayMode: displayMode,
          ),

          // 主内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部搜索栏
                SearchBarWidget(
                  controller: _searchController,
                  onSearchChanged: (query) {
                    ref.read(searchQueryProvider.notifier).state = query;
                  },
                  onClear: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),

                // 内容区域
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildClipboardList(
                          filteredItems,
                          displayMode,
                          searchQuery,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.content_paste_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无剪贴板历史',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '复制一些内容开始使用吧',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardList(
    List<ClipItem> items,
    DisplayMode displayMode,
    String searchQuery,
  ) {
    switch (displayMode) {
      case DisplayMode.compact:
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(ClipConstants.defaultPadding),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ClipItemCard(
              item: items[index],
              displayMode: DisplayMode.compact,
              searchQuery: searchQuery,
              onTap: () => _onItemTap(items[index]),
              onFavorite: () => _onFavoriteToggle(items[index]),
              onDelete: () => _onDeleteItem(items[index]),
            );
          },
        );

      case DisplayMode.normal:
        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            double childAspectRatio = 1.8;

            // 响应式布局：根据窗口宽度调整列数
            if (constraints.maxWidth > ClipConstants.defaultWindowWidth) {
              crossAxisCount = 3;
              childAspectRatio = 1.6;
            } else if (constraints.maxWidth < ClipConstants.minWindowWidth) {
              crossAxisCount = 1;
              childAspectRatio = 2.5;
            }

            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(ClipConstants.defaultPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: ClipConstants.gridSpacing,
                mainAxisSpacing: ClipConstants.gridSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ClipItemCard(
                  item: items[index],
                  displayMode: DisplayMode.normal,
                  searchQuery: searchQuery,
                  onTap: () => _onItemTap(items[index]),
                  onFavorite: () => _onFavoriteToggle(items[index]),
                  onDelete: () => _onDeleteItem(items[index]),
                );
              },
            );
          },
        );

      case DisplayMode.preview:
        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 3;
            double childAspectRatio = 1.5;

            // 响应式布局：根据窗口宽度调整列数
            if (constraints.maxWidth > 1400) {
              crossAxisCount = 4;
              childAspectRatio = 1.4;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.5;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
              childAspectRatio = 1.6;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 2.0;
            }

            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ClipItemCard(
                  item: items[index],
                  displayMode: DisplayMode.preview,
                  searchQuery: searchQuery,
                  onTap: () => _onItemTap(items[index]),
                  onFavorite: () => _onFavoriteToggle(items[index]),
                  onDelete: () => _onDeleteItem(items[index]),
                );
              },
            );
          },
        );
    }
  }

  void _onItemTap(ClipItem item) {
    // 复制到剪贴板
    ref.read(clipboardServiceProvider).setClipboardContent(item);

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: ${_getItemPreview(item)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onFavoriteToggle(ClipItem item) {
    ref.read(clipboardHistoryProvider.notifier).toggleFavorite(item.id);
  }

  void _onDeleteItem(ClipItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这个剪贴板项目吗？\n${_getItemPreview(item)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(clipboardHistoryProvider.notifier).removeItem(item.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _getItemPreview(ClipItem item) {
    switch (item.type) {
      case ClipType.image:
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
        final format = item.metadata['format'] as String? ?? '未知格式';
        return '图片 ($width x $height, $format)';
      case ClipType.file:
        final fileName = item.metadata['fileName'] as String? ?? '未知文件';
        return '文件: $fileName';
      case ClipType.color:
        final colorHex = item.metadata['colorHex'] as String? ?? '#000000';
        return '颜色: $colorHex';
      default:
        final content = String.fromCharCodes(item.content);
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }
}
