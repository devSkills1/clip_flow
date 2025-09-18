import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:clip_flow_pro/features/home/domain/entities/clip_entity.dart';
import 'package:clip_flow_pro/features/home/domain/usecases/get_recent_clips.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/clip_item_card.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/filter_sidebar.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/search_bar_widget.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // 首次进入页面时加载数据库中的历史记录并填充到状态
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final recent = await ref.read(getRecentClipsProvider).call(limit: 100);
        if (recent.isEmpty) return;
        final notifier = ref.read(clipboardHistoryProvider.notifier);
        for (final e in recent) {
          // 从用例返回的是 String，UI 状态中保持 UTF-8 字节，展示时再 decode
          final item = ClipItem(
            id: e.id,
            type: ClipType.text,
            content: e.content,
            metadata: const {},
            createdAt: e.createdAt,
            updatedAt: e.createdAt,
          );
          notifier.addItem(item);
        }
      } catch (_) {
        // 静默失败，避免阻塞 UI
      }
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
    final l10n = S.of(context);
    // 监听剪贴板流
    ref.listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
      next.whenData((clipItem) async {
        // 1) 内存添加（UI 状态统一存 UTF-8 字节，不做双重转换）
        ref.read(clipboardHistoryProvider.notifier).addItem(clipItem);
        // 2) 持久化保存（仅文本先支持，其它类型后续扩展）
        try {
          final repo = ref.read(clipRepositoryProvider);
          final contentText = clipItem.content ?? '';
          await repo.save(
            ClipEntity(
              id: clipItem.id,
              content: contentText,
              createdAt: clipItem.createdAt,
            ),
          );
        } catch (_) {
          // 忽略存储异常，避免阻塞UI
        }
      });
    });

    final clipboardHistory = ref.watch(clipboardHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterType = ref.watch(filterTypeProvider);
    final displayMode = ref.watch(displayModeProvider);

    // 过滤和搜索
    var filteredItems = clipboardHistory;

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
      backgroundColor: const Color(AppColors.transparent),
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
                      ? _buildEmptyState(l10n)
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

  Widget _buildEmptyState(S? l10n) {
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
            l10n?.homeEmptyTitle ?? I18nFallbacks.home.emptyTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.homeEmptySubtitle ?? I18nFallbacks.home.emptySubtitle,
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
            var crossAxisCount = 2;
            var childAspectRatio = 1.8;

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
            var crossAxisCount = 3;
            var childAspectRatio = 1.5;

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
        content: Text(
          S.of(context)?.snackCopiedPrefix(_getItemPreview(item)) ??
              I18nFallbacks.common.snackCopiedPrefix(_getItemPreview(item)),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onFavoriteToggle(ClipItem item) {
    ref.read(clipboardHistoryProvider.notifier).toggleFavorite(item.id);
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
              '${I18nFallbacks.common.deleteContentPrefix}${_getItemPreview(item)}',
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
                final repo = ref.read(clipRepositoryProvider);
                repo.delete(item.id);
              } catch (_) {}
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
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
        final format = item.metadata['format'] as String?;
        return '${I18nFallbacks.common.labelImage} ($width x $height, ${format ?? I18nFallbacks.common.unknown})';
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
