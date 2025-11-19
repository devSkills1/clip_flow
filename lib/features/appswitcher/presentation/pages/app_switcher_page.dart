import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/modern_clip_item_card.dart';
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

  /// 构建应用切换器专用的卡片包装器，复用 ModernClipItemCard
  Widget _buildAppSwitcherCard(ClipItem item, int index) {
    final isSelected = index == _selectedIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.s8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.s12),
        color: isSelected
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.s12),
        child: ModernClipItemCard(
          key: ValueKey(item.id),
          item: item,
          displayMode: DisplayMode.compact, // 使用紧凑模式适合应用切换器
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            _onItemTap(item);
          },
          onDelete: () {
            // 应用切换器中禁用删除功能
          },
          searchQuery: _searchController.text,
          enableOcrCopy: true,
          onOcrTextTap: () {
            // OCR文本复制逻辑
            if (item.ocrText != null && item.ocrText!.isNotEmpty) {
              ref
                  .read(clipboardServiceProvider)
                  .setClipboardContent(item.copyWith(content: item.ocrText));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '已复制OCR文本: ${item.ocrText!.substring(0, 50)}${item.ocrText!.length > 50 ? "..." : ""}',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _onItemTap(ClipItem item) {
    // 复制到剪贴板
    ref.read(clipboardServiceProvider).setClipboardContent(item);

    // 显示提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已复制: ${(item.content?.length ?? 0) > 50 ? "${item.content?.substring(0, 50)}..." : item.content ?? "未知内容"}',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听剪贴板变化和历史列表变化
    ref
      ..listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
        next.whenData((clipItem) {
          _loadData(); // 重新加载数据以显示最新的项目
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
                      // 搜索框
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '搜索剪贴板内容...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Spacing.s12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Spacing.s12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Spacing.s12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.s16,
                              vertical: Spacing.s12,
                            ),
                          ),
                          onChanged: _filterItems,
                        ),
                      ),
                      const SizedBox(width: Spacing.s12),
                      // 切换回传统UI的按钮
                      ElevatedButton.icon(
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
                        label: const Text('切回传统剪贴板'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Spacing.s8),
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
