import '../repositories/clip_repository.dart';
import '../entities/clip_entity.dart';

class GetRecentClips {
  const GetRecentClips(this._repo);

  final ClipRepository _repo;

  Future<List<ClipEntity>> call({int limit = 50}) {
    return _repo.fetchRecent(limit: limit);
  }
}