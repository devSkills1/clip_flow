import 'dart:async';
import 'dart:ui';

import 'package:clip_flow/core/services/observability/index.dart';
import 'package:flutter/material.dart';

/// ToastView is a widget that displays a toast message.
class ToastView extends StatelessWidget {
  /// Creates a ToastView.
  const ToastView({
    required this.message,
    super.key,
    this.icon,
    this.iconColor,
  });

  /// The message to display.
  final String message;

  /// The icon to display.
  final IconData? icon;

  /// The color of the icon.
  final Color? iconColor;

  static OverlayEntry? _currentEntry;
  static final List<_ToastRequest> _toastQueue = [];

  /// Shows a toast message.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final sanitizedMessage = message.trim();
    if (sanitizedMessage.isEmpty) {
      unawaited(
        Log.w(
          'Skipping toast with empty message',
          tag: 'ToastView',
          fields: {
            'originalLength': message.length,
          },
        ),
      );
      return;
    }

    _toastQueue.add(
      _ToastRequest(
        overlay: overlay,
        message: sanitizedMessage,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
      ),
    );

    if (_currentEntry == null) {
      _showNextToast();
    }
  }

  static void _showNextToast() {
    if (_toastQueue.isEmpty || _currentEntry != null) {
      return;
    }

    final request = _toastQueue.removeAt(0);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: request.message,
        icon: request.icon,
        iconColor: request.iconColor,
        duration: request.duration,
        onDismiss: () {
          try {
            overlayEntry.remove();
          } on Exception catch (e) {
            unawaited(
              Log.e(
                'Failed to remove toast overlay',
                tag: 'ToastView',
                error: e,
              ),
            );
          }
          if (_currentEntry == overlayEntry) {
            _currentEntry = null;
          }
          _showNextToast();
        },
      ),
    );

    _currentEntry = overlayEntry;
    request.overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF))
            .withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.duration,
    required this.onDismiss,
    this.icon,
    this.iconColor,
  });
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide =
        Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
          ),
        );

    unawaited(_controller.forward());

    Future.delayed(widget.duration, () {
      if (mounted) {
        unawaited(
          _controller.reverse().then((_) {
            if (mounted) {
              widget.onDismiss();
            }
          }),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We need to handle self-removal.
    // A common pattern is to pass the entry to the widget, but we can't do that easily in the builder.
    // Let's refactor `show` to handle removal.

    return Positioned(
      bottom:
          MediaQuery.of(context).padding.bottom +
          80, // Position above bottom nav/safe area
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: ToastView(
                message: widget.message,
                icon: widget.icon,
                iconColor: widget.iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastRequest {
  const _ToastRequest({
    required this.overlay,
    required this.message,
    required this.duration,
    this.icon,
    this.iconColor,
  });

  final OverlayState overlay;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final Duration duration;
}
