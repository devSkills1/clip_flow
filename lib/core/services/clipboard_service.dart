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
  bool _isInitialized = false;

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
        metadata['wordCount'] = content.split(' ').length;
        metadata['lineCount'] = content.split('\n').length;
        break;
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
      final content = String.fromCharCodes(item.content);
      await Clipboard.setData(ClipboardData(text: content));
      _lastClipboardContent = content;
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
