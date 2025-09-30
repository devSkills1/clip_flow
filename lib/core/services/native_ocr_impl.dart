import 'dart:io';

import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:clip_flow_pro/core/services/ocr_service.dart';
import 'package:flutter/services.dart';

/// 原生OCR实现类
/// 使用各平台的原生OCR能力：
/// - macOS: Vision框架 ✅ 已实现
/// - Windows: Windows.Media.Ocr API ✅ 已实现
/// - Linux: Tesseract OCR ✅ 已实现
class NativeOcrImpl implements OcrService {
  /// 构造函数，异步预取语言列表，不阻塞构造
  NativeOcrImpl() {
    // 异步预取语言列表，不阻塞构造
    _fetchSupportedLanguages();
  }

  static const MethodChannel _channel = MethodChannel('clipboard_service');

  // 语言列表缓存（优先原生查询，回退基本集合）
  List<String> _supportedLanguagesCache = const [
    'en-US',
    'zh-Hans',
    'zh-Hant',
  ];

  /// 获取当前平台信息
  String get _platformInfo {
    if (Platform.isMacOS) return 'macOS (Vision Framework)';
    if (Platform.isWindows) return 'Windows (Windows.Media.Ocr API)';
    if (Platform.isLinux) return 'Linux (Tesseract OCR)';
    return 'Unsupported Platform';
  }

  /// 检查当前平台是否支持OCR
  bool get _isPlatformSupported {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  @override
  Future<OcrResult?> recognizeText(
    Uint8List imageBytes, {
    String language = 'auto',
    double? minConfidence,
  }) async {
    // 检查平台支持
    if (!_isPlatformSupported) {
      await Log.e(
        'Current platform does not support OCR',
        tag: 'OCR',
        fields: {
          'platform': _platformInfo,
        },
      );
      return null;
    }

    await Log.i(
      'Starting OCR recognition',
      tag: 'OCR',
      fields: {
        'imageSize': imageBytes.length,
        'language': language,
        if (minConfidence != null) 'minConfidence': minConfidence,
        'platform': _platformInfo,
      },
    );

    try {
      // 调用原生OCR方法
      final args = {
        'imageData': imageBytes,
        'language': language,
      };
      if (minConfidence != null) {
        args['minConfidence'] = minConfidence;
      }

      final result = await _channel.invokeMethod('performOCR', args);

      if (result == null) {
        await Log.w(
          'OCR returned null result',
          tag: 'OCR',
          fields: {
            'imageSize': imageBytes.length,
            'language': language,
            'platform': _platformInfo,
          },
        );
        return null;
      }

      final resultMap = Map<String, dynamic>.from(result as Map);
      final text = (resultMap['text'] ?? '').toString();
      final confidence = ((resultMap['confidence'] ?? 0.0) as num).toDouble();

      await Log.i(
        'OCR recognition completed successfully',
        tag: 'OCR',
        fields: {
          'textLength': text.length,
          'confidence': confidence,
          'hasText': text.isNotEmpty,
          'platform': _platformInfo,
        },
      );

      return OcrResult(
        text: text,
        confidence: confidence,
      );
    } on PlatformException catch (e) {
      await Log.e(
        'OCR platform exception occurred',
        tag: 'OCR',
        error: e,
        fields: {
          'code': e.code,
          'message': e.message,
          'details': e.details,
          'imageSize': imageBytes.length,
          'language': language,
          'platform': _platformInfo,
        },
      );
      return null;
    } on Object catch (e, stackTrace) {
      await Log.e(
        'Unexpected error during OCR recognition',
        tag: 'OCR',
        error: e,
        stackTrace: stackTrace,
        fields: {
          'imageSize': imageBytes.length,
          'language': language,
          'platform': _platformInfo,
        },
      );
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    await Log.d(
      'Checking OCR availability',
      tag: 'OCR',
      fields: {
        'platform': _platformInfo,
        'isPlatformSupported': _isPlatformSupported,
      },
    );

    // 首先检查平台支持
    if (!_isPlatformSupported) {
      await Log.w(
        'Platform not supported for OCR',
        tag: 'OCR',
        fields: {
          'platform': _platformInfo,
        },
      );
      return false;
    }

    try {
      // 尝试调用测试方法来检查原生插件是否可用
      await _channel.invokeMethod('isOCRAvailable');
      // 成功时刷新语言支持列表
      await _fetchSupportedLanguages();
      await Log.i(
        'OCR service available',
        tag: 'OCR',
        fields: {
          'platform': _platformInfo,
        },
      );
      return true;
    } on PlatformException catch (e) {
      await Log.w(
        'OCR service not available',
        tag: 'OCR',
        error: e,
        fields: {
          'platform': _platformInfo,
          'code': e.code,
          'message': e.message,
        },
      );
      return false;
    } on Object catch (e, stackTrace) {
      await Log.e(
        'Error checking OCR availability',
        tag: 'OCR',
        error: e,
        stackTrace: stackTrace,
        fields: {
          'platform': _platformInfo,
        },
      );
      return false;
    }
  }

  @override
  List<String> getSupportedLanguages() {
    // 返回缓存的语言列表，包含 'auto'
    return ['auto', ..._supportedLanguagesCache];
  }

  Future<void> _fetchSupportedLanguages() async {
    try {
      final langs = await _channel.invokeMethod<List<dynamic>>(
        'getSupportedOCRLanguages',
      );
      if (langs != null && langs.isNotEmpty) {
        _supportedLanguagesCache = langs.map((e) => e.toString()).toList();
        await Log.d(
          'Updated OCR language cache',
          tag: 'OCR',
          fields: {
            'count': _supportedLanguagesCache.length,
          },
        );
      }
    } on PlatformException catch (e) {
      await Log.w(
        'Failed to fetch OCR languages from native',
        tag: 'OCR',
        error: e,
      );
    } on Object catch (_) {
      // 忽略其他错误，保留回退缓存
      await Log.w('Failed to fetch OCR languages from native', tag: 'OCR');
    }
  }

  @override
  Future<void> dispose() async {
    await Log.d('Disposing OCR service', tag: 'OCR');
    // 原生OCR不需要特殊的资源清理
  }
}
