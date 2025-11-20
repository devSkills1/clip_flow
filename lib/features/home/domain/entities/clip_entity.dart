// ignore_for_file: public_member_api_docs
// Reason: Internal module with documented interfaces at higher level
// 忽略公共成员API文档要求，因为这是领域实体类，已有类和构造函数级别文档说明

/// Domain entity representing a clipboard item.
class ClipEntity {
  /// Creates a clipboard item with unique [id], raw [content] and
  /// [createdAt] time.
  const ClipEntity({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
}
