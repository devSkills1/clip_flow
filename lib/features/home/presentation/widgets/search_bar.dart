// Simple search bar widget with Material Design 3 styling.
import 'package:flutter/material.dart';

/// 增强的搜索栏组件 - Material Design 3风格
class EnhancedSearchBar extends StatefulWidget {
  /// Creates an enhanced search bar.
  const EnhancedSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
    this.onSubmitted,
    this.isLoading = false,
    this.autofocus = false,
    this.dense = false,
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

  /// 是否加载中
  final bool isLoading;

  /// 是否自动聚焦
  final bool autofocus;

  /// 是否使用紧凑样式
  final bool dense;

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verticalPadding = widget.dense ? 6.0 : 12.0;
    final iconPadding = widget.dense ? 8.0 : 12.0;
    final fontSize = widget.dense ? 14.0 : 16.0;
    final fieldHeight = widget.dense ? 40.0 : 56.0;

    return SizedBox(
      height: fieldHeight,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          isDense: widget.dense,
          hintText: widget.hintText ?? '搜索剪贴板内容...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(iconPadding),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: widget.dense ? 36 : 48,
            minHeight: widget.dense ? 36 : 48,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    widget.onClear();
                    _focusNode.unfocus();
                  },
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: .7,
                    ),
                  ),
                  tooltip: '清除',
                )
              : null,
          suffixIconConstraints: BoxConstraints(
            minWidth: widget.dense ? 36 : 48,
            minHeight: widget.dense ? 36 : 48,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
        ),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
