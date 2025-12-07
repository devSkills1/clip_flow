import 'package:flutter/material.dart';

/// 增强的搜索栏组件 - Material Design 3 风格
///
/// 特性：
/// - 简洁的底部边框设计
/// - 支持加载状态、自动聚焦、紧凑模式
/// - 清除按钮带 hover 和按压动画
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
    final colorScheme = theme.colorScheme;
    final verticalPadding = widget.dense ? 8.0 : 14.0;
    final horizontalPadding = widget.dense ? 14.0 : 18.0;
    final iconPadding = widget.dense ? 10.0 : 14.0;
    final fontSize = widget.dense ? 14.0 : 16.0;
    final fieldHeight = widget.dense ? 44.0 : 58.0;

    return Container(
      height: fieldHeight,
      decoration: BoxDecoration(
        // 简洁底部边框
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText ?? '搜索剪贴板内容...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            fontSize: fontSize,
            letterSpacing: 0.2,
          ),
          // 搜索图标 / 加载指示器
          prefixIcon: Padding(
            padding: EdgeInsets.all(iconPadding),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    size: widget.dense ? 20 : 22,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: widget.dense ? 40 : 48,
            minHeight: widget.dense ? 40 : 48,
          ),
          // 清除按钮
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: widget.controller.text.isNotEmpty
                ? _ClearButton(
                    onPressed: () {
                      widget.onClear();
                      _focusNode.unfocus();
                    },
                    colorScheme: colorScheme,
                    dense: widget.dense,
                  )
                : const SizedBox.shrink(),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: widget.dense ? 40 : 48,
            minHeight: widget.dense ? 40 : 48,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: fontSize,
          letterSpacing: 0.15,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 清除按钮 - 带 hover 和按压动画
class _ClearButton extends StatefulWidget {
  const _ClearButton({
    required this.onPressed,
    required this.colorScheme,
    required this.dense,
  });

  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final bool dense;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: EdgeInsets.all(widget.dense ? 10.0 : 12.0),
            child: Icon(
              Icons.close_rounded,
              size: widget.dense ? 18 : 20,
              color: widget.colorScheme.onSurface.withValues(
                alpha: _hovered ? 0.9 : 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
