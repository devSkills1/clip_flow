import 'package:uuid/uuid.dart';

enum ClipType { text, rtf, html, image, color, file, audio, video }

class ClipItem {
  final String id;
  final ClipType type;
  final List<int> content;
  final List<int>? thumbnail;
  final Map<String, dynamic> metadata;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClipItem({
    String? id,
    required this.type,
    required this.content,
    this.thumbnail,
    required this.metadata,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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

  factory ClipItem.fromJson(Map<String, dynamic> json) {
    return ClipItem(
      id: json['id'],
      type: ClipType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ClipType.text,
      ),
      content: List<int>.from(json['content']),
      thumbnail: json['thumbnail'] != null
          ? List<int>.from(json['thumbnail'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata']),
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
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
