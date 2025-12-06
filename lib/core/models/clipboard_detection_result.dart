import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/models/clipboard_format_info.dart';
import 'package:clip_flow/core/services/clipboard/clipboard_data.dart';
import 'package:clip_flow/core/utils/color_utils.dart';

/// 剪贴板检测结果
class ClipboardDetectionResult {
  /// 创建检测结果实例
  const ClipboardDetectionResult({
    required this.detectedType,
    required this.contentToSave,
    required this.originalData,
    required this.confidence,
    required this.formatAnalysis,
    this.shouldSaveOriginal = false,
    this.ocrText,
  });

  /// 检测到的剪贴板内容类型
  final ClipType detectedType;

  /// 要保存的内容
  final dynamic contentToSave;

  /// 原始剪贴板数据
  final ClipboardData? originalData;

  /// 检测置信度（0-1）
  final double confidence;

  /// 格式分析结果
  final Map<ClipboardFormat, FormatInfo> formatAnalysis;

  /// 是否保存原始数据
  final bool shouldSaveOriginal;

  /// OCR识别的文本（图片类型）
  final String? ocrText;

  /// 创建ClipItem
  ClipItem createClipItem({String? id}) {
    return ClipItem(
      id: id, // 让ClipItem构造函数自动生成基于内容的ID
      type: detectedType,
      content: _getContentForClipItem(),
      filePath: _extractFilePath(),
      thumbnail: _extractThumbnail(),
      metadata: _buildMetadata(),
      ocrText: ocrText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 获取用于ClipItem的内容
  String? _getContentForClipItem() {
    // 对于非文本类型，内容通常为空
    if (detectedType == ClipType.image ||
        detectedType == ClipType.file ||
        detectedType == ClipType.audio ||
        detectedType == ClipType.video) {
      return '';
    }

    // 对于颜色类型，返回标准化的颜色值，确保与metadata一致
    if (detectedType == ClipType.color) {
      final colorContent = contentToSave?.toString().trim();
      if (colorContent != null && ColorUtils.isColorValue(colorContent)) {
        return ColorUtils.normalizeColorHex(colorContent);
      }
      return colorContent;
    }

    // 对于其他文本类型，返回要保存的内容
    return contentToSave?.toString();
  }

  String? _extractFilePath() {
    if (originalData == null) return null;

    if (detectedType == ClipType.file) {
      final files = originalData!.getFormat<List<String>>(
        ClipboardFormat.files,
      );
      return files?.isNotEmpty ?? false ? files!.first : null;
    }

    // 图片类型也需要从原数据中获取路径信息
    if (detectedType == ClipType.image) {
      final files = originalData!.getFormat<List<String>>(
        ClipboardFormat.files,
      );
      return files?.isNotEmpty ?? false ? files!.first : null;
    }

    return null;
  }

  List<int>? _extractThumbnail() {
    if (originalData == null) return null;

    if (detectedType == ClipType.image) {
      // 直接从原数据中获取图片数据作为缩略图
      final imageData = originalData!.getFormat<List<int>>(
        ClipboardFormat.image,
      );
      return imageData;
    }
    return null;
  }

  Map<String, dynamic> _buildMetadata() {
    final baseMetadata = {
      'confidence': confidence,
      'availableFormats':
          originalData?.availableFormats.map((f) => f.value).toList() ??
          <String>[],
      'sequence': originalData?.sequence ?? 0,
      'formatAnalysis': formatAnalysis.map(
        (k, v) => MapEntry(k.value, v.metadata),
      ),
    };

    // 为颜色类型添加 colorHex 元数据
    if (detectedType == ClipType.color) {
      final colorContent = _getContentForClipItem()?.trim();
      if (colorContent != null && ColorUtils.isColorValue(colorContent)) {
        baseMetadata['colorHex'] = ColorUtils.normalizeColorHex(colorContent);
      }
    }

    return baseMetadata;
  }
}
