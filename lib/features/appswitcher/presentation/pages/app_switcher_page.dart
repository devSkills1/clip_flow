import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/utils/clip_item_card_util.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/clip_item_card.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/search_bar.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用切换器页面
///
/// 模拟 macOS Cmd+Tab 的应用切换界面，支持：
/// - 全屏半透明背景
/// - 水平居中的应用列表
/// - 键盘和鼠标导航
/// - 实时预览和切换
class AppSwitcherPage extends ConsumerStatefulWidget {
  /// 构造器
  const AppSwitcherPage({super.key});

  @override
  ConsumerState<AppSwitcherPage> createState() => _AppSwitcherPageState();
}

class _AppSwitcherPageState extends ConsumerState<AppSwitcherPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  List<ClipItem> _displayItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // 自动滚动到选中项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIndex();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 获取所有剪贴板历史数据
    final allItems = ref.read(clipboardHistoryProvider);
    setState(() {
      _displayItems = allItems.toList();
      _selectedIndex = _displayItems.isNotEmpty ? 0 : -1;
    });
  }

  void _filterItems(String query) {
    final allItems = ref.read(clipboardHistoryProvider);
    final filtered = query.isEmpty
        ? allItems.toList()
        : allItems.where((item) {
            final content = item.content?.toLowerCase() ?? '';
            return content.contains(query.toLowerCase());
          }).toList();

    setState(() {
      _displayItems = filtered;
      _selectedIndex = filtered.isNotEmpty ? 0 : -1;
    });

    // 滚动到新的选中项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIndex();
    });
  }

  void _navigateLeft() {
    if (_displayItems.isNotEmpty && _selectedIndex > 0) {
      setState(() {
        _selectedIndex--;
      });
      _scrollToSelectedIndex();
    }
  }

  void _navigateRight() {
    if (_displayItems.isNotEmpty && _selectedIndex < _displayItems.length - 1) {
      setState(() {
        _selectedIndex++;
      });
      _scrollToSelectedIndex();
    }
  }

  void _scrollToSelectedIndex() {
    if (_scrollController.hasClients && _selectedIndex >= 0 && _displayItems.isNotEmpty) {
      const cardWidth = 280.0;
      const cardMargin = 32.0; // 16 + 16 horizontal margin
      const totalCardWidth = cardWidth + cardMargin;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (_selectedIndex * totalCardWidth) - (screenWidth / 2) + (totalCardWidth / 2);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  
  /// 构建应用切换器专用的卡片，带选中效果
  Widget _buildAppSwitcherCard(ClipItem item, int index) {
    final isSelected = index == _selectedIndex;

    return Container(
      width: 280,
      margin: EdgeInsets.symmetric(
        horizontal: isSelected ? 16 : 8,
        vertical: 8,
      ),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(isSelected ? 1.05 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipItemCard(
                key: ValueKey(item.id),
                item: item,
                displayMode: DisplayMode.compact,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  // 点击图片时复制图片
                  ClipItemUtil.handleItemTap(item, ref, context: context);
                },
                onDelete: () {
                  ClipItemUtil.handleItemDelete(item, ref, context: context);
                },
                onFavoriteToggle: () {
                  ClipItemUtil.handleFavoriteToggle(item, ref, context: context);
                },
                searchQuery: _searchController.text,
                enableOcrCopy: true,
                onOcrTextTap: () {
                  // 点击OCR文字时只复制文字
                  ClipItemUtil.handleOcrTextTap(item, ref, context: context);
                },
              ),
            ),
          ),
        ),
      ), // 关闭 AnimatedContainer
      ), // 关闭 MouseRegion
    ); // 关闭 Container
  }

  
  @override
  Widget build(BuildContext context) {
    // 监听剪贴板变化和历史列表变化
    ref
      ..listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
        next.whenData((clipItem) {
          // 将新的剪贴板项目添加到历史记录
          ref.read(clipboardHistoryProvider.notifier).addItem(clipItem);
        });
      })
      ..listen<List<ClipItem>>(clipboardHistoryProvider, (previous, next) {
        if (!mounted) return;
        setState(() {
          _displayItems = next.toList();
          _selectedIndex = _displayItems.isNotEmpty ? 0 : -1;
        });
        // 滚动到新的选中项
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedIndex();
        });
      });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _navigateLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _navigateRight,
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_selectedIndex >= 0 && _displayItems.isNotEmpty) {
            ClipItemUtil.handleItemTap(_displayItems[_selectedIndex], ref, context: context);
          }
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (_selectedIndex >= 0 && _displayItems.isNotEmpty) {
            ClipItemUtil.handleItemTap(_displayItems[_selectedIndex], ref, context: context);
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
            tileMode: ui.TileMode.decal,
          ),
          child: Column(
            children: [
              // 顶部搜索框和切换按钮 - 占总宽度一半，居中显示
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  margin: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // 搜索框 - 直接使用EnhancedSearchBar组件（不使用搜索建议）
                      Expanded(
                        child: EnhancedSearchBar(
                          controller: _searchController,
                          hintText: '搜索剪贴板内容...',
                          onChanged: _filterItems,
                          onClear: () {
                            _searchController.clear();
                            _filterItems('');
                          },
                        ),
                      ),
                      const SizedBox(width: Spacing.s12),
                      // 切换回传统UI的按钮 - 样式与EnhancedSearchBar保持一致
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            ref
                                .read(userPreferencesProvider.notifier)
                                .setUiMode(UiMode.traditional);
                            // 切换界面模式后重新设置窗口并居中
                            if (mounted) {
                              await WindowManagementService.instance
                                  .applyUISettings(UiMode.traditional, context: context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          tooltip: '切回传统剪贴板',
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // macOS风格的应用切换器 - 居中显示，支持键盘导航
              Expanded(
                child: _displayItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.content_paste_search,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '没有找到匹配的内容',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 48),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            itemCount: _displayItems.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final item = _displayItems[index];
                              return _buildAppSwitcherCard(item, index);
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
