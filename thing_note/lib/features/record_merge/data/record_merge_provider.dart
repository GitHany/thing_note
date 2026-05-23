import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_merge/domain/record_merge.dart';
import 'package:thing_note/features/record_merge/data/record_merge_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final recordMergeRepositoryProvider = FutureProvider<RecordMergeRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return RecordMergeRepository(db);
});

final mergePreviewProvider = FutureProvider.family<MergePreview, (int, List<int>)>((ref, params) async {
  final repo = await ref.watch(recordMergeRepositoryProvider.future);
  return repo.generatePreview(params.$1, params.$2);
});

final mergeHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = await ref.watch(recordMergeRepositoryProvider.future);
  return repo.getMergeHistory();
});

class RecordMergeNotifier extends StateNotifier<AsyncValue<MergeResult?>> {
  RecordMergeNotifier() : super(const AsyncValue.data(null));

  Future<MergeResult> merge(RecordMergeConfig config) async {
    final result = MergeResult(
      targetRecordId: config.targetRecordId,
      sourceRecordsMerged: config.sourceRecordIds.length,
      photosAdded: 0,
      audioAdded: 0,
      videoAdded: 0,
      documentsAdded: 0,
      tagsMerged: const [],
      locationUpdated: false,
      mergedAt: DateTime.now(),
    );
    state = AsyncValue.data(result);
    return result;
  }
}

final recordMergeNotifierProvider = StateNotifierProvider<RecordMergeNotifier, AsyncValue<MergeResult?>>((ref) {
  return RecordMergeNotifier();
});