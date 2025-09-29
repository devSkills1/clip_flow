import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:clip_flow_pro/features/settings/presentation/widgets/enhanced_key_handler.dart';
import 'package:clip_flow_pro/features/settings/presentation/widgets/hotkey_dialog_constants.dart';
import 'package:clip_flow_pro/features/settings/presentation/widgets/hotkey_error_handler.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 快捷键捕获对话框
class HotkeyCaptureDialog extends ConsumerStatefulWidget {
  /// 快捷键捕获对话框
  const HotkeyCaptureDialog({
    required this.action,
    super.key,
    this.currentConfig,
  });

  /// 要设置的快捷键动作
  final HotkeyAction action;

  /// 当前的快捷键配置（可选）
  final HotkeyConfig? currentConfig;

  @override
  ConsumerState<HotkeyCaptureDialog> createState() =>
      _HotkeyCaptureDialogState();
}

class _HotkeyCaptureDialogState extends ConsumerState<HotkeyCaptureDialog> {
  /// 当前捕获的修饰符
  final Set<HotkeyModifier> _capturedModifiers = {};

  /// 当前捕获的主键
  String? _capturedKey;

  /// 是否正在监听按键
  bool _isListening = false;

  /// 错误信息
  String? _errorMessage;

  /// 焦点节点
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 如果有当前配置，预填充
    if (widget.currentConfig != null) {
      _capturedModifiers.addAll(widget.currentConfig!.modifiers);
      _capturedKey = widget.currentConfig!.key;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 开始监听按键
  void _startListening() {
    setState(() {
      _isListening = true;
      _capturedModifiers.clear();
      _capturedKey = null;
      _errorMessage = null;
    });
    _focusNode.requestFocus();
  }

  /// 停止监听按键
  void _stopListening() {
    setState(() {
      _isListening = false;
    });
  }

  /// 处理按键事件
  bool _handleKeyEvent(KeyEvent event) {
    if (!_isListening) return false;

    if (event is KeyDownEvent) {
      setState(() {
        _errorMessage = null;

        // 使用增强的按键处理器
        if (EnhancedKeyHandler.isModifierKey(event.logicalKey)) {
          final modifier = EnhancedKeyHandler.getModifierType(event.logicalKey);
          if (modifier != null) {
            _capturedModifiers.add(modifier);
          }
        } else {
          // 处理主键
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            // ESC键取消设置
            _capturedModifiers.clear();
            _capturedKey = null;
            _stopListening();
          } else {
            final mainKey = EnhancedKeyHandler.getMainKeyLabel(
              event.logicalKey,
            );
            if (mainKey != null) {
              _capturedKey = mainKey;
              _stopListening();
            }
          }
        }
      });
    }

    return true;
  }

  /// 获取当前快捷键的显示字符串
  String get _currentHotkeyString {
    return EnhancedKeyHandler.formatHotkeyString(
      _capturedModifiers,
      _capturedKey,
    );
  }

  /// 验证快捷键是否有效
  bool get _isValidHotkey {
    return HotkeyValidator.isValidCombination(_capturedModifiers, _capturedKey);
  }

  /// 保存快捷键设置
  Future<void> _saveHotkey() async {
    // 使用增强的验证器
    final validationError = HotkeyErrorHandler.validateHotkeyConfig(
      _capturedModifiers,
      _capturedKey,
    );
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    try {
      final hotkeyService = ref.read(hotkeyServiceProvider);

      // 创建新的快捷键配置
      final newConfig = HotkeyConfig(
        action: widget.action,
        key: _capturedKey!,
        modifiers: _capturedModifiers,
        description: _getActionDescription(widget.action),
      );

      // 注册快捷键
      final result = await hotkeyService.registerHotkey(newConfig);

      if (result.success) {
        // 更新用户偏好设置（如果是全局快捷键）
        if (widget.action == HotkeyAction.toggleWindow) {
          ref
              .read(userPreferencesProvider.notifier)
              .setGlobalHotkey(_currentHotkeyString);
        }

        if (mounted) {
          Navigator.of(context).pop(newConfig);
        }
      } else {
        setState(() {
          final originalError = result.error ?? '设置失败';
          _errorMessage = HotkeyErrorHandler.getUserFriendlyErrorMessage(
            originalError,
          );
          if (result.conflicts.isNotEmpty) {
            _errorMessage =
                '$_errorMessage\n冲突: ${result.conflicts.map((c) => c.description).join(', ')}';
          }
        });
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = HotkeyErrorHandler.getUserFriendlyErrorMessage(
          e.toString(),
        );
      });
    }
  }

  /// 获取动作描述
  String _getActionDescription(HotkeyAction action) {
    switch (action) {
      case HotkeyAction.toggleWindow:
        return '显示/隐藏剪贴板窗口';
      case HotkeyAction.quickPaste:
        return '快速粘贴最近一项';
      case HotkeyAction.showHistory:
        return '显示剪贴板历史';
      case HotkeyAction.clearHistory:
        return '清空剪贴板历史';
      case HotkeyAction.search:
        return '搜索剪贴板内容';
      case HotkeyAction.performOCR:
        return 'OCR文字识别';
      case HotkeyAction.toggleMonitoring:
        return '暂停/恢复剪贴板监听';
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        title: Text('设置${_getActionDescription(widget.action)}快捷键'),
        content: SizedBox(
          width: HotkeyDialogConstants.dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请按下您想要设置的快捷键组合'),
              const SizedBox(height: HotkeyDialogConstants.largeSpacing),

              // 快捷键显示区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  HotkeyDialogConstants.largeSpacing,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isListening
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: _isListening
                        ? HotkeyDialogConstants.borderWidth
                        : HotkeyDialogConstants.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    HotkeyDialogConstants.borderRadius,
                  ),
                  color: _isListening
                      ? Theme.of(context).colorScheme.primary.withValues(
                          alpha: HotkeyDialogConstants.activeBackgroundOpacity,
                        )
                      : null,
                ),
                child: Text(
                  _currentHotkeyString,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: _isListening
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: HotkeyDialogConstants.largeSpacing),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isListening
                          ? _stopListening
                          : _startListening,
                      child: Text(_isListening ? '停止监听' : '开始设置'),
                    ),
                  ),
                  const SizedBox(width: HotkeyDialogConstants.smallSpacing),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _capturedModifiers.clear();
                          _capturedKey = null;
                          _errorMessage = null;
                        });
                      },
                      child: const Text('清除'),
                    ),
                  ),
                ],
              ),

              // 错误信息
              if (_errorMessage != null) ...[
                const SizedBox(height: HotkeyDialogConstants.largeSpacing),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    HotkeyDialogConstants.mediumSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(
                      HotkeyDialogConstants.borderRadius,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],

              // 提示信息
              const SizedBox(height: HotkeyDialogConstants.largeSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用提示：',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: HotkeyDialogConstants.smallSpacing),
                  ...HotkeyErrorHandler.getHotkeyTips().map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: HotkeyDialogConstants.smallSpacing / 2,
                      ),
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: HotkeyDialogConstants.smallSpacing),
                  Text(
                    '• 按 ESC 键可以清除当前设置',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: _isValidHotkey ? _saveHotkey : null,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
