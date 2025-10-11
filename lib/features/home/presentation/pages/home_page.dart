import 'dart:io';
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/debug/clipboard_debug_page.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/clip_item_card.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/filter_sidebar.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/search_bar_widget.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首页
/// 展示剪贴板历史记录和筛选功能
class HomePage extends ConsumerStatefulWidget {
  /// 首页
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
        // 直接从数据库加载所有类型的历史记录
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
              // 文本类型直接加载
              validItem = dbItem;

            case ClipType.image:
            case ClipType.file:
            case ClipType.audio:
            case ClipType.video:
              // 文件类型需要验证路径有效性
              var filePath = dbItem.filePath ?? dbItem.content;

              // 对于图片类型，如果filePath为空，尝试从沙盒目录查找可能存在的图片文件
              if (dbItem.type == ClipType.image &&
                  (filePath == null || filePath.isEmpty)) {
                filePath = await _findImageFileForItem(dbItem);
              }

              if (filePath != null && await _isFileValid(filePath)) {
                validItem = dbItem;
              } else {
                // 只有在确实找不到文件时才删除记录
                await DatabaseService.instance.deleteClipItem(dbItem.id);
              }
          }

          if (validItem != null) {
            notifier.addItem(validItem);
          }
        }
      } on Exception catch (_) {
        // 静默失败，避免阻塞 UI
      }
    });
  }

  /// 检查文件路径是否有效
  Future<bool> _isFileValid(String filePath) async {
    if (filePath.isEmpty) return false;
    return PathService.instance.fileExists(filePath);
  }

  /// 为图片记录查找可能存在的图片文件
  Future<String?> _findImageFileForItem(ClipItem dbItem) async {
    try {
      // 获取媒体图片目录
      final documentsDir = await PathService.instance.getDocumentsDirectory();
      final mediaImagesDir = Directory('${documentsDir.path}/media/images');

      if (!mediaImagesDir.existsSync()) {
        return null;
      }

      // 根据创建时间和ID查找可能的图片文件
      final targetTime = dbItem.createdAt;
      final targetIdPrefix = dbItem.id.substring(0, 8); // 使用ID前缀匹配

      // 查找图片目录中的文件
      final files = await mediaImagesDir.list().toList();

      for (final file in files) {
        if (file is! File) continue;

        final fileName = file.path.split('/').last;

        // 检查文件名是否包含记录ID或时间戳
        if (fileName.contains(targetIdPrefix) ||
            fileName.contains(targetTime.millisecondsSinceEpoch.toString())) {
          return file.path;
        }
      }

      return null;
    } on Exception catch (_) {
      return null;
    }
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

        // 2) 持久化保存：统一通过 OptimizedClipboardManager 处理，避免重复保存
        // 这里不再直接保存到数据库，而是让 OptimizedClipboardManager 统一处理
        // 防止与 OptimizedClipboardManager 的批量处理机制产生重复
      });
    });

    final clipboardHistory = ref.watch(clipboardHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterOption = ref.watch(filterTypeProvider);
    final displayMode = ref.watch(displayModeProvider);

    // 对于无搜索查询的情况，应用筛选器到内存中的历史记录
    var filteredItems = clipboardHistory;
    if (searchQuery.isEmpty && filterOption != FilterOption.all) {
      filteredItems = filteredItems.where((item) {
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
          case FilterOption.all:
            return true;
        }
      }).toList();
    }

    return Scaffold(
      body: Row(
        children: [
          // 左侧筛选栏
          FilterSidebar(
            selectedOption: filterOption,
            onOptionSelected: (option) {
              ref.read(filterTypeProvider.notifier).state = option;
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
                // 顶部搜索栏和调试按钮
                Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        controller: _searchController,
                        onSearchChanged: (query) {
                          ref.read(searchQueryProvider.notifier).state = query;
                        },
                        onClear: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                    ),
                    if (!kReleaseMode) ...[
                      const SizedBox(width: 8),
                      // 调试按钮（仅在非生产模式显示）
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const ClipboardDebugPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        tooltip: '剪贴板调试工具',
                      ),
                    ],
                  ],
                ),

                // 内容区域
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
            var childAspectRatio = 1.6; // 恢复合理的卡片比例

            // 响应式布局：根据窗口宽度调整列数
            if (constraints.maxWidth > ClipConstants.defaultWindowWidth) {
              crossAxisCount = 3;
              childAspectRatio = 1.4; // 保持合理比例
            } else if (constraints.maxWidth < ClipConstants.minWindowWidth) {
              crossAxisCount = 1;
              childAspectRatio = 2.2; // 单列时稍微宽一些
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
            var childAspectRatio = 1.3; // 预览模式保持紧凑但合理

            // 响应式布局：根据窗口宽度调整列数
            if (constraints.maxWidth > 1400) {
              crossAxisCount = 4;
              childAspectRatio = 1.2;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
              childAspectRatio = 1.3;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
              childAspectRatio = 1.4;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 1.8;
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
              } on Exception catch (_) {
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
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
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
      case ClipType.text:
      case ClipType.rtf:
      case ClipType.html:
      case ClipType.audio:
      case ClipType.video:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        final content = item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }

  Widget _buildContentArea(
    String searchQuery,
    List<ClipItem> filteredItems,
    DisplayMode displayMode,
    S? l10n,
  ) {
    // 如果有搜索查询，检查搜索状态
    if (searchQuery.isNotEmpty) {
      final searchResult = ref.watch(databaseSearchProvider(searchQuery));
      return searchResult.when(
        data: (items) {
          // 应用筛选器到搜索结果
          final filterOption = ref.watch(filterTypeProvider);
          var filtered = items;
          if (filterOption != FilterOption.all) {
            filtered = items.where((item) {
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
                case FilterOption.all:
                  return true;
              }
            }).toList();
          }

          return filtered.isEmpty
              ? _buildEmptyState(l10n)
              : _buildClipboardList(filtered, displayMode, searchQuery);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _buildEmptyState(l10n),
      );
    }

    // 无搜索查询时的正常显示
    return filteredItems.isEmpty
        ? _buildEmptyState(l10n)
        : _buildClipboardList(filteredItems, displayMode, searchQuery);
  }
}
