import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/enhanced_backup/domain/backup_config.dart';

class EnhancedBackupRepository {
  final Database db;

  EnhancedBackupRepository(this.db);

  Future<List<EnhancedBackupEntry>> getAllBackups() async {
    final maps = await db.query(
      'enhanced_backups',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => EnhancedBackupEntry.fromMap(m)).toList();
  }

  Future<int> saveBackup(EnhancedBackupEntry entry) async {
    return await db.insert('enhanced_backups', entry.toMap());
  }

  Future<int> deleteBackup(int id) async {
    return await db.delete(
      'enhanced_backups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BackupStats> getStats() async {
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_backups');
    final totalSize = await db.rawQuery('SELECT SUM(file_size_bytes) as total FROM enhanced_backups');
    final lastBackup = await db.rawQuery('SELECT MAX(created_at) as last FROM enhanced_backups');
    final avgSize = await db.rawQuery('SELECT AVG(file_size_bytes) as avg FROM enhanced_backups');

    final totalCount = count.first['count'] as int? ?? 0;
    final total = (totalSize.first['total'] as num?)?.toInt() ?? 0;
    final last = lastBackup.first['last'] as String?;
    final avg = (avgSize.first['avg'] as num?)?.toDouble() ?? 0;

    int lastBackupDays = 0;
    if (last != null) {
      final lastDate = DateTime.parse(last);
      lastBackupDays = DateTime.now().difference(lastDate).inDays;
    }

    return BackupStats(
      totalBackups: totalCount,
      totalSizeBytes: total,
      lastBackupDays: lastBackupDays,
      avgBackupSize: avg,
    );
  }

  // Schedule management
  Future<List<BackupSchedule>> getSchedules() async {
    final maps = await db.query(
      'backup_schedules',
      orderBy: 'name ASC',
    );
    return maps.map((m) => BackupSchedule.fromMap(m)).toList();
  }

  Future<int> saveSchedule(BackupSchedule schedule) async {
    return await db.insert('backup_schedules', schedule.toMap());
  }

  Future<int> updateSchedule(BackupSchedule schedule) async {
    return await db.update(
      'backup_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    return await db.delete(
      'backup_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleScheduleEnabled(int id, bool enabled) async {
    await db.update(
      'backup_schedules',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLastRun(int scheduleId) async {
    await db.update(
      'backup_schedules',
      {'last_run_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<List<BackupSchedule>> getDueSchedules() async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dayOfWeek = now.weekday.toString();
    final dayOfMonth = now.day.toString();

    final maps = await db.query(
      'backup_schedules',
      where: 'is_enabled = 1 AND (time_of_day = ? OR time_of_day IS NULL)',
      whereArgs: [timeStr],
    );

    final schedules = maps.map((m) => BackupSchedule.fromMap(m)).toList();

    return schedules.where((s) {
      if (s.frequency == 'daily') return true;
      if (s.frequency == 'weekly' && s.dayOfWeek == dayOfWeek) return true;
      if (s.frequency == 'monthly' && s.dayOfMonth == dayOfMonth) return true;
      return false;
    }).toList();
  }
}