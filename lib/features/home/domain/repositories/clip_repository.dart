import '../entities/clip_entity.dart';

abstract class ClipRepository {
  Future<List<ClipEntity>> fetchRecent({int limit = 50});
  Future<void> save(ClipEntity item);
  Future<void> delete(String id);
}