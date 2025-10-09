/// 跨平台剪贴板数据模型
///
/// 统一表示从各平台获取的原始剪贴板数据
class ClipboardData {
  const ClipboardData({
    required this.formats,
    required this.sequence,
    required this.timestamp,
  });

  /// 剪贴板中可用的所有格式
  final Map<ClipboardFormat, dynamic> formats;

  /// 剪贴板变更序列号
  final int sequence;

  /// 检测时间
  final DateTime timestamp;

  /// 获取指定格式的内容
  T? getFormat<T>(ClipboardFormat format) {
    final content = formats[format];
    return content is T ? content : null;
  }

  /// 检查是否包含指定格式
  bool hasFormat(ClipboardFormat format) {
    return formats.containsKey(format);
  }

  /// 获取所有可用格式
  List<ClipboardFormat> get availableFormats {
    return formats.keys.toList();
  }

  /// 获取最佳内容（按优先级）
  dynamic get bestContent {
    // 优先级：纯文本 > HTML > RTF > 其他
    if (formats.containsKey(ClipboardFormat.text)) {
      return formats[ClipboardFormat.text];
    }
    if (formats.containsKey(ClipboardFormat.html)) {
      return formats[ClipboardFormat.html];
    }
    if (formats.containsKey(ClipboardFormat.rtf)) {
      return formats[ClipboardFormat.rtf];
    }
    return formats.values.firstOrNull;
  }

  /// 创建副本
  ClipboardData copyWith({
    Map<ClipboardFormat, dynamic>? formats,
    int? sequence,
    DateTime? timestamp,
  }) {
    return ClipboardData(
      formats: formats ?? this.formats,
      sequence: sequence ?? this.sequence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ClipboardData(sequence: $sequence, formats: ${formats.keys}, timestamp: $timestamp)';
  }
}

/// 剪贴板格式枚举
enum ClipboardFormat {
  /// 纯文本
  text,

  /// HTML富文本
  html,

  /// RTF富文本
  rtf,

  /// 图片数据
  image,

  /// 文件列表
  files,

  /// 音频
  audio,

  /// 视频
  video,

  /// 自定义格式
  custom,
}

/// 扩展方法
extension ClipboardFormatExtension on ClipboardFormat {
  /// 获取格式的字符串表示
  String get value {
    switch (this) {
      case ClipboardFormat.text:
        return 'text';
      case ClipboardFormat.html:
        return 'html';
      case ClipboardFormat.rtf:
        return 'rtf';
      case ClipboardFormat.image:
        return 'image';
      case ClipboardFormat.files:
        return 'files';
      case ClipboardFormat.audio:
        return 'audio';
      case ClipboardFormat.video:
        return 'video';
      case ClipboardFormat.custom:
        return 'custom';
    }
  }

  /// 从字符串创建格式
  static ClipboardFormat fromString(String value) {
    return ClipboardFormat.values.firstWhere(
      (format) => format.value == value,
      orElse: () => ClipboardFormat.custom,
    );
  }
}
