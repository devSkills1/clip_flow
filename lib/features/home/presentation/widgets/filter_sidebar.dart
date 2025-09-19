import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/dimensions.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/constants/routes.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/strings.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 筛选侧边栏
/// 提供筛选条件的选择和应用
class FilterSidebar extends ConsumerWidget {
  const FilterSidebar({
    required this.selectedType,
    required this.onTypeSelected,
    required this.onDisplayModeChanged,
    required this.displayMode,
    super.key,
  });
  final ClipType? selectedType;
  final ValueChanged<ClipType?> onTypeSelected;
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
          isSelected: selectedType == null,
          onTap: () => onTypeSelected(null),
        ),
        _buildFilterItem(
          icon: Icons.text_fields,
          label: S.of(context)?.filterTypeText ?? I18nFallbacks.filter.typeText,
          isSelected: selectedType == ClipType.text,
          onTap: () => onTypeSelected(ClipType.text),
        ),
        _buildFilterItem(
          icon: Icons.description,
          label:
              S.of(context)?.filterTypeRichText ??
              I18nFallbacks.filter.typeRichText,
          isSelected:
              selectedType == ClipType.rtf || selectedType == ClipType.html,
          onTap: () => onTypeSelected(ClipType.rtf),
        ),
        _buildFilterItem(
          icon: Icons.image,
          label:
              S.of(context)?.filterTypeImage ?? I18nFallbacks.filter.typeImage,
          isSelected: selectedType == ClipType.image,
          onTap: () => onTypeSelected(ClipType.image),
        ),
        _buildFilterItem(
          icon: Icons.palette,
          label:
              S.of(context)?.filterTypeColor ?? I18nFallbacks.filter.typeColor,
          isSelected: selectedType == ClipType.color,
          onTap: () => onTypeSelected(ClipType.color),
        ),
        _buildFilterItem(
          icon: Icons.insert_drive_file,
          label: S.of(context)?.filterTypeFile ?? I18nFallbacks.filter.typeFile,
          isSelected: selectedType == ClipType.file,
          onTap: () => onTypeSelected(ClipType.file),
        ),
        _buildFilterItem(
          icon: Icons.audiotrack,
          label:
              S.of(context)?.filterTypeAudio ?? I18nFallbacks.filter.typeAudio,
          isSelected: selectedType == ClipType.audio,
          onTap: () => onTypeSelected(ClipType.audio),
        ),
        _buildFilterItem(
          icon: Icons.videocam,
          label:
              S.of(context)?.filterTypeVideo ?? I18nFallbacks.filter.typeVideo,
          isSelected: selectedType == ClipType.video,
          onTap: () => onTypeSelected(ClipType.video),
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
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.secondary)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClipConstants.smallPadding),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
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
          icon: Icons.view_list,
          label:
              S.of(context)?.displayCompact ??
              I18nFallbacks.filter.displayCompact,
          mode: DisplayMode.compact,
        ),
        _buildDisplayModeItem(
          icon: Icons.view_module,
          label:
              S.of(context)?.displayNormal ??
              I18nFallbacks.filter.displayNormal,
          mode: DisplayMode.normal,
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

    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDisplayModeChanged(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClipConstants.smallPadding),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
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
                          await historyNotifier.clearHistory();
                          Navigator.of(dialogContext).pop();
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
