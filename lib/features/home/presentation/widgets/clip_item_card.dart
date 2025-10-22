import 'dart:io';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/dimensions.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/constants/strings.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/i18n_common_util.dart';
import 'package:clip_flow_pro/core/utils/image_utils.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
            ClipConstants.cardBorderRadius,
          ),
          child: InkWell(
            onTap: () {}, // 外层点击不触发复制，由内容区域处理
            borderRadius: BorderRadius.circular(
              ClipConstants.cardBorderRadius,
            ),
            splashColor: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            highlightColor: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.05,
            ),
            child: SizedBox(
              // 使用动态高度而非固定高度
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(_contentPadding()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 头部：类型图标和操作按钮
                      _buildHeader(context),

                      const SizedBox(height: Spacing.s12),

                      // 内容预览 - 可滑动区域（仅内容区域可点击触发复制）
                      Expanded(
                        child: _buildContentArea(context),
                      ),

                      // 底部：时间和标签
                      const SizedBox(height: Spacing.s8),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _textViewportHeight() {
    switch (displayMode) {
      case DisplayMode.compact:
        return 120;
      case DisplayMode.normal:
        return 140;
      case DisplayMode.preview:
        return 160;
    }
  }

  /// 最小文本视口高度
  double _minTextViewportHeight() {
    switch (displayMode) {
      case DisplayMode.compact:
        return 60;
      case DisplayMode.normal:
        return 80;
      case DisplayMode.preview:
        return 100;
    }
  }

  /// 构建卡片头部
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: Spacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeLabel(),
              const SizedBox(height: 2),
              _buildContentPriority(),
            ],
          ),
        ),
        const SizedBox(width: Spacing.s8),
        _buildActionButtons(context),
      ],
    );
  }

  /// 构建内容优先级指示器
  Widget _buildContentPriority() {
    switch (item.type) {
      case ClipType.image:
        return _buildPriorityBadge('图片', const Color(0xFFE1BEE7)); // purple100
      case ClipType.file:
        return _buildPriorityBadge('文件', const Color(0xFFEEEEEE)); // grey100
      case ClipType.color:
        return _buildPriorityBadge('颜色', const Color(0xFFFFE0B2)); // orange100
      case ClipType.url:
        return _buildPriorityBadge('链接', const Color(0xFFBBDEFB)); // blue100
      case ClipType.code:
        return _buildPriorityBadge('代码', const Color(0xFFC8E6C9)); // green100
      case ClipType.text:
        return _buildPriorityBadge('文本', const Color(0xFFE1F5FE)); // light blue
      case ClipType.rtf:
      case ClipType.html:
        return _buildPriorityBadge('富文本', const Color(0xFFF0F4C3)); // lime100
      case ClipType.audio:
      case ClipType.video:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
        return const SizedBox.shrink();
    }
  }

  /// 构建优先级徽章
  Widget _buildPriorityBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF424242), // grey800
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据内容类型和可用空间调整布局
        return _buildContentPreview(context);
      },
    );
  }

  // 不同显示模式下的内容内边距，提升层次与紧凑度
  double _contentPadding() {
    switch (displayMode) {
      case DisplayMode.compact:
        return 12;
      case DisplayMode.normal:
        return 16;
      case DisplayMode.preview:
        return 14;
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: IconButton.filledTonal(
            onPressed: onFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(item.isFavorite),
                size: 18,
              ),
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
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.2),
            ),
            tooltip: item.isFavorite ? '取消收藏' : '收藏',
          ),
        ),
        const SizedBox(width: Spacing.s8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: IconButton.outlined(
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
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
            ),
            tooltip: '删除',
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
        // 颜色预览区域
        Container(
          width: double.infinity,
          height: Dimensions.searchBarHeight,
          decoration: BoxDecoration(
            color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
            border: Border.all(
              color: const Color(AppColors.grey300),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClipConstants.smallPadding),
        
        // 颜色信息区域
        Container(
          padding: const EdgeInsets.all(Spacing.s8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA), // grey50
            borderRadius: BorderRadius.circular(
              ClipConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: const Color(0xFFEEEEEE), // grey100
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                colorHex,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
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
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final rawPath = item.filePath;
        final isImageCandidate =
            rawPath != null &&
            rawPath.isNotEmpty &&
            ImageUtils.isImageFile(rawPath);
        final wantOriginal =
            displayMode == DisplayMode.preview && isImageCandidate;

        Widget buildThumbFallback() {
          return (item.thumbnail != null && item.thumbnail!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ClipConstants.cardBorderRadius,
                  ),
                  child: Image.memory(
                    Uint8List.fromList(item.thumbnail!),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    frameBuilder: (
                      context,
                      child,
                      frame,
                      wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImageErrorPlaceholder(theme);
                    },
                  ),
                )
              : _buildImagePlaceholder(theme);
        }

        Widget buildImageWidget() {
          return wantOriginal
              ? FutureBuilder<String?>(
                  future: _resolveAbsoluteImagePath(rawPath),
                  builder: (context, snapshot) {
                    final abs = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingPlaceholder(theme);
                    }
                    if (abs == null) {
                      return buildThumbFallback();
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ClipConstants.cardBorderRadius,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Image.file(
                              File(abs),
                              width: constraints.maxWidth,
                              fit: BoxFit.fitWidth,
                              filterQuality: FilterQuality.high,
                              cacheWidth: 1024,
                              frameBuilder: (
                                context,
                                child,
                                frame,
                                wasSynchronouslyLoaded,
                              ) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return buildThumbFallback();
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : buildThumbFallback();
        }

        // 构建包含OCR文本的完整预览
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片预览
            buildImageWidget(),

            // OCR文本显示
            if (item.ocrText != null && item.ocrText!.isNotEmpty) ...[
              const SizedBox(height: Spacing.s8),
              _buildOcrTextPreview(context),
            ],
          ],
        );
      },
    );
  }

  /// 构建图片错误占位符
  Widget _buildImageErrorPlaceholder(ThemeData theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(
          ClipConstants.cardBorderRadius,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              '图片加载失败',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片占位符
  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(
          ClipConstants.cardBorderRadius,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 32,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  /// 构建加载占位符
  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(
          ClipConstants.cardBorderRadius,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Future<String?> _resolveAbsoluteImagePath(String relativeOrAbsolute) async {
    try {
      // 已是绝对路径
      final isAbsolute =
          relativeOrAbsolute.startsWith('/') ||
          RegExp('^[A-Za-z]:').hasMatch(relativeOrAbsolute);
      if (isAbsolute) {
        final file = File(relativeOrAbsolute);
        if (file.existsSync()) return relativeOrAbsolute;
        return null;
      }
      final dir = await PathService.instance.getDocumentsDirectory();
      final abs = p.join(dir.path, relativeOrAbsolute);
      final file = File(abs);
      if (file.existsSync()) return abs;
      return null;
    } on Exception catch (_) {
      return null;
    }
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

    // 智能截断内容
    final truncatedContent = _getSmartTruncatedContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 动态高度的文本内容
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _textViewportHeight(),
            minHeight: _minTextViewportHeight(),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: shouldPreserveWhitespace
                // 等宽 + 保留空白的文本，支持横向滚动避免超长行溢出
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: _buildHighlightedText(
                      context,
                      truncatedContent,
                      baseStyle.copyWith(height: 1.4),
                      preserveWhitespace: true,
                    ),
                  )
                : _buildHighlightedText(
                    context,
                    truncatedContent,
                    baseStyle,
                    preserveWhitespace: false,
                  ),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        _buildContentStats(wordCount, lineCount),
      ],
    );
  }

  

  /// 智能截断内容
  String _getSmartTruncatedContent(String content) {
    if (content.length <= 500) return content;

    // 根据显示模式调整截断长度
    final maxLength = switch (displayMode) {
      DisplayMode.compact => 200,
      DisplayMode.normal => 350,
      DisplayMode.preview => 500,
    };

    // 尝试在单词边界截断
    if (content.length > maxLength) {
      final truncated = content.substring(0, maxLength);
      final lastSpaceIndex = truncated.lastIndexOf(' ');
      final lastNewlineIndex = truncated.lastIndexOf('\n');
      
      var cutIndex = maxLength;
      if (lastSpaceIndex > maxLength - 50) {
        cutIndex = lastSpaceIndex;
      } else if (lastNewlineIndex > maxLength - 50) {
        cutIndex = lastNewlineIndex;
      }

      return '${content.substring(0, cutIndex)}...';
    }
    
    return content;
  }

  /// 构建内容统计信息
  Widget _buildContentStats(int wordCount, int lineCount) {
    return Row(
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
        if (item.content != null && item.content!.length > 500) ...[
          const SizedBox(width: ClipConstants.smallPadding),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: const Color(AppColors.blue100),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Builder(
              builder: (context) {
                return Text(
                  '已截断',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    TextStyle style, {
    required bool preserveWhitespace,
  }) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return preserveWhitespace
          ? RichText(
              text: TextSpan(
                text: text,
                style: style,
              ),
              textScaler: MediaQuery.of(context).textScaler,
              softWrap: false,
            )
          : Text(
              text,
              style: style,
            );
    }

    // 检查是否匹配搜索查询
    if (!text.toLowerCase().contains(searchQuery!.toLowerCase())) {
      return preserveWhitespace
          ? RichText(
              text: TextSpan(
                text: text,
                style: style,
              ),
              textScaler: MediaQuery.of(context).textScaler,
              softWrap: false,
            )
          : Text(
              text,
              style: style,
            );
    }

    // 构建高亮文本
    final spans = _buildHighlightedSpans(
      context,
      text,
      searchQuery!,
      style,
    );

    return RichText(
      text: TextSpan(children: spans),
      textScaler: MediaQuery.of(context).textScaler,
      softWrap: !preserveWhitespace,
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
      final mbValue = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mbValue ${AppStrings.unitMB}';
    }
    final gbValue = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    return '$gbValue ${AppStrings.unitGB}';
  }

  /// 构建OCR文本预览组件
  Widget _buildOcrTextPreview(BuildContext context) {
    final ocrText = item.ocrText ?? '';
    if (ocrText.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final ocrConfidence = item.metadata['ocrConfidence'] as double?;

    return Container(
      padding: const EdgeInsets.all(Spacing.s12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OCR标题和置信度
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.s4),
              Text(
                'OCR识别文本',
                style: TextStyle(
                  fontSize: ClipConstants.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (ocrConfidence != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.s4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(ocrConfidence).withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(ocrConfidence * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getConfidenceColor(ocrConfidence),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.s4),

          // OCR文本内容
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 80),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _buildOcrTextContent(context, ocrText),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建OCR文本内容，支持搜索高亮
  Widget _buildOcrTextContent(BuildContext context, String ocrText) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: ClipConstants.captionFontSize,
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.3,
    );

    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(ocrText, style: textStyle);
    }

    // 检查是否匹配搜索查询
    if (!ocrText.toLowerCase().contains(searchQuery!.toLowerCase())) {
      return Text(ocrText, style: textStyle);
    }

    // 构建高亮文本
    final spans = _buildHighlightedSpans(
      context,
      ocrText,
      searchQuery!,
      textStyle,
    );
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// 构建高亮文本片段（用于OCR文本）
  List<TextSpan> _buildHighlightedSpans(
    BuildContext context,
    String text,
    String query,
    TextStyle baseStyle,
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
            style: baseStyle,
          ),
        );
      }

      // 添加高亮的匹配文本
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFFEB3B).withAlpha(77),
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
          style: baseStyle,
        ),
      );
    }

    return spans;
  }

  /// 根据置信度获取颜色
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return const Color(0xFF4CAF50); // 绿色 - 高置信度
    } else if (confidence >= 0.6) {
      return const Color(0xFFFF9800); // 橙色 - 中等置信度
    } else {
      return const Color(0xFFF44336); // 红色 - 低置信度
    }
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

        // 使用 TextPainter 进行布局计算，然后立即释放资源
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: availableWidth);
        // ignore: cascade_invocations - dispose() 必须在 layout() 之后单独调用，不能使用级联操作符
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
                backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.3),
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
