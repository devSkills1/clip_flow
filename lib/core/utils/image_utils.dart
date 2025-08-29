import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  // 检测是否为图片文件
  static bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'heic'].contains(extension);
  }

  // 生成缩略图
  static Future<Uint8List?> generateThumbnail(Uint8List imageData, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
    } catch (e) {
      return null;
    }
  }

  // 压缩图片
  static Future<Uint8List?> compressImage(Uint8List imageData, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // 如果图片尺寸超过限制，先调整尺寸
      img.Image resizedImage = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resizedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
    } catch (e) {
      return null;
    }
  }

  // 获取图片信息
  static Map<String, dynamic> getImageInfo(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        return {
          'width': 0,
          'height': 0,
          'format': 'unknown',
          'size': imageData.length,
        };
      }

      return {
        'width': image.width,
        'height': image.height,
        'format': _getImageFormat(imageData),
        'size': imageData.length,
        'aspectRatio': image.width / image.height,
      };
    } catch (e) {
      return {
        'width': 0,
        'height': 0,
        'format': 'unknown',
        'size': imageData.length,
      };
    }
  }

  // 检测图片格式
  static String _getImageFormat(Uint8List data) {
    if (data.length < 4) return 'unknown';

    // JPEG
    if (data[0] == 0xFF && data[1] == 0xD8) return 'jpeg';
    
    // PNG
    if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) return 'png';
    
    // GIF
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) return 'gif';
    
    // BMP
    if (data[0] == 0x42 && data[1] == 0x4D) return 'bmp';
    
    // WebP
    if (data.length >= 12 &&
        data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
        data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
      return 'webp';
    }

    return 'unknown';
  }

  // 提取图片主色调
  static List<Map<String, dynamic>> extractDominantColors(Uint8List imageData, {
    int colorCount = 5,
  }) {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return [];

      // 简化图片以加快处理速度
      final resized = img.copyResize(image, width: 100, height: 100);
      
      final colors = <Map<String, int>>[];
      final colorCounts = <String, int>{};

      // 统计颜色
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = img.getRed(pixel);
          final g = img.getGreen(pixel);
          final b = img.getBlue(pixel);
          
          // 量化颜色以减少相似色
          final quantizedR = (r ~/ 32) * 32;
          final quantizedG = (g ~/ 32) * 32;
          final quantizedB = (b ~/ 32) * 32;
          
          final colorKey = '$quantizedR,$quantizedG,$quantizedB';
          colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
        }
      }

      // 按出现频率排序
      final sortedColors = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 取前N个颜色
      return sortedColors.take(colorCount).map((entry) {
        final parts = entry.key.split(',');
        return {
          'r': int.parse(parts[0]),
          'g': int.parse(parts[1]),
          'b': int.parse(parts[2]),
          'count': entry.value,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 转换为Base64
  static String toBase64(Uint8List imageData) {
    return base64Encode(imageData);
  }

  // 生成Markdown图片语法
  static String toMarkdownImage(String imagePath, {String? altText}) {
    final alt = altText ?? '图片';
    return '![$alt]($imagePath)';
  }

  // 生成HTML img标签
  static String toHtmlImage(String imagePath, {
    String? altText,
    int? width,
    int? height,
  }) {
    final alt = altText ?? '图片';
    final widthAttr = width != null ? ' width="$width"' : '';
    final heightAttr = height != null ? ' height="$height"' : '';
    
    return '<img src="$imagePath" alt="$alt"$widthAttr$heightAttr>';
  }

  // 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
