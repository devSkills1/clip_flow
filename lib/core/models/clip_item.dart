import 'package:clip_flow_pro/core/services/id_generator.dart';
import 'package:meta/meta.dart';

/// 剪贴内容类型：表示剪贴板条目的数据类型，用于解析与渲染。
enum ClipType {
  /// 纯文本（UTF-16 codeUnits）
  text,

  /// 富文本（RTF 格式）
  rtf,

  /// HTML 片段
  html,

  /// 图片（二进制）
  image,

  /// 颜色（如 #RRGGBB 或 ARGB）
  color,

  /// 文件（路径或引用元数据）
  file,

  /// 音频内容
  audio,

  /// 视频内容
  video,

  /// URL链接
  url,

  /// 邮箱地址
  email,

  /// JSON数据
  json,

  /// XML数据
  xml,

  /// 代码内容
  code,
}

/**
*/
////
/// 剪贴项数据模型：表示一次剪贴板历史记录（条目）。
/// - 包含类型、内容、缩略图与元数据等；
/// - 提供 JSON 序列化/反序列化；
/// - 提供不可变式的 copyWith 便于局部更新。
@immutable
class ClipItem {
  /// 构造函数：若未指定 id/时间戳，将自动生成
  ClipItem({
    required this.type,
    required this.metadata,
    this.content,
    this.filePath,
    String? id,
    this.thumbnail,
    this.isFavorite = false,
    this.ocrText,
    this.ocrTextId,
    this.parentImageId,
    this.isOcrExtracted = false,
    this.originWidth,
    this.originHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? IdGenerator.generateId(type, content, filePath, metadata),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 构建剪贴项
  factory ClipItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final typeName = json['type'] as String?;
    final contentRaw = json['content'];
    final filePathRaw = json['filePath'] ?? json['file_path'];
    final thumbRaw = json['thumbnail'];
    final metadataRaw = json['metadata'];
    final isFavRaw = json['isFavorite'];
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final ocrTextRaw = json['ocrText'];
    final ocrTextIdRaw = json['ocrTextId'];
    final parentImageIdRaw = json['parentImageId'];
    final isOcrExtractedRaw = json['isOcrExtracted'];
    final originWidthRaw = json['originWidth'];
    final originHeightRaw = json['originHeight'];

    return ClipItem(
      id: id,
      type: ClipType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => ClipType.text,
      ),
      content: contentRaw is String ? contentRaw : contentRaw?.toString(),
      filePath: filePathRaw is String ? filePathRaw : null,
      thumbnail: thumbRaw is List ? List<int>.from(thumbRaw) : null,
      metadata: metadataRaw is Map<String, dynamic>
          ? metadataRaw
          : (metadataRaw is Map
                ? Map<String, dynamic>.from(metadataRaw)
                : <String, dynamic>{}),
      isFavorite: isFavRaw is bool ? isFavRaw : (isFavRaw == 1),
      ocrText: ocrTextRaw is String ? ocrTextRaw : null,
      ocrTextId: ocrTextIdRaw is String ? ocrTextIdRaw : null,
      parentImageId: parentImageIdRaw is String ? parentImageIdRaw : null,
      isOcrExtracted: isOcrExtractedRaw is bool ? isOcrExtractedRaw : false,
      originWidth: originWidthRaw is num ? originWidthRaw.toInt() : null,
      originHeight: originHeightRaw is num ? originHeightRaw.toInt() : null,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
          : (updatedAtRaw is DateTime ? updatedAtRaw : DateTime.now()),
    );
  }

  /// 基于内容生成唯一ID

  /// 主键（UUID）：唯一标识该条剪贴记录
  final String id;

  /// 剪贴类型：见 [ClipType]
  final ClipType type;

  /// 文本内容（UTF-8），非文本类型为空；媒体路径见 [filePath]
  final String? content;

  /// 媒体相对路径：media/{type}/yyyy/MM/dd/{uuid}.{ext}
  final String? filePath;

  /// 缩略图字节：用于图片/视频等的快速展示，可能为空
  final List<int>? thumbnail;

  /// 附加元数据：如来源应用、文件路径、MIME 类型、颜色格式等
  final Map<String, dynamic> metadata;

  /// 是否收藏：用于界面筛选与置顶等功能
  final bool isFavorite;

  /// OCR识别的文本内容：用于图片中的文字搜索
  final String? ocrText;

  /// OCR文本的独立ID：用于OCR文本的独立身份标识
  final String? ocrTextId;

  /// OCR文本的父图片ID：用于建立OCR文本与原图片的关联关系
  final String? parentImageId;

  /// 是否已提取OCR文本：标识该图片是否已进行OCR识别
  final bool isOcrExtracted;

  /// 图片原始宽度（像素）：用于图片尺寸计算和布局
  final int? originWidth;

  /// 图片原始高度（像素）：用于图片尺寸计算和布局
  final int? originHeight;

  /// 创建时间：该条目首次创建的时间
  final DateTime createdAt;

  /// 更新时间：该条目最后一次更新的时间
  final DateTime updatedAt;

  /// 复制并更新指定字段：保持不可变语义，返回更新后的新实例
  ClipItem copyWith({
    String? id,
    ClipType? type,
    String? content,
    String? filePath,
    List<int>? thumbnail,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    String? ocrText,
    String? ocrTextId,
    String? parentImageId,
    bool? isOcrExtracted,
    int? originWidth,
    int? originHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClipItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      thumbnail: thumbnail ?? this.thumbnail,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      ocrText: ocrText ?? this.ocrText,
      ocrTextId: ocrTextId ?? this.ocrTextId,
      parentImageId: parentImageId ?? this.parentImageId,
      isOcrExtracted: isOcrExtracted ?? this.isOcrExtracted,
      originWidth: originWidth ?? this.originWidth,
      originHeight: originHeight ?? this.originHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 序列化为 JSON：用于持久化与跨进程/网络传输
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'filePath': filePath,
      'thumbnail': thumbnail,
      'metadata': metadata,
      'isFavorite': isFavorite,
      'ocrText': ocrText,
      'ocrTextId': ocrTextId,
      'parentImageId': parentImageId,
      'isOcrExtracted': isOcrExtracted,
      'originWidth': originWidth,
      'originHeight': originHeight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 按 id 判断相等：用于集合判重与 Diff
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipItem && other.id == id;
  }

  /// 使用 id 作为哈希：与 == 一致
  @override
  int get hashCode => id.hashCode;

  /// 调试输出：便于日志与调试定位
  @override
  String toString() {
    return 'ClipItem(id: $id, type: $type, isFavorite: $isFavorite)';
  }
}
