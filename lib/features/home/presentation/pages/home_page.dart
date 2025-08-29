import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../shared/providers/app_providers.dart';
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
    // 监听剪贴板流
    ref.listen(clipboardStreamProvider, (previous, next) {
      next.whenData((clipItem) {
        ref.read(clipboardHistoryProvider.notifier).addItem(clipItem);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clipboardHistory = ref.watch(clipboardHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterType = ref.watch(filterTypeProvider);
    final displayMode = ref.watch(displayModeProvider);

    // 过滤和搜索
    List<ClipItem> filteredItems = clipboardHistory;
    
    if (filterType != null) {
      filteredItems = filteredItems.where((item) => item.type == filterType).toList();
    }
    
    if (searchQuery.isNotEmpty) {
      filteredItems = ref.read(clipboardHistoryProvider.notifier).search(searchQuery);
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
                      : _buildClipboardList(filteredItems, displayMode),
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

  Widget _buildClipboardList(List<ClipItem> items, DisplayMode displayMode) {
    switch (displayMode) {
      case DisplayMode.compact:
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ClipItemCard(
              item: items[index],
              displayMode: DisplayMode.compact,
              onTap: () => _onItemTap(items[index]),
              onFavorite: () => _onFavoriteToggle(items[index]),
              onDelete: () => _onDeleteItem(items[index]),
            );
          },
        );
        
      case DisplayMode.normal:
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ClipItemCard(
              item: items[index],
              displayMode: DisplayMode.normal,
              onTap: () => _onItemTap(items[index]),
              onFavorite: () => _onFavoriteToggle(items[index]),
              onDelete: () => _onDeleteItem(items[index]),
            );
          },
        );
        
      case DisplayMode.preview:
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ClipItemCard(
              item: items[index],
              displayMode: DisplayMode.preview,
              onTap: () => _onItemTap(items[index]),
              onFavorite: () => _onFavoriteToggle(items[index]),
              onDelete: () => _onDeleteItem(items[index]),
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
          TextButton(
            onPressed: () {
              ref.read(clipboardHistoryProvider.notifier).removeItem(item.id);
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _getItemPreview(ClipItem item) {
    final content = String.fromCharCodes(item.content);
    if (content.length > 50) {
      return '${content.substring(0, 50)}...';
    }
    return content;
  }
}
