// ignore_for_file: public_member_api_docs
// Reason: Internal module with documented interfaces at higher level
// 忽略公共成员API文档要求，因为这是内部数据仓库实现，已有类级别文档说明
import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/core/services/sync/index.dart';
import 'package:clip_flow_pro/features/home/domain/entities/clip_entity.dart';
import 'package:clip_flow_pro/features/home/domain/repositories/clip_repository.dart';

/// 剪贴板历史仓库实现类
/// 实现剪贴板历史仓库接口，通过调用 [DatabaseService] 映射到数据库操作。
class ClipRepositoryImpl implements ClipRepository {
  ClipRepositoryImpl(
    DatabaseService db, {
    ICloudSyncService? icloudSyncService,
  })  : _db = db,
        _icloudSyncService = icloudSyncService;

  final DatabaseService _db;
  final ICloudSyncService? _icloudSyncService;

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
    _syncToICloud((service) => service.upsertClipItem(clip));
  }

  @override
  Future<void> delete(String id) async {
    await _db.deleteClipItem(id);
    _syncToICloud((service) => service.deleteClipItem(id));
  }

  @override
  Future<void> updateFavoriteStatus({required String id, required bool isFavorite}) async {
    await _db.updateFavoriteStatus(id: id, isFavorite: isFavorite);
    _syncToICloud((service) async {
      final clip = await _db.getClipItemById(id);
      if (clip != null) {
        await service.upsertClipItem(clip);
      }
    });
  }

  void _syncToICloud(
    Future<void> Function(ICloudSyncService service) operation,
  ) {
    final service = _icloudSyncService;
    if (service == null || !service.isAvailable) return;

    unawaited(() async {
      try {
        await operation(service);
      } on Exception catch (e, stackTrace) {
        await Log.w(
          'iCloud sync task failed',
          tag: 'ClipRepositoryImpl',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }());
  }
}
