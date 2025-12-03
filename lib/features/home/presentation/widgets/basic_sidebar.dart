import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 基础侧边栏 - 最简单稳定的解决方案
///
/// 完全避免复杂的布局约束，使用基本的Column和Container结构
/// 固定宽度，无动画，无响应式逻辑，确保稳定性
class BasicSidebar extends ConsumerWidget {
  /// 创建基础侧边栏
  const BasicSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterType = ref.watch(filterTypeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 200, // 固定宽度，避免约束问题
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 头部 - 只显示图标
          _buildHeader(theme),

          // 分割线
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),

          // 导航菜单
          Expanded(
            child: _buildNavigation(context, ref, filterType, theme),
          ),

          // 底部操作区
          _buildBottomActions(context, ref, searchQuery, theme),
        ],
      ),
    );
  }

  /// 构建头部 - 只显示居中的图标
  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.content_paste_rounded,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  /// 构建导航菜单
  Widget _buildNavigation(
    BuildContext context,
    WidgetRef ref,
    FilterOption filterType,
    ThemeData theme,
  ) {
    final l10n = S.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildNavButton(
            context: context,
            ref: ref,
            icon: Icons.home_rounded,
            label: l10n.filterTypeAll,
            isSelected: filterType == FilterOption.all,
            onTap: () =>
                ref.read(filterTypeProvider.notifier).state = FilterOption.all,
            theme: theme,
          ),
          _buildNavButton(
            context: context,
            ref: ref,
            icon: Icons.text_fields_rounded,
            label: l10n.filterTypeText,
            isSelected: filterType == FilterOption.text,
            onTap: () =>
                ref.read(filterTypeProvider.notifier).state = FilterOption.text,
            theme: theme,
          ),
          _buildNavButton(
            context: context,
            ref: ref,
            icon: Icons.image_rounded,
            label: l10n.filterTypeImage,
            isSelected: filterType == FilterOption.image,
            onTap: () => ref.read(filterTypeProvider.notifier).state =
                FilterOption.image,
            theme: theme,
          ),
          _buildNavButton(
            context: context,
            ref: ref,
            icon: Icons.link_rounded,
            label: l10n.filterTypeFile,
            isSelected: filterType == FilterOption.file,
            onTap: () =>
                ref.read(filterTypeProvider.notifier).state = FilterOption.file,
            theme: theme,
          ),
          _buildNavButton(
            context: context,
            ref: ref,
            icon: Icons.colorize_rounded,
            label: l10n.filterTypeColor,
            isSelected: filterType == FilterOption.color,
            onTap: () => ref.read(filterTypeProvider.notifier).state =
                FilterOption.color,
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// 构建单个导航按钮 - 使用最简单的布局
  Widget _buildNavButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // 左侧选中指示器
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 图标
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),

                const SizedBox(width: 12),

                // 标签
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部操作区
  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    String searchQuery,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final l10n = S.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分割线
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),

        // 清空搜索按钮
        if (searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _buildActionButton(
              icon: Icons.clear_all_rounded,
              label: l10n.filterClearSearchButton,
              onTap: () => ref.read(searchQueryProvider.notifier).state = '',
              theme: theme,
            ),
          ),

        // 清空历史按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildActionButton(
            icon: Icons.delete_sweep_rounded,
            label: l10n.filterClearHistoryButton,
            onTap: () => _showClearHistoryDialog(context, ref),
            theme: theme,
          ),
        ),

        // 设置按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildActionButton(
            icon: Icons.settings_rounded,
            label: l10n.filterSettingsButton,
            onTap: () => context.push('/settings'),
            theme: theme,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示清空历史确认对话框
  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.filterConfirmClearTitle),
        content: Text(l10n.filterConfirmClearContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          // 新增一个“全部清空”按钮
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final historyNotifier = ref.read(
                clipboardHistoryProvider.notifier,
              );
              await historyNotifier.clearHistoryIncludingFavorites();
            },
            child: Text(
              l10n.filterClearAllButton,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              // 关闭对话框
              Navigator.of(dialogContext).pop();

              // 清空历史记录（保留收藏）
              final historyNotifier = ref.read(
                clipboardHistoryProvider.notifier,
              );
              await historyNotifier.clearHistory();
            },
            child: Text(l10n.filterClearAllUnfavoritedButton),
          ),
        ],
      ),
    );
  }
}
