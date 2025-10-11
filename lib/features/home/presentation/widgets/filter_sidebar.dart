// ignore_for_file: public_member_api_docs
// 忽略公共成员API文档要求，因为这是内部UI组件，不需要对外暴露API文档
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/dimensions.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/constants/routes.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/strings.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 筛选侧边栏
/// 提供筛选条件的选择和应用
class FilterSidebar extends ConsumerWidget {
  const FilterSidebar({
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onDisplayModeChanged,
    required this.displayMode,
    super.key,
  });
  final FilterOption selectedOption;
  final ValueChanged<FilterOption> onOptionSelected;
  final ValueChanged<DisplayMode> onDisplayModeChanged;
  final DisplayMode displayMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: Dimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(ClipConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.s8),
                Text(
                  S.of(context)?.filterTitle ?? I18nFallbacks.filter.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // 可滚动的内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 类型筛选
                  _buildTypeFilters(context),

                  const Divider(),

                  // 显示模式
                  _buildDisplayModeSelector(context),
                ],
              ),
            ),
          ),

          // 底部操作
          _buildBottomActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClipConstants.defaultPadding,
            vertical: ClipConstants.smallPadding,
          ),
          child: Text(
            S.of(context)?.filterTypeSection ??
                I18nFallbacks.filter.typeSection,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildFilterItem(
          icon: Icons.text_fields,
          label: S.of(context)?.filterTypeAll ?? I18nFallbacks.filter.typeAll,
          isSelected: selectedOption == FilterOption.all,
          onTap: () => onOptionSelected(FilterOption.all),
        ),
        _buildFilterItem(
          icon: Icons.text_fields,
          label: S.of(context)?.filterTypeText ?? I18nFallbacks.filter.typeText,
          isSelected: selectedOption == FilterOption.text,
          onTap: () => onOptionSelected(FilterOption.text),
        ),
        // 富文本联合筛选（RTF + HTML + Code）
        _buildFilterItem(
          icon: Icons.text_format,
          label:
              S.of(context)?.filterTypeRichText ??
              I18nFallbacks.filter.typeRichText,
          isSelected: selectedOption == FilterOption.richTextUnion,
          onTap: () => onOptionSelected(FilterOption.richTextUnion),
        ),
        // // RTF 独立项
        // _buildFilterItem(
        //   icon: Icons.description,
        //   label: I18nFallbacks.filter.typeRtf,
        //   isSelected: selectedOption == FilterOption.rtf,
        //   onTap: () => onOptionSelected(FilterOption.rtf),
        // ),
        // // HTML 独立项
        // _buildFilterItem(
        //   icon: Icons.language,
        //   label: I18nFallbacks.filter.typeHtml,
        //   isSelected: selectedOption == FilterOption.html,
        //   onTap: () => onOptionSelected(FilterOption.html),
        // ),
        // // Code 独立项
        // _buildFilterItem(
        //   icon: Icons.code,
        //   label: S.of(context)?.clipTypeCode ??
        //       I18nFallbacks.common.clipTypeCode,
        //   isSelected: selectedOption == FilterOption.code,
        //   onTap: () => onOptionSelected(FilterOption.code),
        // ),
        _buildFilterItem(
          icon: Icons.image,
          label:
              S.of(context)?.filterTypeImage ?? I18nFallbacks.filter.typeImage,
          isSelected: selectedOption == FilterOption.image,
          onTap: () => onOptionSelected(FilterOption.image),
        ),
        _buildFilterItem(
          icon: Icons.palette,
          label:
              S.of(context)?.filterTypeColor ?? I18nFallbacks.filter.typeColor,
          isSelected: selectedOption == FilterOption.color,
          onTap: () => onOptionSelected(FilterOption.color),
        ),
        _buildFilterItem(
          icon: Icons.insert_drive_file,
          label: S.of(context)?.filterTypeFile ?? I18nFallbacks.filter.typeFile,
          isSelected: selectedOption == FilterOption.file,
          onTap: () => onOptionSelected(FilterOption.file),
        ),
        _buildFilterItem(
          icon: Icons.audiotrack,
          label:
              S.of(context)?.filterTypeAudio ?? I18nFallbacks.filter.typeAudio,
          isSelected: selectedOption == FilterOption.audio,
          onTap: () => onOptionSelected(FilterOption.audio),
        ),
        _buildFilterItem(
          icon: Icons.videocam,
          label:
              S.of(context)?.filterTypeVideo ?? I18nFallbacks.filter.typeVideo,
          isSelected: selectedOption == FilterOption.video,
          onTap: () => onOptionSelected(FilterOption.video),
        ),
      ],
    );
  }

  Widget _buildFilterItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => _HoverScaleItem(
        onTap: onTap,
        isSelected: isSelected,
        child: ({required isHovered}) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.surfaceContainer
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.7),
                    width: 2,
                  )
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: isHovered ? 0.5 : 0.3),
                  ),
            boxShadow: [
              if (isSelected) ...[
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ] else ...[
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow
                      .withValues(alpha: isHovered ? 0.15 : 0.05),
                  blurRadius: isHovered ? 8 : 4,
                  offset: Offset(0, isHovered ? 3 : 1),
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.25)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: isHovered ? 0.8 : 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.outlineVariant
                            .withValues(alpha: isHovered ? 0.3 : 0.2),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: isSelected ? 15 : 14,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClipConstants.defaultPadding,
            vertical: ClipConstants.smallPadding,
          ),
          child: Text(
            S.of(context)?.filterDisplayModeSection ??
                I18nFallbacks.filter.displayModeSection,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildDisplayModeItem(
          icon: Icons.view_module,
          label:
              S.of(context)?.displayNormal ??
              I18nFallbacks.filter.displayNormal,
          mode: DisplayMode.normal,
        ),
        _buildDisplayModeItem(
          icon: Icons.view_list,
          label:
              S.of(context)?.displayCompact ??
              I18nFallbacks.filter.displayCompact,
          mode: DisplayMode.compact,
        ),
        _buildDisplayModeItem(
          icon: Icons.view_agenda,
          label:
              S.of(context)?.displayPreview ??
              I18nFallbacks.filter.displayPreview,
          mode: DisplayMode.preview,
        ),
      ],
    );
  }

  Widget _buildDisplayModeItem({
    required IconData icon,
    required String label,
    required DisplayMode mode,
  }) {
    final isSelected = displayMode == mode;
    // 根据不同显示模式微调图标与文字样式，提升辨识度
    final iconSize = switch (mode) {
      DisplayMode.compact => 16,
      DisplayMode.normal => 18,
      DisplayMode.preview => 20,
    };

    return Builder(
      builder: (context) => _HoverScaleItem(
        onTap: () => onDisplayModeChanged(mode),
        isSelected: isSelected,
        child: ({required isHovered}) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.surfaceContainer
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.7),
                    width: 2,
                  )
                : Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: isHovered ? 0.5 : 0.3),
                  ),
            boxShadow: [
              if (isSelected) ...[
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ] else ...[
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow
                      .withValues(alpha: isHovered ? 0.15 : 0.05),
                  blurRadius: isHovered ? 8 : 4,
                  offset: Offset(0, isHovered ? 3 : 1),
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.25)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: isHovered ? 0.8 : 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.outlineVariant
                            .withValues(alpha: isHovered ? 0.3 : 0.2),
                  ),
                ),
                child: Icon(
                  icon,
                  size: iconSize.toDouble(),
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    // 预览模式的标签稍大一点，便于强调
                    fontSize: switch (mode) {
                      DisplayMode.compact => 13,
                      DisplayMode.normal => 14,
                      DisplayMode.preview => 15,
                    },
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(ClipConstants.defaultPadding),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                context.push(AppRoutes.settings);
              },
              icon: const Icon(Icons.settings, size: 18),
              label: Text(
                S.of(context)?.filterSettingsButton ??
                    I18nFallbacks.filter.settingsButton,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClipConstants.smallPadding),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 清空历史记录
                final historyNotifier = ref.read(
                  clipboardHistoryProvider.notifier,
                );
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      S.of(context)?.filterConfirmClearTitle ??
                          I18nFallbacks.filter.confirmClearTitle,
                    ),
                    content: const Text(AppStrings.confirmClearHistory),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text(AppStrings.cancel),
                      ),
                      FilledButton(
                        onPressed: () async {
                          // 清空历史记录
                          final navigator = Navigator.of(dialogContext);
                          await historyNotifier.clearHistory();
                          if (navigator.mounted) {
                            navigator.pop();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        child: const Text(AppStrings.clear),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: Text(
                S.of(context)?.filterClearHistoryButton ??
                    I18nFallbacks.filter.clearHistoryButton,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 带有悬停放大效果的组件
class _HoverScaleItem extends StatefulWidget {
  const _HoverScaleItem({
    required this.onTap,
    required this.isSelected,
    required this.child,
  });

  final VoidCallback onTap;
  final bool isSelected;
  final Widget Function({required bool isHovered}) child;

  @override
  State<_HoverScaleItem> createState() => _HoverScaleItemState();
}

class _HoverScaleItemState extends State<_HoverScaleItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() {
      _isHovered = hovering;
    });
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child(isHovered: _isHovered),
            );
          },
        ),
      ),
    );
  }
}
