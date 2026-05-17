import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/domain/record_repository.dart';

final recordListProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getAll();
});

final recordDetailProvider =
    FutureProvider.family<EpisodeRecord?, int>((ref, id) {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getById(id);
});

class RecordNotifier extends StateNotifier<AsyncValue<void>> {
  final RecordRepository _repo;

  RecordNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> create(EpisodeRecord record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.create(record));
  }

  Future<void> update(EpisodeRecord record) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.update(record));
  }

  Future<void> delete(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.delete(id));
  }
}

final recordNotifierProvider =
    StateNotifierProvider<RecordNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(recordRepositoryProvider);
  return RecordNotifier(repo);
});
