import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:flutter/material.dart';
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

/// 剪贴板项目图标工具类
class ClipItemIconUtil {
  /// 私有构造：禁止实例化
  ClipItemIconUtil._();

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
}
