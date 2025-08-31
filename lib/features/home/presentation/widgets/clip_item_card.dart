import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/constants/clip_constants.dart';

class ClipItemCard extends StatelessWidget {
  final ClipItem item;
  final DisplayMode displayMode;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final String? searchQuery;

  const ClipItemCard({
    super.key,
    required this.item,
    required this.displayMode,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：类型图标和操作按钮
                Row(
                  children: [
                    _buildTypeIcon(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTypeLabel()),
                    _buildActionButtons(context),
                  ],
                ),

                const SizedBox(height: 12),

                // 内容预览
                Expanded(child: _buildContentPreview(context)),

                // 底部：时间和标签
                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case ClipType.text:
        iconData = Icons.text_fields;
        iconColor = Colors.blue;
        break;
      case ClipType.rtf:
      case ClipType.html:
        iconData = Icons.description;
        iconColor = Colors.green;
        break;
      case ClipType.image:
        iconData = Icons.image;
        iconColor = Colors.purple;
        break;
      case ClipType.color:
        iconData = Icons.palette;
        iconColor = Colors.orange;
        break;
      case ClipType.file:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
        break;
      case ClipType.audio:
        iconData = Icons.audiotrack;
        iconColor = Colors.red;
        break;
      case ClipType.video:
        iconData = Icons.videocam;
        iconColor = Colors.pink;
        break;
    }

    return Icon(iconData, size: 16, color: iconColor);
  }

  Widget _buildTypeLabel() {
    String label;

    switch (item.type) {
      case ClipType.text:
        label = '文本';
        break;
      case ClipType.rtf:
        label = '富文本';
        break;
      case ClipType.html:
        label = 'HTML';
        break;
      case ClipType.image:
        label = '图片';
        break;
      case ClipType.color:
        label = '颜色';
        break;
      case ClipType.file:
        label = '文件';
        break;
      case ClipType.audio:
        label = '音频';
        break;
      case ClipType.video:
        label = '视频';
        break;
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: ClipConstants.captionFontSize,
        fontWeight: FontWeight.w500,
      ),
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
        const SizedBox(width: 8),
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
      default:
        return _buildTextPreview(context);
    }
  }

  Widget _buildColorPreview() {
    final colorHex = item.metadata['colorHex'] as String? ?? '#000000';
    final colorName = ColorUtils.getColorName(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
            border: Border.all(color: Colors.grey.shade300),
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
          style: TextStyle(
            fontSize: ClipConstants.captionFontSize,
            color: Colors.grey.shade600,
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
    final fileName = item.metadata['fileName'] as String? ?? '未知文件';
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
    final content = String.fromCharCodes(item.content);
    final wordCount = item.metadata['wordCount'] as int? ?? 0;
    final lineCount = item.metadata['lineCount'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: _buildHighlightedText(
            context,
            content,
            maxLines: displayMode == DisplayMode.compact ? 3 : 5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$wordCount 字',
              style: TextStyle(
                fontSize: ClipConstants.captionFontSize,
                color: Colors.grey.shade600,
              ),
            ),
            if (lineCount > 1) ...[
              const SizedBox(width: ClipConstants.smallPadding),
              Text(
                '$lineCount 行',
                style: TextStyle(
                  fontSize: ClipConstants.captionFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text, {
    required int maxLines,
  }) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
        softWrap: true,
      );
    }

    final query = searchQuery!.toLowerCase().trim();
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
        softWrap: true,
      );
    }

    // 按行分割文本，在每行内进行匹配，避免跨行高亮
    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lowerLine = line.toLowerCase();

      // 在当前行内查找匹配
      final lineSpans = <TextSpan>[];
      int lastEnd = 0;

      // 简单的字符串匹配，避免复杂的正则表达式
      int searchIndex = 0;
      while (searchIndex < lowerLine.length) {
        final matchIndex = lowerLine.indexOf(query, searchIndex);
        if (matchIndex == -1) break;

        // 检查是否是完整的词汇（简单版本）
        bool isValidMatch = true;

        // 检查前一个字符
        if (matchIndex > 0) {
          final prevChar = lowerLine[matchIndex - 1];
          if (RegExp(r'[a-zA-Z0-9\u4e00-\u9fa5]').hasMatch(prevChar)) {
            isValidMatch = false;
          }
        }

        // 检查后一个字符
        if (isValidMatch && matchIndex + query.length < lowerLine.length) {
          final nextChar = lowerLine[matchIndex + query.length];
          if (RegExp(r'[a-zA-Z0-9\u4e00-\u9fa5]').hasMatch(nextChar)) {
            isValidMatch = false;
          }
        }

        if (isValidMatch) {
          // 添加匹配前的文本
          if (matchIndex > lastEnd) {
            lineSpans.add(
              TextSpan(
                text: line.substring(lastEnd, matchIndex),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          // 添加高亮文本
          lineSpans.add(
            TextSpan(
              text: line.substring(matchIndex, matchIndex + query.length),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          );

          lastEnd = matchIndex + query.length;
          searchIndex = lastEnd;
        } else {
          searchIndex = matchIndex + 1;
        }
      }

      // 添加行内剩余文本
      if (lastEnd < line.length) {
        lineSpans.add(
          TextSpan(
            text: line.substring(lastEnd),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      // 如果没有匹配，添加整行
      if (lineSpans.isEmpty) {
        lineSpans.add(
          TextSpan(text: line, style: Theme.of(context).textTheme.bodyMedium),
        );
      }

      // 添加当前行的所有spans
      spans.addAll(lineSpans);

      // 如果不是最后一行，添加换行符
      if (lineIndex < lines.length - 1) {
        spans.add(
          TextSpan(text: '\n', style: Theme.of(context).textTheme.bodyMedium),
        );
      }
    }

    // 如果没有匹配项，返回原始文本
    if (spans.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
        softWrap: true,
      );
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final tags = item.metadata['tags'] as List<dynamic>? ?? [];
    final timeAgo = _getTimeAgo();

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
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(
                    ClipConstants.smallPadding / 2,
                  ),
                ),
                child: Text(
                  tag.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
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
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(item.createdAt);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(item.createdAt);
    }
  }
}
