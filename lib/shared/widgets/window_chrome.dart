import 'dart:async';

import 'package:clip_flow/core/services/observability/index.dart';
import 'package:clip_flow/core/services/platform/system/window_listener.dart';
import 'package:clip_flow/l10n/gen/s.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 自定义窗口标题栏 - 隐藏原生标题栏时使用
///
/// 特性：
/// - Material Design 3 风格设计
/// - 支持深色/浅色主题自适应
/// - 渐变光晕和毛玻璃效果
/// - 优雅的阴影和边框处理
/// - 紧凑模式支持
class ModernWindowHeader extends StatelessWidget {
  /// Creates a ModernWindowHeader.
  const ModernWindowHeader({
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.center,
    this.margin = const EdgeInsets.fromLTRB(12, 6, 12, 4),
    this.compact = false,
    this.showTitle = true,
    this.showLeading = true,
    super.key,
  });

  /// 窗口标题
  final String title;

  /// 窗口副标题
  final String subtitle;

  /// 窗口左侧图标
  final Widget? leading;

  /// 窗口右侧操作按钮
  final List<Widget> actions;

  /// 窗口中间区域
  final Widget? center;

  /// 窗口边距
  final EdgeInsetsGeometry margin;

  /// 窗口是否紧凑
  final bool compact;

  /// 窗口是否显示标题
  final bool showTitle;

  /// 窗口是否显示左侧图标
  final bool showLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(compact ? 16 : 20);

    final hasTitle = showTitle && title.isNotEmpty;
    final resolvedLeading = showLeading
        ? (leading ??
              _DefaultLeading(colorScheme: colorScheme, compact: compact))
        : null;
    final hasLeftSection = hasTitle || resolvedLeading != null;

    final leftSection = hasLeftSection
        ? DragToMoveArea(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?resolvedLeading,
                if (resolvedLeading != null && hasTitle)
                  const SizedBox(width: 12),
                if (hasTitle)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
        : const SizedBox(width: 8);
    final spacingAfterLeft = hasLeftSection ? 14.0 : 6.0;

    return Container(
      margin: margin,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // 渐变背景 - 增强视觉层次感
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.88),
                ]
              : [
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.92),
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
                ],
        ),
        borderRadius: radius,
        // 双层边框效果 - 增强深度感
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        // 多层阴影 - 增强立体感和现代感
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.4 : 0.12,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          // 顶部高光效果 - 增强玻璃质感
          if (!isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 1,
              offset: const Offset(0, -0.5),
            ),
        ],
      ),
      child: Row(
        children: [
          leftSection,
          SizedBox(width: spacingAfterLeft),
          Expanded(
            child: center != null
                ? Align(
                    child: center,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DragToMoveArea(
                      child: Container(
                        height: compact ? 22 : 30,
                        decoration: BoxDecoration(
                          // 中央占位区域 - 微妙的凹陷效果
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.4),
                                  ]
                                : [
                                    colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.25),
                                    colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.35),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          // 内阴影效果
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.15 : 0.05,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 12),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: action,
              ),
            ),
          ],
          const SizedBox(width: 12),
          const WindowControlButtons(),
        ],
      ),
    );
  }
}

/// 默认的窗口 Logo - 带渐变光晕和动画效果
class _DefaultLeading extends StatelessWidget {
  const _DefaultLeading({
    required this.colorScheme,
    required this.compact,
  });

  final ColorScheme colorScheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 多层渐变 - 增强立体感
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.35),
            colorScheme.secondary.withValues(alpha: isDark ? 0.3 : 0.25),
            colorScheme.tertiary.withValues(alpha: isDark ? 0.25 : 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // 外光晕效果
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        Icons.content_paste_rounded,
        size: compact ? 16 : 18,
        color: colorScheme.primary,
      ),
    );
  }
}

/// macOS 风格窗口控制按钮 - 优雅的交互动画
class WindowControlButtons extends StatelessWidget {
  /// Creates a WindowControlButtons.
  const WindowControlButtons({
    this.onMinimize,
    this.onClose,
    super.key,
  });

  /// 最小化回调
  final Future<void> Function()? onMinimize;

  /// 关闭回调
  final Future<void> Function()? onClose;

  /// 最小化处理
  Future<void> _handleMinimize() async {
    if (onMinimize != null) {
      await onMinimize!();
      return;
    }
    await WindowManagementService.instance.minimize();
  }

  Future<void> _handleClose() async {
    if (onClose != null) {
      await onClose!();
      return;
    }
    try {
      await windowManager.close();
    } on Exception catch (error, stackTrace) {
      await Log.e(
        'Failed to close window from custom controls',
        tag: 'ModernWindowHeader',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowDotButton(
          color: const Color(0xFFFF5F56),
          icon: Icons.close_rounded,
          tooltip: l10n.windowCloseTooltip,
          onTap: _handleClose,
        ),
        const SizedBox(width: 8),
        _WindowDotButton(
          color: const Color(0xFFFFBD2E),
          icon: Icons.remove_rounded,
          tooltip: l10n.windowMinimizeTooltip,
          onTap: _handleMinimize,
        ),
      ],
    );
  }
}

/// 单个窗口控制按钮 - 带平滑动画和视觉反馈
class _WindowDotButton extends StatefulWidget {
  const _WindowDotButton({
    required this.color,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;

  @override
  State<_WindowDotButton> createState() => _WindowDotButtonState();
}

class _WindowDotButtonState extends State<_WindowDotButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
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
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            setState(() => _pressed = true);
            unawaited(_controller.forward());
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            unawaited(_controller.reverse());
          },
          onTapCancel: () {
            setState(() => _pressed = false);
            unawaited(_controller.reverse());
          },
          onTap: () {
            unawaited(widget.onTap());
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                // 多层阴影 - 增强立体感
                boxShadow: _hovered || _pressed
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  size: 12,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
