import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/domain/record_repository.dart';

final recordListProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getAll();
});

final reminderCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getReminderCount();
});

final reminderRecordsProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getReminderRecords();
});

final recordDetailProvider =
    FutureProvider.family<EpisodeRecord?, int>((ref, id) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getById(id);
});

class RecordNotifier extends StateNotifier<AsyncValue<void>> {
  final RecordRepository _repo;

  RecordNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<EpisodeRecord> create(EpisodeRecord record) async {
    state = const AsyncValue.loading();
    final created = await _repo.create(record);
    state = const AsyncValue.data(null);
    return created;
  }

  Future<EpisodeRecord> update(EpisodeRecord record) async {
    state = const AsyncValue.loading();
    final updated = await _repo.update(record);
    state = const AsyncValue.data(null);
    return updated;
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
