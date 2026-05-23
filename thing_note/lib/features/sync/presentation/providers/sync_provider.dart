import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/sync/data/sync_repository.dart';
import 'package:thing_note/features/sync/data/sync_repository_impl.dart';
import 'package:thing_note/features/sync/domain/sync_service.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return LarkSyncRepositoryImpl();
});

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref);
});

final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.read(syncRepositoryProvider);
  return repo.getLastSyncTime();
});

final syncConfigProvider = FutureProvider<SyncConfig>((ref) async {
  final repo = ref.read(syncRepositoryProvider);
  return repo.getSyncConfig();
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final Ref ref;

  SyncStatusNotifier(this.ref) : super(SyncStatus.idle);

  Future<void> sync() async {
    if (state == SyncStatus.syncing) return;

    state = SyncStatus.syncing;
    try {
      final records = await ref.read(recordListProvider.future);
      final repo = ref.read(syncRepositoryProvider);
      await repo.syncRecords(records);
      state = SyncStatus.success;
      ref.invalidate(lastSyncTimeProvider);
    } catch (e) {
      state = SyncStatus.failed;
    }
  }

  void reset() {
    state = SyncStatus.idle;
  }
}