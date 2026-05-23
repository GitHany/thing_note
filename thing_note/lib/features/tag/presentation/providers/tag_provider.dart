import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/tag/data/tag_repository_impl.dart';
import 'package:thing_note/features/tag/domain/tag.dart';
import 'package:thing_note/features/tag/domain/tag_repository.dart';

// Repository provider
final tagRepositoryProvider = FutureProvider<TagRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TagRepositoryImpl(db);
});

// Tag list provider
final tagListProvider = FutureProvider<List<Tag>>((ref) async {
  final repo = await ref.watch(tagRepositoryProvider.future);
  return repo.getAllTags();
});

// Tags for a specific record
final tagsForRecordProvider = FutureProvider.family<List<Tag>, int>((ref, recordId) async {
  final repo = await ref.watch(tagRepositoryProvider.future);
  return repo.getTagsForRecord(recordId);
});

// Batch load tags for multiple records - returns Map<recordId, List<Tag>>
final tagsForRecordsProvider = FutureProvider.family<Map<int, List<Tag>>, List<int>>((ref, recordIds) async {
  if (recordIds.isEmpty) return {};
  final repo = await ref.watch(tagRepositoryProvider.future);
  return repo.getTagsForRecords(recordIds);
});

// Tag notifier for mutations
class TagNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final Ref _ref;

  TagNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final repo = await _ref.read(tagRepositoryProvider.future);
      final tags = await repo.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(tagListProvider);
    await _init();
  }

  Future<int> createTag(Tag tag) async {
    final repo = await _ref.read(tagRepositoryProvider.future);
    final id = await repo.createTag(tag);
    await refresh();
    return id;
  }

  Future<void> updateTag(Tag tag) async {
    final repo = await _ref.read(tagRepositoryProvider.future);
    await repo.updateTag(tag);
    await refresh();
  }

  Future<void> deleteTag(int id) async {
    final repo = await _ref.read(tagRepositoryProvider.future);
    await repo.deleteTag(id);
    await refresh();
  }
}

// Initialize notifier with repository - use overrideWith to ensure proper initialization
final tagNotifierProvider = StateNotifierProvider<TagNotifier, AsyncValue<List<Tag>>>((ref) {
  return TagNotifier(ref);
});