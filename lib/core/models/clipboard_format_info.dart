import 'package:clip_flow_pro/core/services/clipboard/clipboard_data.dart';

/// 格式信息
class FormatInfo {
  /// 构造器
  const FormatInfo({
    required this.format,
    required this.content,
    required this.size,
    required this.isValid,
    required this.metadata,
  });

  /// 剪贴板格式类型
  final ClipboardFormat format;

  /// 格式内容
  final dynamic content;

  /// 内容大小
  final int size;

  /// 内容是否有效
  final bool isValid;

  /// 格式元数据
  final Map<String, dynamic> metadata;
}
