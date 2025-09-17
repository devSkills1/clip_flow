/// Domain entity representing a clipboard item.
class ClipEntity {
  /// Creates a clipboard item with unique [id], raw [content] and [createdAt] time.
  const ClipEntity({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
}
