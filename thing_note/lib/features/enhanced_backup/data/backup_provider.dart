import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_backup/domain/backup_config.dart';
import 'package:thing_note/features/enhanced_backup/data/backup_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final enhancedBackupRepositoryProvider = FutureProvider<EnhancedBackupRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return EnhancedBackupRepository(db);
});

final backupListProvider = FutureProvider<List<EnhancedBackupEntry>>((ref) async {
  final repo = await ref.watch(enhancedBackupRepositoryProvider.future);
  return repo.getAllBackups();
});

final backupStatsProvider = FutureProvider<BackupStats>((ref) async {
  final repo = await ref.watch(enhancedBackupRepositoryProvider.future);
  return repo.getStats();
});

final backupSchedulesProvider = FutureProvider<List<BackupSchedule>>((ref) async {
  final repo = await ref.watch(enhancedBackupRepositoryProvider.future);
  return repo.getSchedules();
});

class EnhancedBackupNotifier extends StateNotifier<AsyncValue<EnhancedBackupEntry?>> {
  EnhancedBackupNotifier() : super(const AsyncValue.data(null));

  Future<EnhancedBackupEntry> createBackup({
    String? name,
    String backupType = 'full',
    bool compress = true,
  }) async {
    final entry = EnhancedBackupEntry(
      name: name ?? 'Backup ${DateTime.now().toIso8601String()}',
      filePath: '',
      backupType: backupType,
      fileSizeBytes: 0,
      recordCount: 0,
      mediaCount: 0,
      createdAt: DateTime.now(),
      isCompressed: compress,
    );
    state = AsyncValue.data(entry);
    return entry;
  }

  Future<void> deleteBackup(int id) async {
    // Placeholder - would need repository
  }
}

final enhancedBackupNotifierProvider = StateNotifierProvider<EnhancedBackupNotifier, AsyncValue<EnhancedBackupEntry?>>((ref) {
  return EnhancedBackupNotifier();
});

/// Schedule management
class BackupScheduleNotifier extends StateNotifier<AsyncValue<List<BackupSchedule>>> {
  BackupScheduleNotifier() : super(const AsyncValue.data([]));

  Future<void> loadSchedules() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createSchedule(BackupSchedule schedule) async {
    // Placeholder
  }

  Future<void> updateSchedule(BackupSchedule schedule) async {
    // Placeholder
  }

  Future<void> deleteSchedule(int id) async {
    // Placeholder
  }

  Future<void> toggleEnabled(int id, bool enabled) async {
    // Placeholder
  }
}

final backupScheduleNotifierProvider = StateNotifierProvider<BackupScheduleNotifier, AsyncValue<List<BackupSchedule>>>((ref) {
  return BackupScheduleNotifier();
});