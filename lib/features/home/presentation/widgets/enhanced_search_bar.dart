import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 增强的搜索栏组件 - Material Design 3风格
class EnhancedSearchBar extends StatefulWidget {
  const EnhancedSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
    this.onSubmitted,
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.isLoading = false,
    this autofocus = false,
    super.key,
  });

  /// 文本控制器
  final TextEditingController controller;

  /// 文本变化回调
  final ValueChanged<String> onChanged;

  /// 清除回调
  final VoidCallback onClear;

  /// 提示文本
  final String? hintText;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 搜索建议列表
  final List<String> suggestions;

  /// 建议选择回调
  final ValueChanged<String>? onSuggestionSelected;

  /// 是否加载中
  final bool isLoading;

  /// 是否自动聚焦
  final bool autofocus;

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final hasSuggestions = widget.suggestions.isNotEmpty;

    setState(() {
      _showSuggestions = hasFocus && hasText && hasSuggestions;
    });

    if (_showSuggestions) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 搜索栏主体
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onChanged: (value) {
              widget.onChanged(value);
              _onFocusChange();
            },
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText ?? '搜索剪贴板内容...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        widget.onClear();
                        _focusNode.requestFocus();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      tooltip: '清除',
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),

        // 搜索建议
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _fadeAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildSuggestions(context),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    if (!_showSuggestions || widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.suggestions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final suggestion = widget.suggestions[index];
            return ListTile(
              leading: Icon(
                Icons.history,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              title: Text(
                suggestion,
                style: theme.textTheme.bodyMedium,
              ),
              onTap: () {
                widget.controller.text = suggestion;
                widget.onChanged(suggestion);
                widget.onSuggestionSelected?.call(suggestion);
                _focusNode.unfocus();
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
            );
          },
        ),
      ),
    );
  }
}

/// 快速筛选按钮组
class QuickFilterChips extends StatelessWidget {
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
              width: 1,
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

/// 筛选选项
class FilterOption {
  const FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  // 预定义的筛选选项
  static const all = FilterOption(
    value: 'all',
    label: '全部',
    icon: Icons.apps,
  );
  static const text = FilterOption(
    value: 'text',
    label: '文本',
    icon: Icons.text_fields,
  );
  static const richTextUnion = FilterOption(
    value: 'rich',
    label: '富文本',
    icon: Icons.description,
  );
  static const rtf = FilterOption(
    value: 'rtf',
    label: 'RTF',
    icon: Icons.description,
  );
  static const html = FilterOption(
    value: 'html',
    label: 'HTML',
    icon: Icons.code,
  );
  static const code = FilterOption(
    value: 'code',
    label: '代码',
    icon: Icons.terminal,
  );
  static const image = FilterOption(
    value: 'image',
    label: '图片',
    icon: Icons.image,
  );
  static const color = FilterOption(
    value: 'color',
    label: '颜色',
    icon: Icons.palette,
  );
  static const file = FilterOption(
    value: 'file',
    label: '文件',
    icon: Icons.insert_drive_file,
  );
  static const audio = FilterOption(
    value: 'audio',
    label: '音频',
    icon: Icons.audiotrack,
  );
  static const video = FilterOption(
    value: 'video',
    label: '视频',
    icon: Icons.videocam,
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

/// 显示模式切换器
class DisplayModeToggle extends StatelessWidget {
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

/// 高级筛选面板
class AdvancedFilterPanel extends StatefulWidget {
  const AdvancedFilterPanel({
    required this.selectedTypes,
    required this.onTypesChanged,
    required this.dateRange,
    required this.onDateRangeChanged,
    super.key,
  });

  /// 选中的类型
  final Set<ClipType> selectedTypes;

  /// 类型变化回调
  final ValueChanged<Set<ClipType>> onTypesChanged;

  /// 日期范围
  final DateTimeRange? dateRange;

  /// 日期范围变化回调
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  @override
  State<AdvancedFilterPanel> createState() => _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends State<AdvancedFilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 标题和展开按钮
          ListTile(
            leading: Icon(
              Icons.tune,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              '高级筛选',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(Icons.expand_more),
            ),
            onTap: _toggleExpanded,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // 展开的筛选内容
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 类型筛选
                    Text(
                      '内容类型',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTypeFilter(context),

                    const SizedBox(height: 24),

                    // 日期范围筛选
                    Text(
                      '时间范围',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateFilter(context),

                    const SizedBox(height: 16),

                    // 操作按钮
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('重置'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _toggleExpanded,
                          child: const Text('应用筛选'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    final theme = Theme.of(context);
    final allTypes = ClipType.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTypes.map((type) {
        final isSelected = widget.selectedTypes.contains(type);
        final typeInfo = _getClipTypeInfo(type);

        return FilterChip(
          label: Text(typeInfo.label),
          avatar: Icon(
            typeInfo.icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          selected: isSelected,
          onSelected: (selected) {
            final newSelected = Set<ClipType>.from(widget.selectedTypes);
            if (selected) {
              newSelected.add(type);
            } else {
              newSelected.remove(type);
            }
            widget.onTypesChanged(newSelected);
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: theme.colorScheme.primaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(widget.dateRange != null
              ? '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}'
              : '选择日期范围'),
        ),
        if (widget.dateRange != null) ...[
          const SizedBox(height: 8),
          Text(
            '范围: ${_calculateDaysBetween(widget.dateRange!.start, widget.dateRange!.end)} 天',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  ClipTypeInfo _getClipTypeInfo(ClipType type) {
    switch (type) {
      case ClipType.text:
        return ClipTypeInfo('文本', Icons.text_fields);
      case ClipType.rtf:
        return ClipTypeInfo('富文本', Icons.description);
      case ClipType.html:
        return ClipTypeInfo('HTML', Icons.code);
      case ClipType.image:
        return ClipTypeInfo('图片', Icons.image);
      case ClipType.color:
        return ClipTypeInfo('颜色', Icons.palette);
      case ClipType.file:
        return ClipTypeInfo('文件', Icons.insert_drive_file);
      case ClipType.audio:
        return ClipTypeInfo('音频', Icons.audiotrack);
      case ClipType.video:
        return ClipTypeInfo('视频', Icons.videocam);
      case ClipType.url:
        return ClipTypeInfo('链接', Icons.link);
      case ClipType.email:
        return ClipTypeInfo('邮箱', Icons.email);
      case ClipType.json:
        return ClipTypeInfo('JSON', Icons.data_object);
      case ClipType.xml:
        return ClipTypeInfo('XML', Icons.code);
      case ClipType.code:
        return ClipTypeInfo('代码', Icons.terminal);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  int _calculateDaysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  void _resetFilters() {
    widget.onTypesChanged(<ClipType>{});
    widget.onDateRangeChanged(null);
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }
}

class ClipTypeInfo {
  const ClipTypeInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}