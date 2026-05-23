import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:thing_note/features/backup/data/backup_repository.dart';
import 'package:thing_note/features/backup/domain/backup_entry.dart';

class BackupRepositoryImpl implements BackupRepository {
  @override
  Future<List<BackupEntry>> getAllBackups() async {
    final backupDir = await getBackupDirectory();
    final dir = Directory(backupDir);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return [];
    }

    final entries = <BackupEntry>[];
    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.zip')) {
        final stat = await file.stat();
        final fileName = p.basename(file.path);
        final isAuto = fileName.contains('_auto_');

        entries.add(BackupEntry(
          id: file.path,
          fileName: fileName,
          createdAt: stat.modified,
          fileSize: stat.size,
          recordCount: 0, // 从备份内容读取
          isAutoBackup: isAuto,
          type: isAuto ? BackupType.incremental : BackupType.full,
        ));
      }
    }

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Future<RestorePreview> getRestorePreview(String backupId) async {
    // TODO: 实现从 zip 文件读取预览
    return const RestorePreview(
      records: [],
      recordsByThingName: {},
      totalRecords: 0,
    );
  }

  @override
  Future<void> restoreBackup(String backupId, {bool merge = false}) async {
    // TODO: 实现从备份恢复
    throw UnimplementedError('Restore not implemented yet');
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    final file = File(backupId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<BackupEntry> createBackup({bool isAuto = false}) async {
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now();
    final timestampStr = _formatTimestamp(timestamp);
    final prefix = isAuto ? '_auto_' : '_manual_';
    final fileName = 'thing_note_backup$prefix$timestampStr.zip';
    final filePath = p.join(backupDir, fileName);

    // TODO: 实现实际备份逻辑
    // 1. 读取所有记录
    // 2. 序列化为 JSON
    // 3. 压缩为 ZIP
    // 4. 保存到文件

    final file = File(filePath);
    await file.create(recursive: true);

    final stat = await file.stat();

    return BackupEntry(
      id: filePath,
      fileName: fileName,
      createdAt: timestamp,
      fileSize: stat.size,
      recordCount: 0, // 实际实现时统计
      isAutoBackup: isAuto,
      type: isAuto ? BackupType.incremental : BackupType.full,
    );
  }

  @override
  Future<BackupEntry> createIncrementalBackup() async {
    return createBackup(isAuto: true);
  }

  @override
  Future<String> getBackupDirectory() async {
    // 返回应用备份目录
    return p.join(await _getAppDirectory(), 'backups');
  }

  @override
  Future<BackupConfig> getBackupConfig() async {
    // TODO: 从 SharedPreferences 读取
    return const BackupConfig();
  }

  @override
  Future<void> saveBackupConfig(BackupConfig config) async {
    // TODO: 保存到 SharedPreferences
  }

  @override
  Future<void> cleanOldBackups(int maxToKeep) async {
    final backups = await getAllBackups();
    if (backups.length <= maxToKeep) return;

    // 按时间排序，删除最旧的
    final toDelete = backups.skip(maxToKeep).toList();
    for (final backup in toDelete) {
      await deleteBackup(backup.id);
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}_${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
  }

  Future<String> _getAppDirectory() async {
    // 这里应该使用 path_provider 获取应用目录
    return '.';
  }
}