import 'package:flutter/material.dart';

/// 现代化的单选项组件，替代弃用的RadioListTile
/// 使用InheritedWidget来管理组状态，避免使用弃用的groupValue和onChanged
class ModernRadioListTile<T> extends StatelessWidget {
  /// 创建现代化单选项组件
  const ModernRadioListTile({
    required this.value,
    required this.groupValue,
    required this.title,
    super.key,
    this.subtitle,
    this.onChanged,
    this.toggleable = false,
  });

  /// 当前选项的值
  final T value;

  /// 选中组的值
  final T? groupValue;

  /// 标题
  final Widget title;

  /// 副标题
  final Widget? subtitle;

  /// 值变化回调
  final ValueChanged<T?>? onChanged;

  /// 是否可切换
  final bool toggleable;

  /// 检查是否选中
  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 自定义单选按钮
                _CustomRadio<T>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  toggleable: toggleable,
                ),
                const SizedBox(width: 12),
                // 标题和副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style:
                            theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ) ??
                            const TextStyle(),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ) ??
                              const TextStyle(),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (onChanged != null) {
      if (toggleable && isSelected) {
        onChanged!(null);
      } else if (!isSelected) {
        onChanged!(value);
      }
    }
  }
}

/// 自定义单选按钮组件
class _CustomRadio<T> extends StatelessWidget {
  const _CustomRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.toggleable,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final bool toggleable;

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          if (toggleable && isSelected) {
            onChanged!(null);
          } else if (!isSelected) {
            onChanged!(value);
          }
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
