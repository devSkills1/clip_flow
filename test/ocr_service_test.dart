import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow/core/services/ocr_service.dart';
import 'mock_ocr_service.dart';

void main() {
  group('OCR Service Tests', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = MockOcrService();
    });

    tearDown(() async {
      await ocrService.dispose();
    });

    test('OCR service should be available', () async {
      final isAvailable = await ocrService.isAvailable();
      expect(isAvailable, isTrue);
    });

    test('OCR service should support expected languages', () {
      final supportedLanguages = ocrService.getSupportedLanguages();
      expect(supportedLanguages, contains('en'));
      expect(supportedLanguages, contains('zh'));
      expect(supportedLanguages, contains('auto'));
    });

    test('OCR service should handle empty image data', () async {
      final emptyBytes = Uint8List(0);
      final result = await ocrService.recognizeText(emptyBytes);
      expect(result, isNull);
    });

    test('OCR service should handle invalid image data', () async {
      final invalidBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await ocrService.recognizeText(invalidBytes);
      expect(result, isNull);
    });

    test('OCR service should create valid result for valid input', () async {
      // 创建一个简单的白色图像 (1x1像素，RGBA格式)
      final simpleImageBytes = Uint8List.fromList([
        // PNG header
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        // IHDR chunk
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89,
        // IDAT chunk (1x1 white pixel)
        0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, 0x54,
        0x78, 0x9C, 0x62, 0xF8, 0xFF, 0xFF, 0xFF, 0x00,
        0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D,
        0xB4,
        // IEND chunk
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82,
      ]);

      final result = await ocrService.recognizeText(simpleImageBytes);

      // 模拟OCR服务应该返回固定结果
      expect(result, isNotNull);
      expect(result!.text, equals('Mock OCR Result'));
      expect(result.confidence, equals(0.95));
      expect(result.confidence, greaterThanOrEqualTo(0.0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
    });

    test('OCR factory should return same instance', () {
      final instance1 = OcrServiceFactory.getInstance();
      final instance2 = OcrServiceFactory.getInstance();
      expect(instance1, same(instance2));
    });

    test('OCR factory should allow custom instance', () {
      final customService = MockOcrService();
      OcrServiceFactory.setInstance(customService);

      final instance = OcrServiceFactory.getInstance();
      expect(instance, same(customService));

      // 恢复默认实例
      OcrServiceFactory.setInstance(MockOcrService());
    });
  });
}
