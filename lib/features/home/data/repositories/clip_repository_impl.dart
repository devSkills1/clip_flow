// ignore_for_file: public_member_api_docs
// 忽略公共成员API文档要求，因为这是内部数据仓库实现，已有类级别文档说明
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/features/home/domain/entities/clip_entity.dart';
import 'package:clip_flow_pro/features/home/domain/repositories/clip_repository.dart';

/// 剪贴板历史仓库实现类
/// 实现剪贴板历史仓库接口，通过调用 [DatabaseService] 映射到数据库操作。
class ClipRepositoryImpl implements ClipRepository {
  ClipRepositoryImpl(DatabaseService db) : _db = db;

  final DatabaseService _db;

  @override
  Future<List<ClipEntity>> fetchRecent({int limit = 50}) async {
    final items = await _db.getAllClipItems(limit: limit);
    return items.map((e) {
      final text = e.content ?? '';
      return ClipEntity(id: e.id, content: text, createdAt: e.createdAt);
    }).toList();
  }

  @override
  Future<void> save(ClipEntity item) async {
    // 以字符串持久化
    final clip = ClipItem(
      id: item.id,
      type: ClipType.text,
      content: item.content,
      metadata: const {},
      createdAt: item.createdAt,
      updatedAt: item.createdAt,
    );
    await _db.insertClipItem(clip);
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteClipItem(id);
  }

  @override
  Future<void> updateFavoriteStatus({required String id, required bool isFavorite}) async {
    await _db.updateFavoriteStatus(id: id, isFavorite: isFavorite);
  }
}
