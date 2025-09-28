import 'dart:typed_data';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/dimensions.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/strings.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/i18n_common_util.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 剪贴项卡片组件
class ClipItemCard extends StatelessWidget {
  /// 剪贴项卡片组件
  const ClipItemCard({
    required this.item,
    required this.displayMode,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
    super.key,
    this.searchQuery,
  });

  /// 剪贴项
  final ClipItem item;

  /// 显示模式
  final DisplayMode displayMode;

  /// 点击回调
  final VoidCallback onTap;

  /// 收藏回调
  final VoidCallback onFavorite;

  /// 删除回调
  final VoidCallback onDelete;

  /// 搜索关键词
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        child: SizedBox(
          height: _getFixedCardHeight(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：类型图标和操作按钮
                Row(
                  children: [
                    _buildTypeIcon(),
                    const SizedBox(width: Spacing.s12),
                    Expanded(child: _buildTypeLabel()),
                    _buildActionButtons(context),
                  ],
                ),

                const SizedBox(height: Spacing.s12),

                // 内容预览 - 可滑动区域
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildContentPreview(context),
                  ),
                ),

                // 底部：时间和标签
                const SizedBox(height: Spacing.s8),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取固定的卡片高度
  double _getFixedCardHeight() {
    switch (displayMode) {
      case DisplayMode.compact:
        return 140; // 紧凑模式固定高度
      case DisplayMode.normal:
        return 180; // 正常模式固定高度
      case DisplayMode.preview:
        return 160; // 预览模式固定高度
    }
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case ClipType.text:
        iconData = Icons.text_fields;
        iconColor = Color(AppColors.iconColors['blue']!);
      case ClipType.rtf:
      case ClipType.html:
        iconData = Icons.description;
        iconColor = Color(AppColors.iconColors['green']!);
      case ClipType.image:
        iconData = Icons.image;
        iconColor = Color(AppColors.iconColors['purple']!);
      case ClipType.color:
        iconData = Icons.palette;
        iconColor = Color(AppColors.iconColors['orange']!);
      case ClipType.file:
        iconData = Icons.insert_drive_file;
        iconColor = Color(AppColors.iconColors['grey']!);
      case ClipType.audio:
        iconData = Icons.audiotrack;
        iconColor = Color(AppColors.iconColors['red']!);
      case ClipType.video:
        iconData = Icons.videocam;
        iconColor = Color(AppColors.iconColors['pink']!);
      case ClipType.url:
        iconData = Icons.link;
        iconColor = Color(AppColors.iconColors['blue']!);
      case ClipType.email:
        iconData = Icons.email;
        iconColor = Color(AppColors.iconColors['green']!);
      case ClipType.json:
        iconData = Icons.data_object;
        iconColor = Color(AppColors.iconColors['orange']!);
      case ClipType.xml:
        iconData = Icons.code;
        iconColor = Color(AppColors.iconColors['purple']!);
      case ClipType.code:
        iconData = Icons.terminal;
        iconColor = Color(AppColors.iconColors['grey']!);
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  Widget _buildTypeLabel() {
    return Builder(
      builder: (context) {
        String label;

        switch (item.type) {
          case ClipType.text:
            label = I18nCommonUtil.getClipTypeText(context);
          case ClipType.rtf:
            label = I18nCommonUtil.getClipTypeRichText(context);
          case ClipType.html:
            label = I18nCommonUtil.getClipTypeHtml(context);
          case ClipType.image:
            label = I18nCommonUtil.getClipTypeImage(context);
          case ClipType.color:
            label = I18nCommonUtil.getClipTypeColor(context);
          case ClipType.file:
            label = I18nCommonUtil.getClipTypeFile(context);
          case ClipType.audio:
            label = I18nCommonUtil.getClipTypeAudio(context);
          case ClipType.video:
            label = I18nCommonUtil.getClipTypeVideo(context);
          case ClipType.url:
            label = 'URL';
          case ClipType.email:
            label = 'Email';
          case ClipType.json:
            label = 'JSON';
          case ClipType.xml:
            label = 'XML';
          case ClipType.code:
            label = 'Code';
        }

        return Text(
          label,
          style: const TextStyle(
            fontSize: ClipConstants.captionFontSize,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onFavorite,
          icon: Icon(
            item.isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 18,
          ),
          iconSize: 18,
          style: IconButton.styleFrom(
            backgroundColor: item.isFavorite
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: item.isFavorite
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurfaceVariant,
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: Spacing.s8),
        IconButton.outlined(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          iconSize: 18,
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildContentPreview(BuildContext context) {
    switch (item.type) {
      case ClipType.color:
        return _buildColorPreview();
      case ClipType.image:
        return _buildImagePreview();
      case ClipType.file:
        return _buildFilePreview();
      case ClipType.text:
      case ClipType.rtf:
      case ClipType.html:
      case ClipType.audio:
      case ClipType.video:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.code:
        return _buildTextPreview(context);
    }
  }

  Widget _buildColorPreview() {
    final colorHex =
        item.metadata[AppStrings.metaColorHex] as String? ??
        AppColors.defaultColorHex;
    final colorName = ColorUtils.getColorName(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: Dimensions.searchBarHeight,
          decoration: BoxDecoration(
            color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
            border: Border.all(color: const Color(AppColors.grey300)),
          ),
        ),
        const SizedBox(height: ClipConstants.smallPadding),
        Text(
          colorHex,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          colorName,
          style: const TextStyle(
            fontSize: ClipConstants.captionFontSize,
            color: Color(AppColors.grey600),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
            borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
          ),
          child: item.thumbnail != null && item.thumbnail!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ClipConstants.cardBorderRadius,
                  ),
                  child: Image.memory(
                    Uint8List.fromList(item.thumbnail!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 32,
                          color: theme.colorScheme.outline,
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.image,
                    size: 32,
                    color: theme.colorScheme.outline,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFilePreview() {
    final fileName =
        item.metadata[AppStrings.metaFileName] as String? ??
        AppStrings.unknownFile;
    final fileSize = item.metadata['fileSize'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.insert_drive_file, size: 32),
        const SizedBox(height: ClipConstants.smallPadding),
        Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _formatFileSize(fileSize),
          style: TextStyle(
            fontSize: ClipConstants.captionFontSize,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextPreview(BuildContext context) {
    final content = item.content ?? '';
    final wordCount = item.metadata['wordCount'] as int? ?? 0;
    final lineCount = item.metadata['lineCount'] as int? ?? 0;

    final isMonospace =
        item.type == ClipType.code ||
        item.type == ClipType.json ||
        item.type == ClipType.xml;
    final shouldPreserveWhitespace =
        item.type == ClipType.code ||
        item.type == ClipType.html ||
        item.type == ClipType.rtf;

    final baseStyle =
        (isMonospace
            ? const TextStyle(fontFamily: 'monospace')
            : Theme.of(context).textTheme.bodyMedium) ??
        const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 文本内容 - 保留缩进和空白（对于 code/html/rtf），并使用等宽字体渲染代码
        if (shouldPreserveWhitespace)
          RichText(
            text: TextSpan(
              text: content,
              style: baseStyle.copyWith(height: 1.4),
            ),
            textScaler: MediaQuery.of(context).textScaler,
            softWrap: false,
          )
        else
          Text(
            content,
            style: baseStyle,
          ),
        const SizedBox(height: Spacing.s8),
        Row(
          children: [
            Text(
              '$wordCount ${AppStrings.unitWords}',
              style: const TextStyle(
                fontSize: ClipConstants.captionFontSize,
                color: Color(AppColors.grey600),
              ),
            ),
            if (lineCount > 1) ...[
              const SizedBox(width: ClipConstants.smallPadding),
              Text(
                '$lineCount ${AppStrings.unitLines}',
                style: const TextStyle(
                  fontSize: ClipConstants.captionFontSize,
                  color: Color(AppColors.grey600),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final tags = item.metadata['tags'] as List<dynamic>? ?? [];
    final timeAgo = _getTimeAgo(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeAgo,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: ClipConstants.smallPadding / 2),
          Wrap(
            spacing: ClipConstants.smallPadding / 2,
            children: tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(AppColors.blue100),
                  borderRadius: BorderRadius.circular(
                    ClipConstants.smallPadding / 2,
                  ),
                ),
                child: Text(
                  tag.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: Dimensions.fontSizeXSmall,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} ${AppStrings.unitKB}';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${AppStrings.unitMB}';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ${AppStrings.unitGB}';
  }

  String _getTimeAgo(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(item.createdAt);

    if (difference.inMinutes < 1) {
      return I18nCommonUtil.getTimeJustNow(context);
    } else if (difference.inMinutes < 60) {
      return I18nCommonUtil.getTimeMinutesAgo(context, difference.inMinutes);
    } else if (difference.inHours < 24) {
      return I18nCommonUtil.getTimeHoursAgo(context, difference.inHours);
    } else if (difference.inDays < 7) {
      return I18nCommonUtil.getTimeDaysAgo(context, difference.inDays);
    } else {
      return DateFormat(AppStrings.timeFormatDefault).format(item.createdAt);
    }
  }
}

/// 可展开的文本组件，支持长文本滚动展示
class ExpandableTextWidget extends StatefulWidget {
  /// 构造函数
  const ExpandableTextWidget({
    required this.text,
    required this.maxLines,
    super.key,
    this.searchQuery,
    this.style,
  });

  /// 文本内容
  final String text;

  /// 最大行数
  final int maxLines;

  /// 搜索关键词
  final String? searchQuery;

  /// 文本样式
  final TextStyle? style;

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用实际可用宽度进行溢出计算
        final availableWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 64;

        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: availableWidth);
        textPainter.dispose();

        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    // 简化为直接显示文本，依赖外部的 SingleChildScrollView 来处理滑动
    return _buildText(null);
  }

  Widget _buildText(int? maxLines) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return Text(
        widget.text,
        maxLines: maxLines,
        overflow: maxLines != null
            ? TextOverflow.ellipsis
            : TextOverflow.visible,
        style: widget.style,
        softWrap: true,
      );
    }

    // 执行搜索高亮
    if (!_isQueryMatch(widget.text, widget.searchQuery!)) {
      return Text(
        widget.text,
        maxLines: maxLines,
        overflow: maxLines != null
            ? TextOverflow.ellipsis
            : TextOverflow.visible,
        style: widget.style,
        softWrap: true,
      );
    }

    final spans = _buildHighlightedSpans(
      context,
      widget.text,
      widget.searchQuery!,
    );

    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
      text: TextSpan(children: spans),
    );
  }

  /// 检查查询是否匹配文本
  bool _isQueryMatch(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  /// 构建高亮文本片段
  List<TextSpan> _buildHighlightedSpans(
    BuildContext context,
    String text,
    String query,
  ) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    var start = 0;
    var index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // 添加匹配前的普通文本
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: widget.style,
          ),
        );
      }

      // 添加高亮的匹配文本
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style:
              widget.style?.copyWith(
                backgroundColor: Colors.yellow.withAlpha(100),
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                backgroundColor: Colors.yellow.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // 添加剩余的普通文本
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: widget.style,
        ),
      );
    }

    return spans;
  }
}
