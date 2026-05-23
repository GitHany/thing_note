import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/domain/record_repository.dart';

final recordListProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getAll();
});

// Records linked to a specific record
final linkedRecordsProvider = FutureProvider.family<List<EpisodeRecord>, int>((ref, recordId) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getLinkedRecords(recordId);
});

final reminderCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getReminderCount();
});

final reminderRecordsProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getReminderRecords();
});

final favoriteCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getFavoriteCount();
});

final favoriteRecordsProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getFavoriteRecords();
});

// Recurring records count provider
final recurringCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  final records = await repo.getAll();
  return records.where((r) => r.isRecurring).length;
});

final recordDetailProvider =
    FutureProvider.family<EpisodeRecord?, int>((ref, id) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getById(id);
});

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(recordRepositoryProvider);
  return repo.search(query);
});

// Records by tag
final recordsByTagProvider = FutureProvider.family<List<EpisodeRecord>, int>((ref, tagId) async {
  final repo = ref.watch(recordRepositoryProvider);
  return repo.getRecordsByTag(tagId);
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

  Future<void> createLink(int recordIdA, int recordIdB) async {
    state = const AsyncValue.loading();
    await _repo.createLink(recordIdA, recordIdB);
    state = const AsyncValue.data(null);
  }

  Future<void> deleteLink(int linkId) async {
    state = const AsyncValue.loading();
    await _repo.deleteLink(linkId);
    state = const AsyncValue.data(null);
  }
}

final recordNotifierProvider =
    StateNotifierProvider<RecordNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(recordRepositoryProvider);
  return RecordNotifier(repo);
});
