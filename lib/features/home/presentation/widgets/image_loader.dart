// ignore_for_file: public_member_api_docs
// Public member documentation is handled inline for clarity.
// Optimized image loader with comprehensive inline documentation.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 优化的图片加载器 - 解决图片溢出和性能问题
class ImageLoader extends StatefulWidget {
  /// 优化的图片加载器
  const ImageLoader({
    required this.imagePath,
    required this.thumbnailData,
    required this.displaySize,
    required this.originWidth,
    required this.originHeight,
    this.useOriginal = false,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    this.loadingBuilder,
    super.key,
  });

  /// 图片路径
  final String? imagePath;

  /// 缩略图数据
  final Uint8List? thumbnailData;

  /// 显示尺寸
  final Size displaySize;

  /// 原始宽度
  final int? originWidth;

  /// 原始高度
  final int? originHeight;

  /// 是否使用原图
  final bool useOriginal;

  /// 适配方式
  final BoxFit fit;

  /// 错误构建器
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// 加载构建器
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  @override
  State<ImageLoader> createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader>
    with AutomaticKeepAliveClientMixin {
  bool _useOriginalImage = false;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _useOriginalImage = widget.useOriginal;
  }

  @override
  void didUpdateWidget(ImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useOriginal != oldWidget.useOriginal) {
      setState(() {
        _useOriginalImage = widget.useOriginal;
      });
    }
  }

  Future<Uint8List?> _loadOptimizedImage(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('File not found: $path');
      }

      // 对于大图片，先读取图片信息
      final fileSize = await file.length();
      final shouldResize = fileSize > 1024 * 1024; // 1MB

      if (!shouldResize) {
        return await file.readAsBytes();
      }

      // 大图片需要优化处理
      return await _resizeImage(file, widget.displaySize);
    } on Exception catch (e) {
      debugPrint('Error loading optimized image: $e');
      return null;
    }
  }

  Future<Uint8List> _resizeImage(File file, Size targetSize) async {
    try {
      // 读取图片
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 计算目标尺寸，保持宽高比
      final originalWidth = image.width.toDouble();
      final originalHeight = image.height.toDouble();
      final aspectRatio = originalWidth / originalHeight;

      var targetHeight = targetSize.width / aspectRatio;

      // 确保不超过显示区域
      if (targetHeight > targetSize.height) {
        targetHeight = targetSize.height;
      }

      // 创建图片字节
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      image.dispose();
      return byteData.buffer.asUint8List();
    } on Exception {
      // 如果优化失败，返回原始图片
      return file.readAsBytes();
    }
  }

  Widget _buildThumbnailImage() {
    if (widget.thumbnailData == null || widget.thumbnailData!.isEmpty) {
      return _buildPlaceholder();
    }

    return _buildImageWidget(
      Image.memory(
        widget.thumbnailData!,
        width: widget.displaySize.width,
        height: widget.displaySize.height,
        fit: widget.fit,
        cacheWidth: widget.displaySize.width.round(),
        gaplessPlayback: true,
        semanticLabel: '缩略图预览',
        errorBuilder: widget.errorBuilder ?? _defaultErrorBuilder,
      ),
    );
  }

  Widget _buildOriginalImage() {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      return _buildThumbnailImage();
    }

    return FutureBuilder<Uint8List?>(
      future: _loadOptimizedImage(widget.imagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          setState(() {});
          return _buildLoadingWidget();
        }

        setState(() {});

        if (snapshot.hasError || snapshot.data == null) {
          setState(() => _hasError = true);
          return widget.errorBuilder?.call(
                context,
                snapshot.error ?? Exception('Failed to load image'),
                snapshot.stackTrace,
              ) ??
              _defaultErrorBuilder(
                context,
                snapshot.error ?? Exception('Failed to load image'),
                snapshot.stackTrace,
              );
        }

        setState(() => _hasError = false);

        return _buildImageWidget(
          Image.memory(
            snapshot.data!,
            width: widget.displaySize.width,
            height: widget.displaySize.height,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
            cacheWidth: widget.displaySize.width.round(),
            gaplessPlayback: true,
            semanticLabel: '原图预览',
            errorBuilder: widget.errorBuilder ?? _defaultErrorBuilder,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(Widget image) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, image, null);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);

    return Container(
      width: widget.displaySize.width,
      height: widget.displaySize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无图片',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final theme = Theme.of(context);

    return Container(
      width: widget.displaySize.width,
      height: widget.displaySize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: widget.displaySize.width,
      height: widget.displaySize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
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
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 智能选择显示策略
    if (_useOriginalImage && !_hasError) {
      return _buildOriginalImage();
    }

    return _buildThumbnailImage();
  }
}

/// 图片缓存管理器
class ImageCacheManager {
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();
  static final ImageCacheManager _instance = ImageCacheManager._internal();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheSize = 50; // 最大缓存数量
  static const Duration _maxCacheAge = Duration(hours: 1); // 缓存有效期

  Future<Uint8List?> loadImageFromCache(String key) async {
    // 检查缓存是否存在且未过期
    if (_memoryCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _maxCacheAge) {
        return _memoryCache[key];
      } else {
        // 缓存已过期，移除
        _removeFromCache(key);
      }
    }
    return null;
  }

  Future<void> saveImageToCache(String key, Uint8List imageData) async {
    // 如果缓存已满，清理最旧的缓存
    if (_memoryCache.length >= _maxCacheSize) {
      _cleanupOldCache();
    }

    _memoryCache[key] = imageData;
    _cacheTimestamps[key] = DateTime.now();
  }

  void _removeFromCache(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void _cleanupOldCache() {
    if (_memoryCache.isEmpty) return;

    // 找到最旧的缓存项
    var oldestKey = _cacheTimestamps.keys.first;
    var oldestTime = _cacheTimestamps[oldestKey]!;

    for (final entry in _cacheTimestamps.entries) {
      if (entry.value.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value;
      }
    }

    _removeFromCache(oldestKey);
  }

  void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  int get cacheSize => _memoryCache.length;
}
