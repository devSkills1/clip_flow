import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/modern_clip_item_card.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';

/// 响应式首页布局组件 - 解决布局溢出和响应式问题
class ResponsiveHomeLayout extends StatelessWidget {
  /// 响应式首页布局组件
  const ResponsiveHomeLayout({
    required this.items,
    required this.displayMode,
    required this.searchQuery,
    required this.onItemTap,
    required this.onItemDelete,
    required this.emptyWidget,
    super.key,
    this.scrollController,
  });

  /// 剪贴板项目列表
  final List<ClipItem> items;

  /// 显示模式
  final DisplayMode displayMode;

  /// 搜索查询
  final String? searchQuery;

  /// 项目点击回调
  final void Function(ClipItem) onItemTap;

  /// 项目删除回调
  final void Function(ClipItem) onItemDelete;

  /// 空状态组件
  final Widget emptyWidget;

  /// 滚动控制器
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget;
    }

    switch (displayMode) {
      case DisplayMode.compact:
        return _buildCompactLayout(context);
      case DisplayMode.normal:
        return _buildNormalLayout(context);
      case DisplayMode.preview:
        return _buildPreviewLayout(context);
    }
  }

  Widget _buildCompactLayout(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ModernClipItemCard(
                  key: ValueKey(item.id),
                  item: item,
                  displayMode: DisplayMode.compact,
                  searchQuery: searchQuery,
                  onTap: () => onItemTap(item),
                  onDelete: () => onItemDelete(item),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutConfig = _calculateGridLayout(constraints.maxWidth);

        return CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(layoutConfig.padding),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: layoutConfig.crossAxisCount,
                  crossAxisSpacing: layoutConfig.crossAxisSpacing,
                  mainAxisSpacing: layoutConfig.mainAxisSpacing,
                  childAspectRatio: layoutConfig.childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return ModernClipItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      displayMode: DisplayMode.normal,
                      searchQuery: searchQuery,
                      onTap: () => onItemTap(item),
                      onDelete: () => onItemDelete(item),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutConfig = _calculatePreviewLayout(constraints);

        return CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(layoutConfig.padding),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: layoutConfig.crossAxisCount,
                  crossAxisSpacing: layoutConfig.crossAxisSpacing,
                  mainAxisSpacing: layoutConfig.mainAxisSpacing,
                  childAspectRatio: layoutConfig.childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return ModernClipItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      displayMode: DisplayMode.preview,
                      searchQuery: searchQuery,
                      onTap: () => onItemTap(item),
                      onDelete: () => onItemDelete(item),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  GridLayoutConfig _calculateGridLayout(double width) {
    int crossAxisCount;
    double childAspectRatio;
    double padding;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (width > 1600) {
      // 超宽屏
      crossAxisCount = 4;
      childAspectRatio = 1.8;
      padding = 24;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    } else if (width > 1200) {
      // 宽屏
      crossAxisCount = 3;
      childAspectRatio = 1.6;
      padding = 20;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (width > 800) {
      // 中等屏幕
      crossAxisCount = 2;
      childAspectRatio = 1.4;
      padding = 16;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
    } else {
      // 小屏幕
      crossAxisCount = 1;
      childAspectRatio = 2.2;
      padding = 16;
      crossAxisSpacing = 8;
      mainAxisSpacing = 8;
    }

    return GridLayoutConfig(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      padding: padding,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  GridLayoutConfig _calculatePreviewLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;

    int crossAxisCount;
    double childAspectRatio;
    double padding;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (width > 1600) {
      // 超宽屏 - 3列，更接近正方形的卡片
      crossAxisCount = 3;
      childAspectRatio = 1.0;
      padding = 24;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    } else if (width > 1200) {
      // 宽屏 - 2列，较大卡片
      crossAxisCount = 2;
      childAspectRatio = 0.9;
      padding = 20;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (width > 800) {
      // 中等屏幕 - 2列，适中卡片
      crossAxisCount = 2;
      childAspectRatio = 1.0;
      padding = 16;
      crossAxisSpacing = 12;
      mainAxisSpacing = 12;
    } else if (width > 600) {
      // 小屏幕 - 1列，横向卡片
      crossAxisCount = 1;
      childAspectRatio = 1.8;
      padding = 16;
      crossAxisSpacing = 8;
      mainAxisSpacing = 8;
    } else {
      // 超小屏幕 - 1列，紧凑卡片
      crossAxisCount = 1;
      childAspectRatio = 1.5;
      padding = 12;
      crossAxisSpacing = 6;
      mainAxisSpacing = 6;
    }

    return GridLayoutConfig(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      padding: padding,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }
}

/// 网格布局配置
class GridLayoutConfig {
  /// 创建网格布局配置
  const GridLayoutConfig({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.padding,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });

  /// 横轴项目数量
  final int crossAxisCount;

  /// 子组件宽高比
  final double childAspectRatio;

  /// 内边距
  final double padding;

  /// 横轴间距
  final double crossAxisSpacing;

  /// 主轴间距
  final double mainAxisSpacing;
}

/// 增强的空状态组件
class EnhancedEmptyState extends StatelessWidget {
  /// 创建增强的空状态组件
  const EnhancedEmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
    super.key,
  });

  /// 标题文本
  final String title;

  /// 副标题文本
  final String subtitle;

  /// 图标
  final IconData icon;

  /// 操作按钮列表
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
              // 图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 24),

              // 标题
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 副标题
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),

              // 操作按钮
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// 加载状态组件
class LoadingState extends StatelessWidget {
  /// 创建加载状态组件
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 错误状态组件
class ErrorState extends StatelessWidget {
  /// 创建错误状态组件
  const ErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// 错误信息
  final String message;

  /// 重试回调
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '出现错误',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
