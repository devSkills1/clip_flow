import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/clip_item.dart';
import '../utils/color_utils.dart';
import '../utils/image_utils.dart';


class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  static ClipboardService get instance => _instance;

  final StreamController<ClipItem> _clipboardController = 
      StreamController<ClipItem>.broadcast();
  
  Stream<ClipItem> get clipboardStream => _clipboardController.stream;
  
  Timer? _pollingTimer;
  String _lastClipboardContent = '';
  Uint8List? _lastImageContent;
  bool _isInitialized = false;
  
  static const MethodChannel _platformChannel = MethodChannel('clipboard_service');

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 启动剪贴板监听
    _startPolling();
    _isInitialized = true;
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) => _checkClipboard(),
    );
  }

  Future<void> _checkClipboard() async {
    try {
      // 首先检查图片数据
      final imageBytes = await _getClipboardImage();
      if (imageBytes != null && imageBytes.isNotEmpty) {
        if (_lastImageContent == null || !_areImageBytesEqual(imageBytes, _lastImageContent!)) {
          _lastImageContent = imageBytes;
          await _processImageContent(imageBytes);
          return;
        }
      }
      
      // 检查文本数据
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final currentContent = clipboardData?.text ?? '';
      
      if (currentContent.isNotEmpty && currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        await _processClipboardContent(currentContent);
      }
    } catch (e) {
      // 忽略剪贴板访问错误
    }
  }

  Future<void> _processClipboardContent(String content) async {
    try {
      // 检测内容类型
      final clipType = _detectContentType(content);
      
      // 创建剪贴板项目
      final clipItem = ClipItem(
        type: clipType,
        content: content.codeUnits,
        metadata: await _extractMetadata(content, clipType),
      );
      
      // 发送到流
      _clipboardController.add(clipItem);
    } catch (e) {
      // 处理错误
    }
  }

  ClipType _detectContentType(String content) {
    // 检测颜色值
    if (ColorUtils.isColorValue(content)) {
      return ClipType.color;
    }
    
    // 检测文件路径
    if (content.startsWith('file://') || content.contains('/') || content.contains('\\')) {
      final file = File(content.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return ClipType.file;
      }
    }
    
    // 检测HTML
    if (content.contains('<html>') || content.contains('<div>') || content.contains('<p>')) {
      return ClipType.html;
    }
    
    // 检测富文本
    if (content.contains('\\rtf') || content.contains('\\fonttbl')) {
      return ClipType.rtf;
    }
    
    // 默认为纯文本
    return ClipType.text;
  }

  Future<Map<String, dynamic>> _extractMetadata(String content, ClipType type) async {
    final metadata = <String, dynamic>{
      'sourceApp': await _getSourceApp(),
      'contentLength': content.length,
      'tags': <String>[],
    };

    switch (type) {
      case ClipType.color:
        metadata['colorHex'] = content;
        metadata['colorRgb'] = ColorUtils.hexToRgb(content);
        metadata['colorHsl'] = ColorUtils.hexToHsl(content);
        break;
      case ClipType.file:
        final file = File(content.replaceFirst('file://', ''));
        metadata['filePath'] = file.path;
        metadata['fileName'] = file.path.split('/').last;
        metadata['fileSize'] = await file.length();
        metadata['fileExtension'] = file.path.split('.').last.toLowerCase();
        break;
      case ClipType.image:
        // 图片处理逻辑
        break;
      default:
        // 文本内容分析
        metadata['wordCount'] = _calculateWordCount(content);
        metadata['lineCount'] = content.split('\n').length;
        break;
    }

    return metadata;
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      final result = await _platformChannel.invokeMethod<Uint8List>('getClipboardImage');
      return result;
    } catch (e) {
      return null;
    }
  }

  bool _areImageBytesEqual(Uint8List bytes1, Uint8List bytes2) {
    if (bytes1.length != bytes2.length) return false;
    for (int i = 0; i < bytes1.length; i++) {
      if (bytes1[i] != bytes2[i]) return false;
    }
    return true;
  }

  Future<void> _processImageContent(Uint8List imageBytes) async {
    try {
      // 创建图片剪贴板项目
      final clipItem = ClipItem(
        type: ClipType.image,
        content: imageBytes,
        thumbnail: await ImageUtils.generateThumbnail(imageBytes),
        metadata: await _extractImageMetadata(imageBytes),
      );
      
      // 发送到流
      _clipboardController.add(clipItem);
    } catch (e) {
      // 处理错误
    }
  }

  int _calculateWordCount(String content) {
    if (content.isEmpty) return 0;
    
    // 移除首尾空白字符
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    
    // 统计中文字符数
    final chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(trimmed).length;
    
    // 统计英文单词数（按空格分割）
    final englishText = trimmed.replaceAll(RegExp(r'[\u4e00-\u9fa5]'), ' ');
    final englishWords = englishText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    
    // 返回中文字符数 + 英文单词数
    return chineseChars + englishWords;
  }

  Future<Map<String, dynamic>> _extractImageMetadata(Uint8List imageBytes) async {
    final metadata = <String, dynamic>{
      'sourceApp': await _getSourceApp(),
      'contentLength': imageBytes.length,
      'tags': <String>[],
      'fileSize': imageBytes.length,
    };

    try {
      final imageInfo = ImageUtils.getImageInfo(imageBytes);
      metadata['imageFormat'] = imageInfo['format'];
      metadata['width'] = imageInfo['width'];
      metadata['height'] = imageInfo['height'];
      metadata['aspectRatio'] = imageInfo['aspectRatio'];
    } catch (e) {
      // 无法获取图片信息
      metadata['imageFormat'] = 'unknown';
      metadata['width'] = 0;
      metadata['height'] = 0;
    }

    return metadata;
  }

  Future<String?> _getSourceApp() async {
    // 平台特定实现获取源应用
    try {
      const platform = MethodChannel('clipboard_service');
      final result = await platform.invokeMethod<String>('getSourceApp');
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<void> setClipboardContent(ClipItem item) async {
    try {
      switch (item.type) {
        case ClipType.image:
          // 处理图片类型
          await _setClipboardImage(item.content);
          break;
        case ClipType.text:
        case ClipType.rtf:
        case ClipType.html:
        case ClipType.color:
        case ClipType.file:
        default:
          // 处理文本类型
          final content = String.fromCharCodes(item.content);
          await Clipboard.setData(ClipboardData(text: content));
          _lastClipboardContent = content;
          break;
      }
    } catch (e) {
      // 处理错误
    }
  }
  
  Future<void> _setClipboardImage(List<int> imageBytes) async {
    try {
      await _platformChannel.invokeMethod('setClipboardImage', {
        'imageData': Uint8List.fromList(imageBytes),
      });
    } catch (e) {
      // 处理错误
    }
  }

  Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      _lastClipboardContent = '';
    } catch (e) {
      // 处理错误
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _clipboardController.close();
  }
}

// Riverpod Provider
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return ClipboardService.instance;
});

final clipboardStreamProvider = StreamProvider<ClipItem>((ref) {
  final service = ref.watch(clipboardServiceProvider);
  return service.clipboardStream;
});
