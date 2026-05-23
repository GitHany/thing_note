import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_version/domain/record_version.dart';
import 'package:thing_note/features/record_version/data/record_version_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final recordVersionRepositoryProvider = FutureProvider<RecordVersionRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return RecordVersionRepository(db);
});

final recordVersionsProvider = FutureProvider.family<List<RecordVersion>, int>((ref, recordId) async {
  final repo = await ref.watch(recordVersionRepositoryProvider.future);
  return repo.getVersionsForRecord(recordId);
});

class RecordVersionNotifier extends StateNotifier<AsyncValue<List<RecordVersion>>> {
  RecordVersionNotifier() : super(const AsyncValue.data([]));

  Future<void> loadVersions() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createVersion(RecordVersion version) async {
    // Placeholder
  }

  Future<RecordVersion?> restoreVersion(int versionId) async {
    return null;
  }
}

final recordVersionNotifierProvider = StateNotifierProvider<RecordVersionNotifier, AsyncValue<List<RecordVersion>>>((ref) {
  return RecordVersionNotifier();
});