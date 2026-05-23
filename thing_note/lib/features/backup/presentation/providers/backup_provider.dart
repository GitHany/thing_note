import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/backup/data/backup_repository.dart';
import 'package:thing_note/features/backup/data/backup_repository_impl.dart';
import 'package:thing_note/features/backup/domain/backup_entry.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});

final backupListProvider = FutureProvider<List<BackupEntry>>((ref) async {
  final repo = ref.read(backupRepositoryProvider);
  return repo.getAllBackups();
});

final restorePreviewProvider = FutureProvider.family<RestorePreview, String>((ref, backupId) async {
  final repo = ref.read(backupRepositoryProvider);
  return repo.getRestorePreview(backupId);
});

final backupConfigProvider = FutureProvider<BackupConfig>((ref) async {
  final repo = ref.read(backupRepositoryProvider);
  return repo.getBackupConfig();
});

final backupOperationProvider = StateNotifierProvider<BackupOperationNotifier, BackupOperationState>((ref) {
  return BackupOperationNotifier(ref);
});

class BackupOperationState {
  final bool isProcessing;
  final String? statusMessage;
  final double? progress;
  final BackupEntry? lastBackup;
  final String? error;

  const BackupOperationState({
    this.isProcessing = false,
    this.statusMessage,
    this.progress,
    this.lastBackup,
    this.error,
  });

  BackupOperationState copyWith({
    bool? isProcessing,
    String? statusMessage,
    double? progress,
    BackupEntry? lastBackup,
    String? error,
  }) {
    return BackupOperationState(
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      lastBackup: lastBackup ?? this.lastBackup,
      error: error,
    );
  }
}

class BackupOperationNotifier extends StateNotifier<BackupOperationState> {
  final Ref ref;

  BackupOperationNotifier(this.ref) : super(const BackupOperationState());

  Future<void> createBackup({bool isAuto = false}) async {
    if (state.isProcessing) return;

    state = state.copyWith(
      isProcessing: true,
      statusMessage: isAuto ? 'Creating incremental backup...' : 'Creating backup...',
      progress: 0,
    );

    try {
      final repo = ref.read(backupRepositoryProvider);

      state = state.copyWith(progress: 0.3);
      final backup = await repo.createBackup(isAuto: isAuto);

      state = state.copyWith(progress: 1.0, lastBackup: backup);

      // 清理旧备份
      final config = await repo.getBackupConfig();
      await repo.cleanOldBackups(config.maxBackupsToKeep);

      ref.invalidate(backupListProvider);

      state = state.copyWith(
        isProcessing: false,
        statusMessage: 'Backup created successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
        statusMessage: 'Backup failed',
      );
    }
  }

  Future<void> deleteBackup(String backupId) async {
    try {
      final repo = ref.read(backupRepositoryProvider);
      await repo.deleteBackup(backupId);
      ref.invalidate(backupListProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> restoreBackup(String backupId, {bool merge = false}) async {
    state = state.copyWith(
      isProcessing: true,
      statusMessage: 'Restoring backup...',
      progress: 0,
    );

    try {
      final repo = ref.read(backupRepositoryProvider);
      await repo.restoreBackup(backupId, merge: merge);

      state = state.copyWith(
        isProcessing: false,
        statusMessage: 'Restore completed',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
        statusMessage: 'Restore failed',
      );
    }
  }
}