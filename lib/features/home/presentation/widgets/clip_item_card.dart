import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/utils/color_utils.dart';

class ClipItemCard extends StatelessWidget {
  final ClipItem item;
  final DisplayMode displayMode;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const ClipItemCard({
    super.key,
    required this.item,
    required this.displayMode,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：类型图标和操作按钮
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeLabel(),
                  ),
                  _buildActionButtons(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 内容预览
              Expanded(
                child: _buildContentPreview(),
              ),
              
              // 底部：时间和标签
              const SizedBox(height: 8),
              _buildFooter(),
            ],
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
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onFavorite,
          icon: Icon(
            item.isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: item.isFavorite ? Colors.red : null,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildContentPreview() {
    switch (item.type) {
      case ClipType.color:
        return _buildColorPreview();
      case ClipType.image:
        return _buildImagePreview();
      case ClipType.file:
        return _buildFilePreview();
      default:
        return _buildTextPreview();
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          colorHex,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          colorName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 32, color: Colors.grey),
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = item.metadata['fileName'] as String? ?? '未知文件';
    final fileSize = item.metadata['fileSize'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.insert_drive_file, size: 32),
        const SizedBox(height: 8),
        Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _formatFileSize(fileSize),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextPreview() {
    final content = String.fromCharCodes(item.content);
    final wordCount = item.metadata['wordCount'] as int? ?? 0;
    final lineCount = item.metadata['lineCount'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          maxLines: displayMode == DisplayMode.compact ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              '$wordCount 字',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (lineCount > 1) ...[
              const SizedBox(width: 8),
              Text(
                '$lineCount 行',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final tags = item.metadata['tags'] as List<dynamic>? ?? [];
    final timeAgo = _getTimeAgo();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeAgo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
