import 'dart:ui' as ui;

import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/platform/system/window_listener.dart';
import 'package:clip_flow_pro/core/utils/clip_item_icon_util.dart';
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
    _setupWindow();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 设置窗口尺寸和属性
  Future<void> _setupWindow() async {
    try {
      // 等待一帧以确保context已初始化
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // 使用WindowManagementService统一处理窗口设置
          await WindowManagementService.instance.applyUISettings(
            UiMode.appSwitcher,
            context: context,
          );
        }
      });
    } on Exception catch (e, stackTrace) {
      // 错误处理，不阻止界面显示
      await Log.e(
        '应用切换器窗口设置失败',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadData() async {
    // 获取所有剪贴板历史数据
    final allItems = ref.read(clipboardHistoryProvider);
    setState(() {
      _displayItems = allItems.take(10).toList(); // 限制显示最近10个项目
      _selectedIndex = _displayItems.isNotEmpty ? 0 : -1;
    });
  }

  void _filterItems(String query) {
    final allItems = ref.read(clipboardHistoryProvider);
    final filtered = query.isEmpty
        ? allItems.take(10).toList()
        : allItems
              .where((item) {
                final content = item.content?.toLowerCase() ?? '';
                return content.contains(query.toLowerCase());
              })
              .take(10)
              .toList();

    setState(() {
      _displayItems = filtered;
      _selectedIndex = filtered.isNotEmpty ? 0 : -1;
    });
  }

  Widget _buildLargeItemIcon(ClipItem item) {
    final iconConfig = ClipItemIconUtil.getIconConfig(item);

    return Container(
      width: 48, // 与传统模式ListTile的leading保持一致
      height: 48,
      padding: const EdgeInsets.all(Spacing.s8), // 8px padding，与传统模式一致
      decoration: BoxDecoration(
        color: iconConfig.color.withValues(alpha: 0.1), // 与传统模式一致的透明度
        borderRadius: BorderRadius.circular(Spacing.s8), // 8px圆角，与传统模式一致
        border: Border.all(
          color: iconConfig.color.withValues(alpha: 0.2), // 与传统模式一致的边框透明度
        ),
      ),
      child: Icon(
        iconConfig.icon,
        color: iconConfig.color, // 使用类型颜色而不是白色，与传统模式一致
        size: 16, // 与传统模式type icon大小一致
      ),
    );
  }

  String _getItemTitle(ClipItem item) {
    return ClipItemUtil.getItemTitle(item);
  }

  String _formatDate(DateTime dateTime) {
    return ClipItemUtil.formatDateTime(dateTime);
  }

  void _onItemTap(ClipItem item) {
    // 复制到剪贴板
    ref.read(clipboardServiceProvider).setClipboardContent(item);

    // 显示提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已复制: ${_getItemTitle(item)}',
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
    // 监听剪贴板变化
    ref.listen<AsyncValue<ClipItem>>(clipboardStreamProvider, (previous, next) {
      next.whenData((clipItem) {
        _loadData(); // 重新加载数据以显示最新的项目
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
                        onPressed: () {
                          ref
                              .read(userPreferencesProvider.notifier)
                              .setUiMode(UiMode.traditional);
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

                            // 水平滚动视图
                            Expanded(
                              child: PageView.builder(
                                controller: PageController(
                                  viewportFraction: 0.3,
                                  initialPage: 0,
                                ),
                                itemCount: _displayItems.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final item = _displayItems[index];
                                  final isSelected = index == _selectedIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                      _onItemTap(item);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: Spacing.s8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.4,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          Spacing.s12,
                                        ), // 12px圆角，与传统模式卡片一致
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.6,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // 应用图标
                                          Container(
                                            width:
                                                48, // 与传统模式ListTile的leading保持一致
                                            height: 48,
                                            margin: const EdgeInsets.all(
                                              Spacing.s16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Spacing.s8,
                                                  ), // 8px圆角，与传统模式一致
                                            ),
                                            child: _buildLargeItemIcon(item),
                                          ),

                                          // 应用标题
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Spacing.s12,
                                            ),
                                            child: Text(
                                              _getItemTitle(item),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isSelected ? 14 : 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // 时间
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                bottom: 16,
                                                left: 12,
                                                right: 12,
                                              ),
                                              child: Text(
                                                _formatDate(item.createdAt),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
