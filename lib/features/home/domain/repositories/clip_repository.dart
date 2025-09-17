import 'package:clip_flow_pro/features/home/domain/entities/clip_entity.dart';

/// Repository contract for clipboard items persistence/query.
abstract class ClipRepository {
  /// Returns recent clipboard items limited by [limit].
  Future<List<ClipEntity>> fetchRecent({int limit = 50});

  /// Persists a clipboard [item].
  Future<void> save(ClipEntity item);

  /// Deletes an item by [id].
  Future<void> delete(String id);
}
