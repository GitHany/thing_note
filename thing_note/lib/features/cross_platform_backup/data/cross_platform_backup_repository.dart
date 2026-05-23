import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/cross_platform_backup/domain/backup_models.dart';
import 'package:thing_note/core/database/database_provider.dart';

final crossPlatformBackupRepositoryProvider = Provider((ref) => CrossPlatformBackupRepository(ref));

class CrossPlatformBackupRepository {
  final Ref _ref;

  CrossPlatformBackupRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<BackupEntry>> getAllBackups() async {
    final db = await _db;
    final results = await db.query('backups', orderBy: 'created_at DESC');
    return results.map((e) => BackupEntry.fromMap(e)).toList();
  }

  Future<int> saveBackupEntry(BackupEntry entry) async {
    final db = await _db;
    return await db.insert('backups', entry.toMap());
  }

  Future<void> deleteBackupEntry(int id) async {
    final db = await _db;
    await db.delete('backups', where: 'id = ?', whereArgs: [id]);
  }

  /// Create a backup of the database
  Future<BackupEntry> createBackup({
    String? name,
    bool compress = true,
    bool encrypt = false,
  }) async {
    final db = await _db;
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Get database path
    final dbPath = await getDatabasesPath();
    final dbFilePath = '$dbPath/thing_note.db';
    
    // Create backup name
    final backupName = name ?? 'backup_$timestamp';
    final backupDir = Directory('${appDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    // Copy database file
    final backupFilePath = '${backupDir.path}/$backupName.db';
    final dbFile = File(dbFilePath);
    if (await dbFile.exists()) {
      await dbFile.copy(backupFilePath);
    }
    
    // Get record count
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records');
    final recordCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    // Get file size
    final backupFile = File(backupFilePath);
    final fileSize = await backupFile.length();
    
    final entry = BackupEntry(
      name: backupName,
      createdAt: DateTime.now(),
      sizeBytes: fileSize,
      recordCount: recordCount,
      destination: 'local',
    );
    
    await saveBackupEntry(entry);
    return entry;
  }

  /// Restore from a backup file
  Future<bool> restoreBackup(BackupEntry entry) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFilePath = '${appDir.path}/backups/${entry.name}.db';
      
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return false;
      }
      
      // Get current database path
      final dbPath = await getDatabasesPath();
      final currentDbPath = '$dbPath/thing_note.db';
      
      // Close current database connection first
      final db = await _db;
      await db.close();
      
      // Copy backup file to database location
      await backupFile.copy(currentDbPath);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get backup file path
  Future<String> getBackupFilePath(String backupName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/backups/$backupName.db';
  }

  /// Delete backup file
  Future<void> deleteBackupFile(String backupName) async {
    final filePath = await getBackupFilePath(backupName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get total backup size
  Future<int> getTotalBackupSize() async {
    final backups = await getAllBackups();
    return backups.fold<int>(0, (sum, b) => sum + b.sizeBytes);
  }

  /// Clean old backups
  Future<int> cleanOldBackups(int retentionDays) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final backups = await getAllBackups();
    
    int deletedCount = 0;
    for (final backup in backups) {
      if (backup.createdAt.isBefore(cutoffDate)) {
        await deleteBackupFile(backup.name);
        await deleteBackupEntry(backup.id!);
        deletedCount++;
      }
    }
    
    return deletedCount;
  }

  /// Export backup to external location
  Future<String?> exportBackup(BackupEntry entry, String targetPath) async {
    try {
      final sourcePath = await getBackupFilePath(entry.name);
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        return null;
      }
      
      final targetFile = File(targetPath);
      await sourceFile.copy(targetFile.path);
      
      return targetFile.path;
    } catch (e) {
      return null;
    }
  }
}