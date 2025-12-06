// Filter components for clip item filtering and display mode selection.
import 'package:clip_flow/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';

/// 筛选选项
@immutable
class FilterOption {
  /// Creates a filter option.
  const FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  /// The filter value.
  final String value;

  /// The display label.
  final String label;

  /// The icon to display.
  final IconData icon;

  /// 预定义的筛选选项
  static const all = FilterOption(
    value: 'all',
    label: '全部',
    icon: Icons.apps,
  );

  /// All text filter option.
  static const text = FilterOption(
    value: 'text',
    label: '文本',
    icon: Icons.text_fields,
  );

  /// Rich text filter option.
  static const richTextUnion = FilterOption(
    value: 'rich',
    label: '富文本',
    icon: Icons.description,
  );

  /// RTF filter option.
  static const rtf = FilterOption(
    value: 'rtf',
    label: 'RTF',
    icon: Icons.description,
  );

  /// HTML filter option.
  static const html = FilterOption(
    value: 'html',
    label: 'HTML',
    icon: Icons.code,
  );

  /// Code filter option.
  static const code = FilterOption(
    value: 'code',
    label: '代码',
    icon: Icons.terminal,
  );

  /// Image filter option.
  static const image = FilterOption(
    value: 'image',
    label: '图片',
    icon: Icons.image,
  );

  /// Color filter option.
  static const color = FilterOption(
    value: 'color',
    label: '颜色',
    icon: Icons.palette,
  );

  /// File filter option.
  static const file = FilterOption(
    value: 'file',
    label: '文件',
    icon: Icons.insert_drive_file,
  );

  /// Audio filter option.
  static const audio = FilterOption(
    value: 'audio',
    label: '音频',
    icon: Icons.audiotrack,
  );

  /// Video filter option.
  static const video = FilterOption(
    value: 'video',
    label: '视频',
    icon: Icons.videocam,
  );

  /// Recent filter option.
  static const recent = FilterOption(
    value: 'recent',
    label: '最近',
    icon: Icons.access_time,
  );

  /// Favorites filter option.
  static const favorites = FilterOption(
    value: 'favorites',
    label: '收藏',
    icon: Icons.favorite,
  );

  /// Images filter option.
  static const images = FilterOption(
    value: 'images',
    label: '图片',
    icon: Icons.image,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// 快速筛选按钮组
class QuickFilterChips extends StatelessWidget {
  /// Creates quick filter chips.
  const QuickFilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.scrollDirection = Axis.horizontal,
    super.key,
  });

  /// 筛选选项列表
  final List<FilterOption> filters;

  /// 当前选中的筛选
  final FilterOption? selectedFilter;

  /// 筛选选择回调
  final ValueChanged<FilterOption> onFilterSelected;

  /// 滚动方向
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: scrollDirection,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return FilterChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (selected) => onFilterSelected(filter),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

/// 显示模式切换器
class DisplayModeToggle extends StatelessWidget {
  /// Creates a display mode toggle.
  const DisplayModeToggle({
    required this.displayMode,
    required this.onModeChanged,
    super.key,
  });

  /// 当前显示模式
  final DisplayMode displayMode;

  /// 模式变化回调
  final ValueChanged<DisplayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context,
            icon: Icons.view_list,
            mode: DisplayMode.compact,
            tooltip: '紧凑视图',
          ),
          _buildModeButton(
            context,
            icon: Icons.grid_view,
            mode: DisplayMode.normal,
            tooltip: '网格视图',
          ),
          _buildModeButton(
            context,
            icon: Icons.view_module,
            mode: DisplayMode.preview,
            tooltip: '预览视图',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required DisplayMode mode,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final isSelected = displayMode == mode;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () => onModeChanged(mode),
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: isSelected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
          backgroundColor: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
