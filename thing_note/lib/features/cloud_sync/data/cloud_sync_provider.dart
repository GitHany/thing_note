import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/cloud_sync/data/cloud_sync_repository.dart';
import 'package:thing_note/features/cloud_sync/domain/cloud_sync_queue.dart';

final cloudSyncRepositoryProvider = Provider((ref) => CloudSyncRepository(ref));

final pendingItemsProvider = FutureProvider<List<CloudSyncQueue>>((ref) async {
  final repo = ref.read(cloudSyncRepositoryProvider);
  return repo.getPendingItems();
});

final syncQueueStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(cloudSyncRepositoryProvider);
  return repo.getQueueStats();
});