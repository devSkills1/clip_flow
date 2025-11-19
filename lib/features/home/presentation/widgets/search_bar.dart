// ignore_for_file: public_member_api_docs
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
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.isLoading = false,
    this.autofocus = false,
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
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
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
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        widget.onClear();
                        _focusNode.unfocus(); // 失去焦点以隐藏搜索建议
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
