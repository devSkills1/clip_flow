import 'dart:async';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/platform/system/window_listener.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom window chrome used when hiding the native title bar.
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
    final radius = BorderRadius.circular(compact ? 14 : 18);

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
                  const SizedBox(width: 10),
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
        : const SizedBox(width: 8);
    final spacingAfterLeft = hasLeftSection ? 12.0 : 6.0;

    return Container(
      margin: margin,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.92 : 0.9,
        ),
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.35 : 0.15,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                        height: compact ? 20 : 28,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 10),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: action,
              ),
            ),
          ],
          const SizedBox(width: 10),
          const WindowControlButtons(),
        ],
      ),
    );
  }
}

class _DefaultLeading extends StatelessWidget {
  const _DefaultLeading({
    required this.colorScheme,
    required this.compact,
  });

  final ColorScheme colorScheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.35),
            colorScheme.secondary.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.content_paste_rounded,
        size: compact ? 16 : 18,
        color: colorScheme.primary,
      ),
    );
  }
}

/// macOS-inspired window control dots.
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
        const SizedBox(width: 6),
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

class _WindowDotButtonState extends State<_WindowDotButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            unawaited(widget.onTap());
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: _hovered ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: Icon(
                widget.icon,
                size: 11,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
