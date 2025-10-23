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
    return Semantics(
      label: _getSemanticLabel(),
      hint: '点击复制内容，长按显示更多选项',
      button: true,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => onTap(),
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ClipConstants.cardBorderRadius,
              ),
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
                onTap: onTap,
                borderRadius: BorderRadius.circular(
                  ClipConstants.cardBorderRadius,
                ),
                splashColor: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                highlightColor: Theme.of(context).colorScheme.primary
                    .withValues(
                      alpha: 0.05,
                    ),
                child: SizedBox(
                  // 使用Flexible而不是IntrinsicHeight来避免溢出
                  child: ClipRect(
                    child: Padding(
                      padding: EdgeInsets.all(_contentPadding()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 头部：类型图标和操作按钮
                          _buildHeader(context),

                          const SizedBox(height: Spacing.s12),

                          // 内容预览 - 使用Flexible防止溢出
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: _getMaxContentHeight(context),
                              ),
                              child: _buildContentArea(context),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取最大内容高度，防止溢出
  double _getMaxContentHeight(BuildContext context) {
    switch (displayMode) {
      case DisplayMode.compact:
        return 150; // 增加紧凑模式内容高度
      case DisplayMode.normal:
        return 200; // 增加正常模式内容高度
      case DisplayMode.preview:
        return 250; // 增加预览模式内容高度
    }
  }

  /// 获取语义化标签
  String _getSemanticLabel() {
    final typeLabel = _getTypeLabel();
    final contentPreview = _getContentPreview();
    final timeAgo = _getTimeAgoLabel();

    return '$typeLabel：$contentPreview，$timeAgo${item.isFavorite ? '，已收藏' : ''}';
  }

  /// 获取类型标签
  String _getTypeLabel() {
    switch (item.type) {
      case ClipType.text:
        return '文本';
      case ClipType.rtf:
        return '富文本';
      case ClipType.html:
        return 'HTML';
      case ClipType.image:
        return '图片';
      case ClipType.color:
        return '颜色';
      case ClipType.file:
        return '文件';
      case ClipType.audio:
        return '音频';
      case ClipType.video:
        return '视频';
      case ClipType.url:
        return '链接';
      case ClipType.email:
        return '邮箱';
      case ClipType.json:
        return 'JSON';
      case ClipType.xml:
        return 'XML';
      case ClipType.code:
        return '代码';
    }
  }

  /// 获取内容预览
  String _getContentPreview() {
    switch (item.type) {
      case ClipType.image:
        final width = item.metadata['width'] as int? ?? 0;
        final height = item.metadata['height'] as int? ?? 0;
        return '图片 ${width}x$height';
      case ClipType.file:
        final fileName = item.metadata['fileName'] as String? ?? '未知文件';
        return fileName;
      case ClipType.color:
        final colorHex = item.metadata['colorHex'] as String? ?? '#000000';
        return '颜色 $colorHex';
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
        final content = item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }

  /// 获取时间标签
  String _getTimeAgoLabel() {
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
      return DateFormat('yyyy-MM-dd').format(item.createdAt);
    }
  }

  /// 构建卡片头部
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: Spacing.s12),
        Expanded(child: _buildTypeLabel()),
        _buildActionButtons(context),
      ],
    );
  }

  // 收藏功能已移除

  /// 处理删除操作，包含反馈效果
  void _handleDeleteWithFeedback(BuildContext context) {
    // 触觉反馈
    HapticFeedback.mediumImpact();

    // 显示确认对话框
    _showDeleteConfirmation(context);
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这个${_getTypeLabel()}吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
              _showFloatingFeedback(
                context,
                '已删除',
                Icons.delete,
                isError: true,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示浮动反馈提示
  void _showFloatingFeedback(
    BuildContext context,
    String message,
    IconData icon, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: MediaQuery.of(context).size.width / 2 - 75,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: isError
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // 3秒后自动移除
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight,
            ),
            child: _buildContentPreview(context),
          );
        },
      ),
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
          child: Semantics(
            label: '删除',
            button: true,
            child: IconButton.outlined(
              onPressed: () => _handleDeleteWithFeedback(context),
              icon: const Icon(
                Icons.delete_outline,
                semanticLabel: '删除',
              ),
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
                    gaplessPlayback: true,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
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
                              cacheWidth: 512, // 降低缓存尺寸以节省内存
                              frameBuilder:
                                  (
                                    context,
                                    child,
                                    frame,
                                    wasSynchronouslyLoaded,
                                  ) {
                                    if (wasSynchronouslyLoaded) return child;
                                    return AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
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
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 图片预览 - 直接使用，不要复杂约束
            SizedBox(
              height: 200, // 固定高度确保图片显示
              child: ClipRect(
                child: buildImageWidget(),
              ),
            ),

            // OCR文本显示 - 简化处理
            if (item.ocrText != null && item.ocrText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60, // 固定高度，避免溢出
                child: _buildOcrTextPreview(context),
              ),
            ],
          ],
        );
      },
    );
  }

  /// 构建图片错误占位符
  Widget _buildImageErrorPlaceholder(ThemeData theme) {
    // 根据显示模式调整占位符高度
    final placeholderHeight = switch (displayMode) {
      DisplayMode.compact => 100,
      DisplayMode.normal => 150,
      DisplayMode.preview => 200,
    };

    return Container(
      height: placeholderHeight.toDouble(),
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
    // 根据显示模式调整占位符高度
    final placeholderHeight = switch (displayMode) {
      DisplayMode.compact => 100,
      DisplayMode.normal => 150,
      DisplayMode.preview => 200,
    };

    return Container(
      height: placeholderHeight.toDouble(),
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
    // 根据显示模式调整占位符高度
    final placeholderHeight = switch (displayMode) {
      DisplayMode.compact => 100,
      DisplayMode.normal => 150,
      DisplayMode.preview => 200,
    };

    return Container(
      height: placeholderHeight.toDouble(),
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

    // 重新计算准确的字数统计
    final wordCount = _calculateWordCount(content);
    final charCount = content.length;
    final lineCount = content.split('\n').length;

    final isMonospace =
        item.type == ClipType.code ||
        item.type == ClipType.json ||
        item.type == ClipType.xml;
    final shouldPreserveWhitespace =
        item.type == ClipType.code ||
        item.type == ClipType.html ||
        item.type == ClipType.rtf;

    final theme = Theme.of(context);
    final baseStyle =
        (isMonospace
            ? const TextStyle(fontFamily: 'monospace')
            : theme.textTheme.bodyMedium) ??
        const TextStyle();

    // 确保文本颜色有足够的对比度
    final textStyle = baseStyle.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
      fontSize: baseStyle.fontSize ?? 14,
      height: 1.4,
    );

    // 智能截断内容
    final truncatedContent = _getSmartTruncatedContent(content);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 使用Flexible而不是固定高度，防止溢出
            Flexible(
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
                          textStyle,
                          preserveWhitespace: true,
                        ),
                      )
                    : _buildHighlightedText(
                        context,
                        truncatedContent,
                        textStyle,
                        preserveWhitespace: false,
                      ),
              ),
            ),
            const SizedBox(height: Spacing.s8),
            _buildContentStats(charCount, wordCount, lineCount),
          ],
        );
      },
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
  Widget _buildContentStats(int charCount, int wordCount, int lineCount) {
    return Row(
      children: [
        Text(
          '$charCount 字符',
          style: const TextStyle(
            fontSize: ClipConstants.captionFontSize,
            color: Color(AppColors.grey600),
          ),
        ),
        if (wordCount > 0) ...[
          const SizedBox(width: ClipConstants.smallPadding),
          Text(
            '$wordCount 词',
            style: const TextStyle(
              fontSize: ClipConstants.captionFontSize,
              color: Color(AppColors.grey600),
            ),
          ),
        ],
        if (lineCount > 1) ...[
          const SizedBox(width: ClipConstants.smallPadding),
          Text(
            '$lineCount 行',
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间显示区域
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 添加绝对时间提示
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.help,
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (tags.isNotEmpty) ...[
          const SizedBox(height: ClipConstants.smallPadding / 2),
          _buildTagsSection(context, tags),
        ],

        // 显示更多元数据
        const SizedBox(height: ClipConstants.smallPadding / 2),
        _buildMetadataSection(context),
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
      padding: const EdgeInsets.all(Spacing.s4), // 最小内边距
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(ClipConstants.cardBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // OCR标题和置信度 - 使用固定高度的行
          SizedBox(
            height: 16, // 固定标题行高度
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 10, // 最小图标尺寸
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    'OCR识别文本',
                    style: TextStyle(
                      fontSize: 8, // 最小字体尺寸
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (ocrConfidence != null) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(ocrConfidence).withAlpha(51),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${(ocrConfidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 6, // 最小字体尺寸
                        fontWeight: FontWeight.w600,
                        color: _getConfidenceColor(ocrConfidence),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),

          // OCR文本内容 - 使用Expanded确保填充剩余空间
          Expanded(
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

  /// 构建标签区域
  Widget _buildTagsSection(BuildContext context, List<dynamic> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(5).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            tag.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建元数据区域
  Widget _buildMetadataSection(BuildContext context) {
    final metadataItems = <Widget>[];

    // 根据类型添加特定元数据
    switch (item.type) {
      case ClipType.image:
        final width = item.metadata['width'] as int?;
        final height = item.metadata['height'] as int?;
        final format = item.metadata['format'] as String?;
        final size = item.metadata['fileSize'] as int?;

        if (width != null && height != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.photo_size_select_large,
              '${width}x$height',
            ),
          );
        }
        if (format != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.image,
              format.toUpperCase(),
            ),
          );
        }
        if (size != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.storage,
              _formatFileSize(size),
            ),
          );
        }

      case ClipType.file:
        final fileSize = item.metadata['fileSize'] as int?;
        final fileType = item.metadata['fileType'] as String?;

        if (fileType != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.description,
              fileType,
            ),
          );
        }
        if (fileSize != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.storage,
              _formatFileSize(fileSize),
            ),
          );
        }

      case ClipType.text:
      case ClipType.rtf:
      case ClipType.code:
        // 重新计算准确的统计信息
        final content = item.content ?? '';
        final charCount = content.length;
        final wordCount = _calculateWordCount(content);
        final lineCount = content.split('\n').length;

        metadataItems.add(
          _buildMetadataItem(
            context,
            Icons.text_fields,
            '$charCount 字符',
          ),
        );
        if (wordCount > 0) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.space_bar,
              '$wordCount 词',
            ),
          );
        }
        if (lineCount > 1) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.format_align_left,
              '$lineCount 行',
            ),
          );
        }

      case ClipType.color:
        final colorHex = item.metadata['colorHex'] as String?;
        if (colorHex != null) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.palette,
              colorHex.toUpperCase(),
            ),
          );
        }

      case ClipType.url:
        final domain = _extractDomain(item.content ?? '');
        if (domain.isNotEmpty) {
          metadataItems.add(
            _buildMetadataItem(
              context,
              Icons.language,
              domain,
            ),
          );
        }

      case ClipType.audio:
      case ClipType.video:
      case ClipType.html:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
        // 这些类型暂时不显示特殊元数据
        break;
    }

    if (metadataItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: metadataItems,
    );
  }

  /// 构建单个元数据项
  Widget _buildMetadataItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: 0.7,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  /// 提取域名
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } on Exception {
      return '';
    }
  }

  /// 计算准确的字数统计
  int _calculateWordCount(String content) {
    if (content.isEmpty) return 0;

    // 对于中文文本，每个字符算一个词
    final hasChineseChars = RegExp(r'[\u4e00-\u9fff]').hasMatch(content);
    if (hasChineseChars) {
      // 统计非空白字符作为词数
      final nonWhitespaceChars = RegExp(r'\S').allMatches(content).length;
      return nonWhitespaceChars;
    }

    // 对于英文文本，按空格分割统计词数
    final words = content.trim().split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
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
