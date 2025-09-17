import 'package:clip_flow_pro/features/home/domain/entities/clip_entity.dart';
import 'package:clip_flow_pro/features/home/domain/repositories/clip_repository.dart';

/// Use case to fetch recent clipboard items from repository.
class GetRecentClips {
  /// Creates a use case wrapping a [ClipRepository].
  const GetRecentClips(this._repo);

  final ClipRepository _repo;

  /// Executes the use case.
  /// Returns the list of recent clips with optional [limit].
  Future<List<ClipEntity>> call({int limit = 50}) {
    return _repo.fetchRecent(limit: limit);
  }
}
