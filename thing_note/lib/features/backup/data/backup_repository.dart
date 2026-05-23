import 'package:thing_note/features/backup/domain/backup_entry.dart';
abstract class BackupRepository {
  Future<List<BackupEntry>> getAllBackups();
  Future<RestorePreview> getRestorePreview(String backupId);
  Future<void> restoreBackup(String backupId, {bool merge = false});
  Future<void> deleteBackup(String backupId);
  Future<BackupEntry> createBackup({bool isAuto = false});
  Future<BackupEntry> createIncrementalBackup();
  Future<String> getBackupDirectory();
  Future<BackupConfig> getBackupConfig();
  Future<void> saveBackupConfig(BackupConfig config);
  Future<void> cleanOldBackups(int maxToKeep);
}