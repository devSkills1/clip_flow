import 'dart:math' as math;

import 'package:clip_flow/core/constants/colors.dart';
import 'package:clip_flow/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/observability/logger/logger.dart';
import 'package:clip_flow/l10n/gen/s.dart';
import 'package:clip_flow/shared/providers/app_providers.dart';
import 'package:clip_flow/shared/widgets/toast_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 图标配置类
class IconConfig {
  /// 创建图标配置
  const IconConfig(this.icon, this.color);

  /// 图标数据
  final IconData icon;

  /// 图标颜色
  final Color color;
}

/// 剪贴板项目卡片工具类
class ClipItemCardUtil {
  /// 私有构造：禁止实例化
  ClipItemCardUtil._();

  /// 获取剪贴板项目的图标配置
  static IconConfig getIconConfig(ClipItem item) {
    switch (item.type) {
      case ClipType.text:
        return IconConfig(
          Icons.text_fields,
          Color(AppColors.iconColors['blue']!),
        );
      case ClipType.rtf:
      case ClipType.html:
        return IconConfig(
          Icons.description,
          Color(AppColors.iconColors['green']!),
        );
      case ClipType.image:
        return IconConfig(Icons.image, Color(AppColors.iconColors['purple']!));
      case ClipType.color:
        return IconConfig(
          Icons.palette,
          Color(AppColors.iconColors['orange']!),
        );
      case ClipType.file:
        return IconConfig(
          Icons.insert_drive_file,
          Color(AppColors.iconColors['grey']!),
        );
      case ClipType.audio:
        return IconConfig(
          Icons.audiotrack,
          Color(AppColors.iconColors['red']!),
        );
      case ClipType.video:
        return IconConfig(Icons.videocam, Color(AppColors.iconColors['pink']!));
      case ClipType.url:
        return IconConfig(Icons.link, Color(AppColors.iconColors['blue']!));
      case ClipType.email:
        return IconConfig(Icons.email, Color(AppColors.iconColors['green']!));
      case ClipType.json:
        return IconConfig(
          Icons.data_object,
          Color(AppColors.iconColors['orange']!),
        );
      case ClipType.xml:
        return IconConfig(Icons.code, Color(AppColors.iconColors['purple']!));
      case ClipType.code:
        return IconConfig(Icons.terminal, Color(AppColors.iconColors['grey']!));
    }
  }

  /// 获取剪贴板项目的图标
  static IconData getIcon(ClipItem item) {
    return getIconConfig(item).icon;
  }
}

/// 剪贴板项目工具类
class ClipItemUtil {
  /// 私有构造：禁止实例化
  ClipItemUtil._();

  /// 安全地将 dynamic 值解析为 int
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 安全地将 dynamic 值解析为 int?（保持可空性）
  static int? safeParseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 获取剪贴板项目的标题
  static String getItemTitle(ClipItem item, {S? l10n}) {
    final strings = l10n;
    const fallback = I18nFallbacks.common;
    final content = item.content ?? '';
    final previewText = _truncateContent(content);

    switch (item.type) {
      case ClipType.text:
      case ClipType.html:
      case ClipType.rtf:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        return previewText;
      case ClipType.image:
        final width = safeParseInt(item.metadata['width']);
        final height = safeParseInt(item.metadata['height']);
        final label = strings?.clipTypeImage ?? fallback.clipTypeImage;
        if (width > 0 && height > 0) {
          return '$label $width×$height';
        }
        return label;
      case ClipType.file:
      case ClipType.audio:
      case ClipType.video:
        return _resolveFileName(item, strings);
      case ClipType.color:
        final colorHex = content.isNotEmpty
            ? content
            : AppColors.defaultColorHex;
        final colorLabel =
            strings?.previewColor(colorHex) ??
            '${fallback.labelColor}: $colorHex';
        return colorLabel;
    }
  }

  /// 格式化日期显示（相对时间）
  static String formatDate(
    DateTime dateTime, {
    S? l10n,
    Locale? locale,
  }) {
    final strings = l10n;
    const fallback = I18nFallbacks.common;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return strings?.timeJustNow ?? fallback.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return strings?.timeMinutesAgo(difference.inMinutes) ??
          fallback.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return strings?.timeHoursAgo(difference.inHours) ??
          fallback.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return strings?.timeDaysAgo(difference.inDays) ??
          fallback.timeDaysAgo(difference.inDays);
    } else {
      final localeName = locale != null
          ? locale.toLanguageTag()
          : Intl.getCurrentLocale();
      return DateFormat.yMMMd(localeName).format(dateTime);
    }
  }

  /// 处理项目点击复制
  static Future<void> handleItemTap(
    ClipItem item,
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    // 🔍 调试：确认方法被调用
    await Log.i(
      '🟢 handleItemTap CALLED',
      tag: 'ClipItemUtil',
      fields: {
        'itemId': item.id,
        'itemType': item.type.name,
        'content':
            item.content?.substring(
              0,
              math.min(20, item.content?.length ?? 0),
            ) ??
            'null',
      },
    );

    try {
      // 只复制到剪贴板，剪贴板监控会自动处理后续更新
      // 这避免了双重更新：
      // 1. setClipboardContent 触发剪贴板监控
      // 2. 监控检测到变化 → 自动更新数据库和UI
      //
      // ❌ 不要在这里手动更新数据库或UI，会导致重复操作
      await Log.d(
        '📋 Calling setClipboardContent',
        tag: 'ClipItemUtil',
        fields: {'itemType': item.type.name},
      );

      await ref.read(clipboardServiceProvider).setClipboardContent(item);

      await Log.i(
        '✅ setClipboardContent completed',
        tag: 'ClipItemUtil',
      );

      // 显示提示
      // 显示提示
      if (context != null && context.mounted) {
        final localized = S.of(context);
        final previewLabel = _getItemPreview(item, l10n: localized);
        final snackText = localized != null
            ? localized.snackCopiedPrefix(previewLabel)
            : I18nFallbacks.common.snackCopiedPrefix(previewLabel);
        ToastView.show(
          context,
          snackText,
          icon: Icons.check_circle_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
        );
      }

      await Log.d(
        'Item copied to clipboard, monitoring will handle updates',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'itemType': item.type.name,
        },
      );
    } on Exception catch (e) {
      await Log.e(
        '❌ handleItemTap FAILED',
        tag: 'ClipItemUtil',
        error: e,
      );

      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.copyErrorMessage('$e') ??
            I18nFallbacks.common.copyErrorMessage('$e');
        _showErrorMessage(context, msg);
      }
    }
  }

  /// 处理OCR文本点击复制
  static Future<void> handleOcrTextTap(
    ClipItem item,
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    // 详细的调试信息
    await Log.d(
      'OCR text tap triggered',
      tag: 'ClipItemUtil',
      fields: {
        'itemId': item.id,
        'itemType': item.type.name,
        'hasOcrText': item.ocrText != null,
        'ocrTextLength': item.ocrText?.length ?? 0,
        'ocrTextId': item.ocrTextId,
        'ocrTextPreview':
            item.ocrText?.substring(
              0,
              math.min(50, item.ocrText?.length ?? 0),
            ) ??
            '',
      },
    );

    if (item.type != ClipType.image) {
      await Log.w(
        'OCR tap on non-image item',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'itemType': item.type.name,
        },
      );
      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.ocrImageOnlyError ??
            I18nFallbacks.common.ocrImageOnlyError;
        _showOcrErrorMessage(context, msg);
      }
      return;
    }

    if (item.ocrText == null || item.ocrText!.isEmpty) {
      await Log.w(
        'No OCR text available',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'hasOcrText': item.ocrText != null,
        },
      );
      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.ocrNoTextAvailable ??
            I18nFallbacks.common.ocrNoTextAvailable;
        _showOcrErrorMessage(context, msg);
      }
      return;
    }

    try {
      await Log.d(
        'Copying OCR text to clipboard',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'ocrTextId': item.ocrTextId,
          'textLength': item.ocrText!.length,
        },
      );

      // 直接复制OCR文本到剪贴板
      await flutter_services.Clipboard.setData(
        flutter_services.ClipboardData(text: item.ocrText!),
      );

      // 只复制到剪贴板，剪贴板监控会自动处理后续更新
      // 这避免了双重更新：
      // 1. Clipboard.setData 触发剪贴板监控
      // 2. 监控检测到变化 → 自动更新数据库和UI
      //
      // 之前的手动更新会导致：
      // 1. 更新了关联的OCR记录
      // 2. 监控又创建了一个新的文本记录
      // 3. 导致数据重复和UI跳动

      await Log.i(
        'OCR text copied successfully',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'ocrTextId': item.ocrTextId,
          'textLength': item.ocrText!.length,
        },
      );

      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.ocrTextCopied(item.ocrText!.length) ??
            I18nFallbacks.common.ocrTextCopied(item.ocrText!.length);
        ToastView.show(
          context,
          msg,
          icon: Icons.text_fields,
          iconColor: Theme.of(context).colorScheme.primary,
        );
      }
    } on Exception catch (e) {
      await Log.e('OCR copy operation failed', tag: 'ClipItemUtil', error: e);
      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.ocrCopyError('$e') ??
            I18nFallbacks.common.ocrCopyError('$e');
        _showOcrErrorMessage(context, msg);
      }
    }
  }

  /// 处理收藏状态切换
  static Future<void> handleFavoriteToggle(
    ClipItem item,
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    try {
      // 先更新数据库
      await ref
          .read(clipRepositoryProvider)
          .updateFavoriteStatus(
            id: item.id,
            isFavorite: !item.isFavorite,
          );

      // 数据库更新成功后再更新内存
      ref.read(clipboardHistoryProvider.notifier).toggleFavorite(item.id);

      await Log.d(
        'Favorite status toggled successfully',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'newFavoriteStatus': !item.isFavorite,
        },
      );

      // 静默完成收藏状态切换，不显示 SnackBar 减少打扰
    } on Exception catch (e) {
      await Log.e('Failed to toggle favorite', tag: 'ClipItemUtil', error: e);

      if (context != null && context.mounted) {
        final l10n = S.of(context);
        final msg = l10n?.favoriteToggleError('$e') ??
            I18nFallbacks.common.favoriteToggleError('$e');
        _showErrorMessage(context, msg);
      }
    }
  }

  /// 处理删除项目
  static Future<void> handleItemDelete(
    ClipItem item,
    WidgetRef ref, {
    BuildContext? context,
    VoidCallback? onDeleteConfirmed,
  }) async {
    if (context == null) {
      // 如果没有context，直接执行删除
      await _performDelete(item, ref);
      onDeleteConfirmed?.call();
      return;
    }

    final isFavorite = item.isFavorite;
    final l10n = S.of(context);
    const fallback = I18nFallbacks.common;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isFavorite ? Icons.warning_amber : Icons.delete_outline,
              color: isFavorite
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isFavorite
                  ? (l10n?.dialogDeleteFavoriteTitle ??
                      fallback.dialogDeleteFavoriteTitle)
                  : (l10n?.dialogDeleteTitle ?? fallback.dialogDeleteTitle),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFavorite) ...[
              Text(
                l10n?.dialogDeleteFavoriteWarning ??
                    fallback.dialogDeleteFavoriteWarning,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.dialogDeleteFavoriteConfirm ??
                    fallback.dialogDeleteFavoriteConfirm,
              ),
            ] else ...[
              Text(l10n?.dialogDeleteConfirm ?? fallback.dialogDeleteConfirm),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(l10n?.actionCancel ?? fallback.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(item, ref);
              onDeleteConfirmed?.call();
            },
            icon: const Icon(Icons.delete_forever),
            label: Text(l10n?.actionDelete ?? fallback.actionDelete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取项目预览文本
  static String _getItemPreview(ClipItem item, {S? l10n}) {
    final strings = l10n;
    const fallback = I18nFallbacks.common;

    switch (item.type) {
      case ClipType.image:
        final width = safeParseInt(item.metadata['width']);
        final height = safeParseInt(item.metadata['height']);
        final format = item.metadata['format'] as String?;
        final resolvedFormat =
            format?.toUpperCase() ??
            (strings?.unknownFormat ?? fallback.unknown);
        return strings?.previewImage(width, height, resolvedFormat) ??
            '${fallback.labelImage} ($width x $height, $resolvedFormat)';
      case ClipType.file:
      case ClipType.audio:
      case ClipType.video:
        final fileName = _resolveFileName(item, strings);
        return strings?.previewFile(fileName) ??
            '${fallback.labelFile}: $fileName';
      case ClipType.color:
        final colorHex = item.content ?? AppColors.defaultColorHex;
        return strings?.previewColor(colorHex) ??
            '${fallback.labelColor}: $colorHex';
      case ClipType.text:
      case ClipType.html:
      case ClipType.rtf:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        final content = item.content ?? '';
        return _truncateContent(content);
    }
  }

  static String _truncateContent(String value, {int maxLength = 50}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }

  static String _resolveFileName(ClipItem item, S? l10n) {
    const fallback = I18nFallbacks.common;
    final metadataName = item.metadata['fileName'];
    if (metadataName is String && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    final content = item.content?.trim();
    if (content != null && content.isNotEmpty) {
      return content;
    }

    return l10n?.unknownFile ?? fallback.unknown;
  }

  /// 执行实际的删除操作
  static Future<void> _performDelete(ClipItem item, WidgetRef ref) async {
    // 先尝试删除数据库记录
    try {
      await ref.read(clipRepositoryProvider).delete(item.id);

      // 数据库删除成功后，再移除内存
      ref.read(clipboardHistoryProvider.notifier).removeItem(item.id);

      await Log.d(
        'Item deleted successfully',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'itemType': item.type.name,
        },
      );

      // 静默完成删除，不显示成功提示减少打扰
    } on Exception catch (e) {
      await Log.e('Failed to delete item', tag: 'ClipItemUtil', error: e);

      // 删除失败时显示错误，不移除内存状态
      // 注意：这里无法显示SnackBar，因为没有context
      // 调用方需要处理错误显示
    }
  }

  /// 显示OCR错误消息
  static void _showOcrErrorMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ToastView.show(
        context,
        message,
        icon: Icons.warning_amber_rounded,
        iconColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// 显示错误消息
  static void _showErrorMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ToastView.show(
        context,
        message,
        icon: Icons.error_outline_rounded,
        iconColor: Theme.of(context).colorScheme.error,
      );
    }
  }
}
