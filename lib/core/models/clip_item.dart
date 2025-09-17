import 'package:uuid/uuid.dart';

enum ClipType { text, rtf, html, image, color, file, audio, video }

class ClipItem {
  ClipItem({
    required this.type,
    required this.content,
    required this.metadata,
    String? id,
    this.thumbnail,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ClipItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final typeName = json['type'] as String?;
    final contentRaw = json['content'];
    final thumbRaw = json['thumbnail'];
    final metadataRaw = json['metadata'];
    final isFavRaw = json['isFavorite'];
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];

    return ClipItem(
      id: id,
      type: ClipType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => ClipType.text,
      ),
      content: contentRaw is List ? List<int>.from(contentRaw) : <int>[],
      thumbnail: thumbRaw is List ? List<int>.from(thumbRaw) : null,
      metadata: metadataRaw is Map<String, dynamic>
          ? metadataRaw
          : (metadataRaw is Map
                ? Map<String, dynamic>.from(metadataRaw)
                : <String, dynamic>{}),
      isFavorite: isFavRaw is bool ? isFavRaw : (isFavRaw == 1),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
          : (updatedAtRaw is DateTime ? updatedAtRaw : DateTime.now()),
    );
  }
  final String id;
  final ClipType type;
  final List<int> content;
  final List<int>? thumbnail;
  final Map<String, dynamic> metadata;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClipItem copyWith({
    String? id,
    ClipType? type,
    List<int>? content,
    List<int>? thumbnail,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClipItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      thumbnail: thumbnail ?? this.thumbnail,
      metadata: metadata ?? this.metadata,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'thumbnail': thumbnail,
      'metadata': metadata,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ClipItem(id: $id, type: $type, isFavorite: $isFavorite)';
  }
}
