// ignore_for_file: public_member_api_docs, no_default_cases
// This file uses extensive switch statements with exhaustive patterns that are
// cleaner without default cases. Public member documentation is handled inline.
import 'dart:io';
import 'dart:math' as math;

import 'package:clip_flow_pro/core/constants/colors.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:clip_flow_pro/core/utils/i18n_common_util.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// 现代化的剪贴项卡片组件 - 解决布局溢出和性能问题
class ModernClipItemCard extends StatefulWidget {
  /// 剪贴项卡片组件
  const ModernClipItemCard({
    required this.item,
    required this.displayMode,
    required this.onTap,
    required this.onDelete,
    super.key,
    this.searchQuery,
    this.onFavoriteToggle,
    this.onOcrTextTap,
    this.enableOcrCopy = false,
  });

  /// 剪贴项
  final ClipItem item;

  /// 显示模式
  final DisplayMode displayMode;

  /// 点击回调
  final VoidCallback onTap;

  /// 删除回调
  final VoidCallback onDelete;

  /// 收藏切换回调
  final VoidCallback? onFavoriteToggle;

  /// 搜索关键词
  final String? searchQuery;

  /// OCR文本点击回调
  final VoidCallback? onOcrTextTap;

  /// 是否启用OCR复制功能
  final bool enableOcrCopy;

  @override
  State<ModernClipItemCard> createState() => _ModernClipItemCardState();
}

class _ModernClipItemCardState extends State<ModernClipItemCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(
          begin: 1,
          end: 0.98,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _elevationAnimation =
        Tween<double>(
          begin: 2,
          end: 8,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
  }

  void _handleMouseExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Semantics(
      label: _getSemanticLabel(),
      hint: '点击复制内容，长按显示更多选项',
      button: true,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap(),
          ),
        },
        child: MouseRegion(
          onEnter: _handleMouseEnter,
          onExit: _handleMouseExit,
          cursor: SystemMouseCursors.click,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: _getCardMargin(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_getBorderRadius()),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _getShadowAlpha(),
                        ),
                        blurRadius: _elevationAnimation.value,
                        offset: Offset(0, _getShadowOffset()),
                        spreadRadius: _isHovered ? 1 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: _getBorderColor(context),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(_getBorderRadius()),
                    child: InkWell(
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(_getBorderRadius()),
                      splashColor: Theme.of(context).colorScheme.primary
                          .withValues(
                            alpha: 0.1,
                          ),
                      highlightColor: Theme.of(context).colorScheme.primary
                          .withValues(
                            alpha: 0.05,
                          ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _getMaxCardHeight(context),
                          minHeight: _getMinCardHeight(context),
                        ),
                        child: _buildCardContent(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Padding(
      padding: _getContentPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：类型图标和操作按钮
          _buildHeader(context),

          SizedBox(height: _getVerticalSpacing()),

          // 内容预览 - 使用Expanded确保footer固定在底部
          Expanded(
            child: _buildContentArea(context),
          ),

          SizedBox(height: _getVerticalSpacing()),

          // 底部：时间和元数据
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildTypeIcon(context),
        const SizedBox(width: Spacing.s12),
        Expanded(
          child: _buildTypeLabel(context),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    final iconConfig = _getIconConfig();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconConfig.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconConfig.color.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        iconConfig.icon,
        size: 16,
        color: iconConfig.color,
      ),
    );
  }

  Widget _buildTypeLabel(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _getTypeLabel();

    return Text(
      typeLabel,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isHovered ? 1.0 : 0.7,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFavoriteButton(context),
          const SizedBox(width: Spacing.s4),
          _buildDeleteButton(context),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        // 从状态管理器获取最新的收藏状态
        final clipboardItems = ref.watch(clipboardHistoryProvider);
        final currentItem = clipboardItems.firstWhere(
          (item) => item.id == widget.item.id,
          orElse: () => widget.item, // 如果找不到则使用原始item
        );
        final isFavorite = currentItem.isFavorite;

        return Semantics(
          label: isFavorite ? '取消收藏' : '收藏',
          button: true,
          child: IconButton.outlined(
            onPressed: _handleFavoriteToggle,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFavorite),
                size: 18,
                color: isFavorite
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            style: IconButton.styleFrom(
              foregroundColor: isFavorite
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              side: BorderSide(
                color: isFavorite
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '删除',
      button: true,
      child: IconButton.outlined(
        onPressed: () {
          // 添加触觉反馈
          HapticFeedback.mediumImpact();
          // 直接调用外部删除回调，确认对话框由主页处理
          widget.onDelete();
        },
        icon: Icon(
          Icons.delete_outline,
          size: 18,
          color: theme.colorScheme.error,
        ),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: '删除',
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: _buildContentPreview(context, constraints.maxWidth),
        );
      },
    );
  }

  Widget _buildContentPreview(BuildContext context, double availableWidth) {
    switch (widget.item.type) {
      case ClipType.color:
        return _buildColorPreview(context);
      case ClipType.image:
        return _buildImagePreview(context, availableWidth);
      case ClipType.file:
        return _buildFilePreview(context);
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
        return _buildTextPreview(context, availableWidth);
    }
  }

  Widget _buildColorPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorHex = widget.item.content ?? AppColors.defaultColorHex;
    final colorName = ColorUtils.getColorName(colorHex);
    final color = _parseColorSafely(colorHex);

    return Container(
      width: double.infinity,
      height: _getColorPreviewHeight(),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              colorHex.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (colorName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                colorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, double availableWidth) {
    return Consumer(
      builder: (context, ref, child) {
        // 获取OCR设置状态
        final preferences = ref.watch(userPreferencesProvider);
        final isOcrEnabled = preferences.enableOCR;
        final hasOcrText = widget.item.ocrText != null && widget.item.ocrText!.isNotEmpty;

        // 如果开启OCR且有OCR文本，使用并排布局
        if (isOcrEnabled && hasOcrText) {
          return _buildImageWithOcrSideBySide(context, availableWidth, ref);
        }

        // 否则使用垂直布局（仅图片或图片+OCR文本）
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片预览
            Flexible(
              child: _buildImageWidget(context, availableWidth),
            ),

            // OCR文本显示（仅在关闭OCR时显示，作为额外信息）
            if (!isOcrEnabled && hasOcrText) ...[
              SizedBox(height: _getVerticalSpacing()),
              _buildOcrTextPreview(context),
            ],
          ],
        );
      },
    );
  }

  Widget _buildImageWithOcrSideBySide(BuildContext context, double availableWidth, WidgetRef ref) {
    // 计算间距
    const spacing = 8.0; // 固定间距

    // 计算可用宽度（减去间距后，平分给图片和OCR）
    final remainingWidth = availableWidth - spacing;
    final imageWidth = remainingWidth / 2; // 图片和OCR各占一半
    final imageDisplaySize = _calculateImageDisplaySize(imageWidth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧：图片预览
        SizedBox(
          width: imageWidth,
          height: imageDisplaySize.height, // 确保容器高度匹配图片
          child: _buildImageWidget(context, imageWidth),
        ),

        // 间距
        const SizedBox(width: spacing),

        // 右侧：OCR文本 - 宽度和高度都与图片一致
        SizedBox(
          width: imageWidth, // OCR容器宽度与图片容器宽度完全一致
          height: imageDisplaySize.height, // 高度与图片完全一致
          child: _buildCompactOcrTextPreviewWithHeight(context, imageDisplaySize.height),
        ),
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context, double availableWidth) {
    final theme = Theme.of(context);
    final imageDisplaySize = _calculateImageDisplaySize(availableWidth);

    return GestureDetector(
      onTap: widget.enableOcrCopy ? widget.onTap : null,
      child: Container(
        width: imageDisplaySize.width,
        height: imageDisplaySize.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageContent(context, imageDisplaySize),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, Size displaySize) {
    // 优先使用缩略图
    if (widget.item.thumbnail != null && widget.item.thumbnail!.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(widget.item.thumbnail!),
        width: displaySize.width,
        height: displaySize.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        cacheWidth: displaySize.width.round(),
        gaplessPlayback: true,
        semanticLabel: '图片预览',
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder(context, displaySize);
        },
      );
    }

    // 尝试加载原图
    if (widget.item.filePath != null && widget.item.filePath!.isNotEmpty) {
      return FutureBuilder<String?>(
        future: _resolveAbsoluteImagePath(widget.item.filePath!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder(context, displaySize);
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              File(snapshot.data!),
              width: displaySize.width,
              height: displaySize.height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              cacheWidth: displaySize.width.round(),
              semanticLabel: '图片预览',
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorPlaceholder(context, displaySize);
              },
            );
          }

          return _buildImagePlaceholder(context, displaySize);
        },
      );
    }

    return _buildImagePlaceholder(context, displaySize);
  }

  Widget _buildImageErrorPlaceholder(BuildContext context, Size size) {
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              '图片加载失败',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, Size size) {
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, Size size) {
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildCompactOcrTextPreviewWithHeight(BuildContext context, double fixedHeight) {
    final theme = Theme.of(context);
    final ocrText = widget.item.ocrText ?? '';
    final ocrConfidence = widget.item.metadata['ocrConfidence'] as double?;

    return GestureDetector(
      onTap: widget.enableOcrCopy ? widget.onOcrTextTap : null,
      child: Container(
        width: double.infinity,
        height: fixedHeight, // 使用固定的指定高度
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 紧凑的OCR标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 10,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'OCR',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ocrConfidence != null) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(
                        ocrConfidence,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${(ocrConfidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: _getConfidenceColor(ocrConfidence),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // OCR文本内容 - 使用剩余的全部空间
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(6),
              physics: const ClampingScrollPhysics(),
              child: _buildOcrTextContent(context, ocrText),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildOcrTextPreview(BuildContext context) {
    final theme = Theme.of(context);
    final ocrText = widget.item.ocrText ?? '';
    final ocrConfidence = widget.item.metadata['ocrConfidence'] as double?;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: _getOcrTextMaxHeight(),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // OCR标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'OCR识别文本',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ocrConfidence != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(
                        ocrConfidence,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(ocrConfidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: _getConfidenceColor(ocrConfidence),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // OCR文本内容
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              physics: const ClampingScrollPhysics(),
              child: _buildOcrTextContent(context, ocrText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrTextContent(BuildContext context, String ocrText) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.3,
    );

    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return Text(ocrText, style: textStyle);
    }

    // 搜索高亮
    final spans = _buildHighlightedSpans(
      context,
      ocrText,
      widget.searchQuery!,
      textStyle ?? const TextStyle(),
    );

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = widget.item.metadata['fileName'] as String? ?? '未知文件';
    final fileSize = widget.item.metadata['fileSize'] as int? ?? 0;
    final fileIcon = _getFileIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fileIcon.icon,
            size: 24,
            color: fileIcon.color,
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (fileSize > 0) ...[
            const SizedBox(height: 2),
            Text(
              _formatFileSize(fileSize),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context, double availableWidth) {
    final content = widget.item.content ?? '';
    final theme = Theme.of(context);

    final isMonospace =
        widget.item.type == ClipType.code ||
        widget.item.type == ClipType.json ||
        widget.item.type == ClipType.xml;

    final baseStyle = isMonospace
        ? theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
        : theme.textTheme.bodyMedium;

    final textStyle = baseStyle?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
      height: 1.4,
    );

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: _buildTextContent(context, content, textStyle),
      ),
    );
  }

  Widget _buildTextContent(
    BuildContext context,
    String content,
    TextStyle? style,
  ) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return Text(
        content,
        style: style,
        overflow: TextOverflow.clip,
      );
    }

    // 搜索高亮
    if (!content.toLowerCase().contains(widget.searchQuery!.toLowerCase())) {
      return Text(
        content,
        style: style,
        overflow: TextOverflow.clip,
      );
    }

    final spans = _buildHighlightedSpans(
      context,
      content,
      widget.searchQuery!,
      style ?? const TextStyle(),
    );

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _getTimeAgo(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间和所有信息在同一行显示
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 时间信息部分
              Icon(
                Icons.access_time,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 其他统计信息 - 文本统计或图片/文件元数据
              const SizedBox(width: 12),
              _buildCompactStatsOrMetadata(context),
            ],
          ),
        ),
      ],
    );
  }

  // 辅助方法和配置
  EdgeInsets _getCardMargin() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return const EdgeInsets.symmetric(vertical: 4, horizontal: 8);
      case DisplayMode.normal:
        return const EdgeInsets.symmetric(vertical: 6, horizontal: 10);
      case DisplayMode.preview:
        return const EdgeInsets.symmetric(vertical: 8, horizontal: 12);
    }
  }

  double _getBorderRadius() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 8;
      case DisplayMode.normal:
        return 12;
      case DisplayMode.preview:
        return 16;
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return const EdgeInsets.all(12);
      case DisplayMode.normal:
        return const EdgeInsets.all(16);
      case DisplayMode.preview:
        return const EdgeInsets.all(20);
    }
  }

  double _getMaxCardHeight(BuildContext context) {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 200;
      case DisplayMode.normal:
        return 300;
      case DisplayMode.preview:
        return 500;
    }
  }

  double _getMinCardHeight(BuildContext context) {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 120;
      case DisplayMode.normal:
        return 180;
      case DisplayMode.preview:
        return 250;
    }
  }

  double _getShadowAlpha() {
    if (_isPressed) return 0.3;
    if (_isHovered) return 0.15;
    return 0.08;
  }

  double _getShadowOffset() {
    if (_isPressed) return 1;
    if (_isHovered) return 4;
    return 2;
  }

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    if (_isHovered) {
      return theme.colorScheme.primary.withValues(alpha: 0.3);
    }
    return theme.colorScheme.outline.withValues(alpha: 0.2);
  }

  double _getVerticalSpacing() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 8;
      case DisplayMode.normal:
        return 12;
      case DisplayMode.preview:
        return 16;
    }
  }

  IconConfig _getIconConfig() {
    switch (widget.item.type) {
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

  double _getColorPreviewHeight() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 60;
      case DisplayMode.normal:
        return 80;
      case DisplayMode.preview:
        return 100;
    }
  }

  double _getOcrTextMaxHeight() {
    switch (widget.displayMode) {
      case DisplayMode.compact:
        return 60;
      case DisplayMode.normal:
        return 80;
      case DisplayMode.preview:
        return 120;
    }
  }

  Size _calculateImageDisplaySize(double availableWidth) {
    final maxWidth = math.min(
      switch (widget.displayMode) {
        DisplayMode.compact => availableWidth * 0.8,
        DisplayMode.normal => availableWidth * 0.7,
        DisplayMode.preview => availableWidth * 0.9,
      },
      switch (widget.displayMode) {
        DisplayMode.compact => 150.0,
        DisplayMode.normal => 250.0,
        DisplayMode.preview => 400.0,
      },
    );

    if (widget.item.originWidth == null || widget.item.originHeight == null) {
      return Size(maxWidth, maxWidth * 0.75); // 默认4:3比例
    }

    final originWidth = widget.item.originWidth!.toDouble();
    final originHeight = widget.item.originHeight!.toDouble();
    final aspectRatio = originWidth / originHeight;

    final displayWidth = math.min(maxWidth, originWidth);
    final displayHeight = displayWidth / aspectRatio;

    return Size(displayWidth, displayHeight);
  }

  Future<String?> _resolveAbsoluteImagePath(String path) async {
    try {
      final isAbsolute =
          path.startsWith('/') || RegExp('^[A-Za-z]:').hasMatch(path);
      if (isAbsolute) {
        final file = File(path);
        return file.existsSync() ? path : null;
      }

      final dir = await PathService.instance.getDocumentsDirectory();
      final abs = p.join(dir.path, path);
      final file = File(abs);
      return file.existsSync() ? abs : null;
    } on Exception catch (_) {
      return null;
    }
  }

  FileIconConfig _getFileIcon() {
    final fileName = widget.item.metadata['fileName'] as String? ?? '';
    final extension = p.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return const FileIconConfig(Icons.picture_as_pdf, Colors.red);
      case '.doc':
      case '.docx':
        return const FileIconConfig(Icons.description, Colors.blue);
      case '.xls':
      case '.xlsx':
        return const FileIconConfig(Icons.table_chart, Colors.green);
      case '.ppt':
      case '.pptx':
        return const FileIconConfig(Icons.slideshow, Colors.orange);
      case '.zip':
      case '.rar':
      case '.7z':
        return const FileIconConfig(Icons.archive, Colors.purple);
      case '.mp4':
      case '.avi':
      case '.mov':
        return const FileIconConfig(Icons.video_file, Colors.red);
      case '.mp3':
      case '.wav':
      case '.flac':
        return const FileIconConfig(Icons.audio_file, Colors.pink);
      default:
        return const FileIconConfig(Icons.insert_drive_file, Colors.grey);
    }
  }

  String _getTypeLabel() {
    switch (widget.item.type) {
      case ClipType.text:
        return I18nCommonUtil.getClipTypeText(context);
      case ClipType.rtf:
        return I18nCommonUtil.getClipTypeRichText(context);
      case ClipType.html:
        return I18nCommonUtil.getClipTypeHtml(context);
      case ClipType.image:
        return I18nCommonUtil.getClipTypeImage(context);
      case ClipType.color:
        return I18nCommonUtil.getClipTypeColor(context);
      case ClipType.file:
        return I18nCommonUtil.getClipTypeFile(context);
      case ClipType.audio:
        return I18nCommonUtil.getClipTypeAudio(context);
      case ClipType.video:
        return I18nCommonUtil.getClipTypeVideo(context);
      case ClipType.url:
        return 'URL';
      case ClipType.email:
        return 'Email';
      case ClipType.json:
        return 'JSON';
      case ClipType.xml:
        return 'XML';
      case ClipType.code:
        return 'Code';
    }
  }

  String _getSemanticLabel() {
    final typeLabel = _getTypeLabel();
    final contentPreview = _getContentPreview();
    final timeAgo = _getTimeAgo(context);

    return '$typeLabel：$contentPreview，$timeAgo';
  }

  String _getContentPreview() {
    switch (widget.item.type) {
      case ClipType.image:
        final width =
            widget.item.originWidth ??
            widget.item.metadata['width'] as int? ??
            0;
        final height =
            widget.item.originHeight ??
            widget.item.metadata['height'] as int? ??
            0;
        return width > 0 && height > 0 ? '图片 $width×$height' : '图片';
      case ClipType.file:
        final fileName = widget.item.metadata['fileName'] as String? ?? '未知文件';
        return fileName;
      case ClipType.color:
        final colorHex = widget.item.content ?? AppColors.defaultColorHex;
        return '颜色 $colorHex';
      default:
        final content = widget.item.content ?? '';
        if (content.length > 50) {
          return '${content.substring(0, 50)}...';
        }
        return content;
    }
  }

  String _getTimeAgo(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(widget.item.createdAt);

    if (difference.inMinutes < 1) {
      return I18nCommonUtil.getTimeJustNow(context);
    } else if (difference.inMinutes < 60) {
      return I18nCommonUtil.getTimeMinutesAgo(context, difference.inMinutes);
    } else if (difference.inHours < 24) {
      return I18nCommonUtil.getTimeHoursAgo(context, difference.inHours);
    } else if (difference.inDays < 7) {
      return I18nCommonUtil.getTimeDaysAgo(context, difference.inDays);
    } else {
      return DateFormat('yyyy-MM-dd').format(widget.item.createdAt);
    }
  }

  Widget _buildCompactStatsOrMetadata(BuildContext context) {
    switch (widget.item.type) {
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
        return _buildCompactContentStats(context);

      case ClipType.image:
        return _buildCompactImageMetadata(context);

      case ClipType.file:
        return _buildCompactFileMetadata(context);

      case ClipType.color:
        return _buildCompactColorMetadata(context);
    }
  }

  Widget _buildCompactContentStats(BuildContext context) {
    final content = widget.item.content ?? '';

    // 计算统计信息
    final charCount = content.length;
    final wordCount = _calculateWordCount(content);
    final lineCount = content.split('\n').length;

    return Wrap(
      spacing: 6,
      runSpacing: 3,
      children: [
        _buildCompactStatChip(context, Icons.text_fields, '$charCount字符'),
        if (wordCount > 0)
          _buildCompactStatChip(context, Icons.space_bar, '$wordCount词'),
        if (lineCount > 1)
          _buildCompactStatChip(
            context,
            Icons.format_align_left,
            '$lineCount行',
          ),
      ],
    );
  }

  Widget _buildCompactImageMetadata(BuildContext context) {
    final metadataItems = <Widget>[];

    final width =
        widget.item.originWidth ?? widget.item.metadata['width'] as int?;
    final height =
        widget.item.originHeight ?? widget.item.metadata['height'] as int?;
    final format = widget.item.metadata['format'] as String?;
    final size = widget.item.metadata['fileSize'] as int?;

    if (width != null && height != null) {
      metadataItems.add(
        _buildCompactStatChip(
          context,
          Icons.photo_size_select_large,
          '$width×$height',
        ),
      );
    }
    if (format != null) {
      metadataItems.add(
        _buildCompactStatChip(context, Icons.image, format.toUpperCase()),
      );
    }
    if (size != null) {
      metadataItems.add(
        _buildCompactStatChip(context, Icons.storage, _formatFileSize(size)),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 3,
      children: metadataItems,
    );
  }

  Widget _buildCompactFileMetadata(BuildContext context) {
    final metadataItems = <Widget>[];

    final fileSize = widget.item.metadata['fileSize'] as int?;
    final fileType = widget.item.metadata['fileType'] as String?;

    if (fileType != null) {
      metadataItems.add(
        _buildCompactStatChip(context, Icons.description, fileType),
      );
    }
    if (fileSize != null) {
      metadataItems.add(
        _buildCompactStatChip(
          context,
          Icons.storage,
          _formatFileSize(fileSize),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 3,
      children: metadataItems,
    );
  }

  Widget _buildCompactColorMetadata(BuildContext context) {
    final colorHex = widget.item.content;

    if (colorHex != null && colorHex.isNotEmpty) {
      return _buildCompactStatChip(
        context,
        Icons.palette,
        colorHex.toUpperCase(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCompactStatChip(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _calculateWordCount(String content) {
    if (content.isEmpty) return 0;

    final hasChineseChars = RegExp(r'[\u4e00-\u9fff]').hasMatch(content);
    if (hasChineseChars) {
      return RegExp(r'\S').allMatches(content).length;
    }

    final words = content.trim().split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
  }

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
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  
  void _handleFavoriteToggle() {
    // 触发触觉反馈
    HapticFeedback.selectionClick();

    // 调用外部回调来更新收藏状态
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle?.call();
    }
  }

  Color _parseColorSafely(String colorHex) {
    try {
      return ColorUtils.hexToColor(colorHex);
    } on Exception catch (_) {
      // 如果颜色解析失败，返回默认颜色
      return Color(
        int.parse(AppColors.defaultColorHex.replaceFirst('#', '0xFF')),
      );
    }
  }
}

// 配置类

/// 图标配置类
class IconConfig {
  /// 创建图标配置
  const IconConfig(this.icon, this.color);

  /// 图标数据
  final IconData icon;

  /// 图标颜色
  final Color color;
}

/// 文件图标配置类
class FileIconConfig {
  /// 创建文件图标配置
  const FileIconConfig(this.icon, this.color);

  /// 图标数据
  final IconData icon;

  /// 图标颜色
  final Color color;
}
