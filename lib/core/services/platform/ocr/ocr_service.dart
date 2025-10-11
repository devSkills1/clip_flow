import 'dart:typed_data';
import 'package:clip_flow_pro/core/services/platform/ocr/index.dart';

/// OCR识别结果
class OcrResult {
  /// 构造函数
  const OcrResult({
    required this.text,
    required this.confidence,
    this.boundingBoxes,
  });

  /// 识别的文本内容
  final String text;

  /// 识别的置信度 (0.0 - 1.0)
  final double confidence;

  /// 文本在图片中的边界框 (可选)
  final List<OcrBoundingBox>? boundingBoxes;

  @override
  String toString() => 'OcrResult(text: "$text", confidence: $confidence)';
}

/// 文本边界框
class OcrBoundingBox {
  /// 构造函数
  const OcrBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.text,
    required this.confidence,
  });

  /// 左上角x坐标
  final double x;

  /// 左上角y坐标
  final double y;

  /// 宽度
  final double width;

  /// 高度
  final double height;

  /// 该区域的文本
  final String text;

  /// 该区域的置信度
  final double confidence;
}

/// OCR服务抽象接口
abstract class OcrService {
  /// 从图片字节数据中识别文字
  ///
  /// [imageBytes] 图片的字节数据
  /// [language] 识别语言代码，如 'en', 'zh', 'auto' 等
  /// [minConfidence] 最小置信度阈值，低于该值的结果可能被原生层过滤
  /// 返回识别结果，如果识别失败返回null
  Future<OcrResult?> recognizeText(
    Uint8List imageBytes, {
    String language = 'auto',
    double? minConfidence,
  });

  /// 检查OCR服务是否可用
  Future<bool> isAvailable();

  /// 获取支持的语言列表
  List<String> getSupportedLanguages();

  /// 释放资源
  Future<void> dispose();
}

/// OCR服务工厂
class OcrServiceFactory {
  static OcrService? _instance;

  /// 获取OCR服务实例
  static OcrService getInstance() {
    _instance ??= _createDefaultService();
    return _instance!;
  }

  /// 设置自定义OCR服务实例
  static void setInstance(OcrService service) {
    _instance?.dispose();
    _instance = service;
  }

  /// 创建默认的OCR服务
  static OcrService _createDefaultService() {
    // 返回原生OCR实现
    return NativeOcrImpl();
  }
}
