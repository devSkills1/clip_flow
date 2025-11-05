import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/id_generator.dart';
import 'package:flutter/foundation.dart';

/// OCR识别结果模型
/// 扩展ClipItem以支持OCR功能的独立性和关联性
@immutable
class OCREnhancedClipItem {
  /// 原始图片项目
  final ClipItem imageItem;

  /// OCR文本的独立ID（用于去重和复制）
  final String? ocrId;

  /// OCR识别的文本内容
  final String? ocrText;

  /// OCR识别时间
  final DateTime? ocrTimestamp;

  /// OCR识别语言
  final String? ocrLanguage;

  /// OCR识别置信度
  final double? ocrConfidence;

  /// OCR处理状态
  final OCRProcessingStatus ocrStatus;

  /// OCR版本号（支持OCR结果更新）
  final int ocrVersion;

  /// 创建OCR增强剪贴项
  const OCREnhancedClipItem({
    required this.imageItem,
    this.ocrId,
    this.ocrText,
    this.ocrTimestamp,
    this.ocrLanguage,
    this.ocrConfidence,
    this.ocrStatus = OCRProcessingStatus.pending,
    this.ocrVersion = 1,
  });

  /// 从ClipItem创建OCR增强项
  factory OCREnhancedClipItem.fromClipItem(ClipItem item) {
    return OCREnhancedClipItem(
      imageItem: item,
      ocrText: item.ocrText,
      ocrStatus: item.ocrText != null
          ? OCRProcessingStatus.completed
          : OCRProcessingStatus.pending,
      ocrTimestamp: item.updatedAt,
    );
  }

  /// 创建包含OCR结果的完整项目
  OCREnhancedClipItem withOCRResult({
    required String ocrText,
    String? language,
    double? confidence,
  }) {
    // 为OCR文本生成独立ID
    final ocrId = IdGenerator.generateId(
      ClipType.text, // OCR文本作为文本类型
      ocrText,
      null, // OCR文本没有文件路径
      {
        'sourceImageId': imageItem.id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // 更新图片项的OCR信息
    final updatedImageItem = imageItem.copyWith(
      ocrText: ocrText,
      updatedAt: DateTime.now(),
    );

    return OCREnhancedClipItem(
      imageItem: updatedImageItem,
      ocrId: ocrId,
      ocrText: ocrText,
      ocrTimestamp: DateTime.now(),
      ocrLanguage: language,
      ocrConfidence: confidence,
      ocrStatus: OCRProcessingStatus.completed,
      ocrVersion: ocrVersion + 1,
    );
  }

  /// 转换为存储用的ClipItem（仅存储在图片项中）
  ClipItem toStorageItem() {
    return imageItem.copyWith(
      ocrText: ocrText,
      updatedAt: DateTime.now(),
    );
  }

  /// 检查是否有OCR结果
  bool get hasOCR => ocrText != null && ocrText!.isNotEmpty;

  /// 检查OCR是否正在处理
  bool get isOCRProcessing => ocrStatus == OCRProcessingStatus.processing;

  /// 检查OCR是否已完成
  bool get isOCRCompleted => ocrStatus == OCRProcessingStatus.completed;

  /// 检查OCR是否失败
  bool get isOCRFailed => ocrStatus == OCRProcessingStatus.failed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OCREnhancedClipItem &&
           other.imageItem.id == imageItem.id &&
           other.ocrVersion == ocrVersion;
  }

  @override
  int get hashCode => Object.hash(imageItem.id, ocrVersion);

  Map<String, dynamic> toJson() {
    return {
      'imageItem': imageItem.toJson(),
      'ocrId': ocrId,
      'ocrText': ocrText,
      'ocrTimestamp': ocrTimestamp?.toIso8601String(),
      'ocrLanguage': ocrLanguage,
      'ocrConfidence': ocrConfidence,
      'ocrStatus': ocrStatus.name,
      'ocrVersion': ocrVersion,
    };
  }

  /// 从JSON创建OCR增强剪贴项
  factory OCREnhancedClipItem.fromJson(Map<String, dynamic> json) {
    return OCREnhancedClipItem(
      imageItem: ClipItem.fromJson(json['imageItem'] as Map<String, dynamic>),
      ocrId: json['ocrId'] as String?,
      ocrText: json['ocrText'] as String?,
      ocrTimestamp: json['ocrTimestamp'] != null
          ? DateTime.parse(json['ocrTimestamp'] as String)
          : null,
      ocrLanguage: json['ocrLanguage'] as String?,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
      ocrStatus: OCRProcessingStatus.values.firstWhere(
        (e) => e.name == json['ocrStatus'] as String?,
        orElse: () => OCRProcessingStatus.pending,
      ),
      ocrVersion: json['ocrVersion'] as int? ?? 1,
    );
  }
}

/// OCR处理状态枚举
enum OCRProcessingStatus {
  /// 等待处理
  pending,

  /// 正在处理
  processing,

  /// 处理完成
  completed,

  /// 处理失败
  failed,

  /// 已跳过（不支持的格式）
  skipped,
}

/// OCR复制类型
enum OCRCopyType {
  /// 复制图片
  image,

  /// 复制OCR文本
  text,

  /// 复制两者（先复制图片，再复制文本）
  both,
}