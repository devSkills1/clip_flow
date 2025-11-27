import 'dart:math' as math;

import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
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

  /// 获取剪贴板项目的图标颜色
  static Color getIconColor(ClipItem item) {
    return getIconConfig(item).color;
  }
}

/// 剪贴板项目工具类
class ClipItemUtil {
  /// 私有构造：禁止实例化
  ClipItemUtil._();

  /// 获取剪贴板项目的标题
  static String getItemTitle(ClipItem item) {
    final content = item.content ?? '';
    switch (item.type) {
      case ClipType.text:
      case ClipType.html:
      case ClipType.rtf:
        return content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
      case ClipType.image:
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
        return width > 0 && height > 0 ? '图片 $width×$height' : '图片';
      case ClipType.file:
        final fileName = item.metadata['fileName'] as String? ?? '未知文件';
        return fileName;
      case ClipType.color:
        final colorHex = content.isNotEmpty ? content : AppColors.defaultColorHex;
        return '颜色 $colorHex';
      case ClipType.url:
        return content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
      case ClipType.email:
        return content;
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        return content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
      case ClipType.audio:
      case ClipType.video:
        final fileName = item.metadata['fileName'] as String? ??
            (content.isNotEmpty ? content : '${item.type.name}文件');
        return fileName;
    }
  }

  /// 格式化日期显示（相对时间）
  static String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }

  /// 格式化日期显示（带时间）
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 处理项目点击复制
  static Future<void> handleItemTap(
    ClipItem item,
    WidgetRef ref, {
    BuildContext? context,
  }) async {
    try {
      // 只复制到剪贴板，剪贴板监控会自动处理后续更新
      // 这避免了双重更新：
      // 1. setClipboardContent 触发剪贴板监控
      // 2. 监控检测到变化 → 自动更新数据库和UI
      // 
      // ❌ 不要在这里手动更新数据库或UI，会导致重复操作
      await ref.read(clipboardServiceProvider).setClipboardContent(item);

      // 显示提示
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.snackCopiedPrefix(_getItemPreview(item)) ??
                  I18nFallbacks.common.snackCopiedPrefix(_getItemPreview(item)),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
      await Log.e('Failed to copy item', tag: 'ClipItemUtil', error: e);

      if (context != null && context.mounted) {
        _showErrorMessage(context, '复制失败：$e');
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
        'ocrTextPreview': item.ocrText?.substring(
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
        _showOcrErrorMessage(context, '只能对图片类型进行OCR操作');
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
        _showOcrErrorMessage(context, '该图片没有可用的OCR文本');
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

      // 更新数据库中对应的OCR文本记录（如果存在ocrTextId）
      if (item.ocrTextId != null) {
        final updatedOcrItem = await _updateOcrTextRecord(item);
        if (updatedOcrItem != null) {
          ref.read(clipboardHistoryProvider.notifier).addItem(updatedOcrItem);
        }
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ OCR文本已复制到剪贴板 (${item.ocrText!.length}字符)',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      await Log.e('OCR copy operation failed', tag: 'ClipItemUtil', error: e);
      if (context != null && context.mounted) {
        _showOcrErrorMessage(context, 'OCR复制错误：$e');
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
        _showErrorMessage(context, '收藏操作失败：$e');
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
            Text(isFavorite ? '删除收藏项目？' : '确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFavorite) ...[
              const Text(
                '这是一个收藏的项目！删除后将无法恢复。',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Text('你确定要继续删除吗？'),
            ] else ...[
              const Text('确定要删除这个项目吗？'),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(item, ref);
              onDeleteConfirmed?.call();
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('删除'),
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
  static String _getItemPreview(ClipItem item) {
    switch (item.type) {
      case ClipType.image:
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
        final format = item.metadata['format'] as String?;
        return '${I18nFallbacks.common.labelImage} '
            '($width x $height, ${format ?? I18nFallbacks.common.unknown})';
      case ClipType.file:
        final fileName =
            item.metadata['fileName'] as String? ??
            I18nFallbacks.common.unknown;
        return '${I18nFallbacks.common.labelFile}: $fileName';
      case ClipType.color:
        final colorHex = item.content ?? AppColors.defaultColorHex;
        return '${I18nFallbacks.common.labelColor}: $colorHex';
      case ClipType.text:
      case ClipType.html:
      case ClipType.rtf:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
      case ClipType.audio:
      case ClipType.video:
        final content = item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
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

  /// 更新项目记录的时间戳
  static Future<void> _updateItemRecord(ClipItem item) async {
    try {
      final database = DatabaseService.instance;
      await database.updateClipItem(item);

      await Log.d(
        'Updated item record timestamp',
        tag: 'ClipItemUtil',
        fields: {
          'itemId': item.id,
          'itemType': item.type.name,
        },
      );
    } on Exception catch (e) {
      await Log.e(
        'Failed to update item record',
        tag: 'ClipItemUtil',
        error: e,
      );
    }
  }

  /// 更新OCR文本记录的时间戳
  static Future<ClipItem?> _updateOcrTextRecord(ClipItem imageItem) async {
    try {
      final database = DatabaseService.instance;

      // 获取OCR文本记录
      final ocrRecord = await database.getClipItemById(imageItem.ocrTextId!);
      if (ocrRecord != null) {
        // 更新OCR文本记录的访问时间戳
        // 保持createdAt不变，只更新updatedAt
        final updatedOcrRecord = ocrRecord.copyWith(
          updatedAt: DateTime.now(),
          // ✅ 不修改createdAt，保持原始创建时间
        );
        await database.updateClipItem(updatedOcrRecord);

        await Log.d(
          'Updated OCR text record timestamp',
          tag: 'ClipItemUtil',
          fields: {
            'ocrTextId': imageItem.ocrTextId,
            'imageId': imageItem.id,
          },
        );
        return updatedOcrRecord;
      }
    } on Exception catch (e) {
      await Log.e(
        'Failed to update OCR text record',
        tag: 'ClipItemUtil',
        error: e,
      );
      // 不阻止复制操作，只记录错误
    }
    return null;
  }

  /// 显示OCR错误消息
  static void _showOcrErrorMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $message'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 显示错误消息
  static void _showErrorMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
