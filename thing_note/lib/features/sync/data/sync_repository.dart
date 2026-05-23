import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/sync/domain/sync_service.dart';

abstract class SyncRepository {
  Future<SyncResult> syncRecords(List<EpisodeRecord> records);
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<SyncConfig> getSyncConfig();
  Future<void> saveSyncConfig(SyncConfig config);
  Future<bool> isConnected();
}