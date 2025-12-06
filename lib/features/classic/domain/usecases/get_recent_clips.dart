import 'package:clip_flow/features/classic/domain/entities/clip_entity.dart';
import 'package:clip_flow/features/classic/domain/repositories/clip_repository.dart';
import 'package:clip_flow/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Riverpod provider for use case
final getRecentClipsProvider = Provider<GetRecentClips>((ref) {
  final repo = ref.read(clipRepositoryProvider);
  return GetRecentClips(repo);
});
