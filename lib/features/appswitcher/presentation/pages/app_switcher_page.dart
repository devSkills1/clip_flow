import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/utils/clip_item_card_util.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/clip_item_card.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/search_bar.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart'; 
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
  int _selectedIndex = 0;
  List<ClipItem> _displayItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
  }

  /// 构建应用切换器专用的卡片，用 GestureDetector 包装解决点击问题
  Widget _buildAppSwitcherCard(ClipItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          ClipItemUtil.handleItemTap(item, ref, context: context);
        },
        child: ClipItemCard(
          key: ValueKey(item.id),
          item: item,
          displayMode: DisplayMode.compact, // 使用紧凑模式适合应用切换器
          onTap: () {
            // 卡片内部的点击事件，禁用避免重复触发
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
            // 使用统一的OCR处理逻辑
            ClipItemUtil.handleOcrTextTap(item, ref, context: context);
          },
        ),
      ),
    );
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
      });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
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

              // 水平横向滚动的应用切换器
              Expanded(
                child: _displayItems.isEmpty
                    ? const Center(
                        child: Text(
                          '没有找到匹配的内容',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 左箭头
                            if (_displayItems.length > 1)
                              IconButton(
                                onPressed: _selectedIndex > 0
                                    ? () {
                                        setState(() {
                                          _selectedIndex--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                                color: Colors.white,
                                iconSize: 20, // 与传统模式导航图标大小一致
                              ),

                            // 水平滚动视图 - 使用复用的 ModernClipItemCard
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final itemWidth =
                                      MediaQuery.of(context).size.width * 0.3;
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _displayItems.length,
                                    itemExtent: itemWidth,
                                    itemBuilder: (context, index) {
                                      final item = _displayItems[index];
                                      return _buildAppSwitcherCard(item, index);
                                    },
                                  );
                                },
                              ),
                            ),

                            // 右箭头
                            if (_displayItems.length > 1)
                              IconButton(
                                onPressed:
                                    _selectedIndex < _displayItems.length - 1
                                    ? () {
                                        setState(() {
                                          _selectedIndex++;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                                color: Colors.white,
                                iconSize: 20, // 与传统模式导航图标大小一致
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
