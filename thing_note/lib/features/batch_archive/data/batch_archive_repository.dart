import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/batch_archive/domain/batch_archive_model.dart';

final batchArchiveRepositoryProvider = Provider<BatchArchiveRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return BatchArchiveRepository(dbAsync);
});

class BatchArchiveRepository {
  final AsyncValue<Database> _dbAsync;

  BatchArchiveRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> createArchiveJob(ArchiveJob job) async {
    final db = await _db;
    return await db.insert('archive_jobs', job.toMap());
  }

  Future<int> updateArchiveJob(ArchiveJob job) async {
    final db = await _db;
    return await db.update(
      'archive_jobs',
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<List<ArchiveJob>> getAllJobs() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'archive_jobs',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ArchiveJob.fromMap(map)).toList();
  }

  Future<ArchiveJob?> getJobById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'archive_jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ArchiveJob.fromMap(maps.first);
  }

  Future<int> markJobRunning(int id) async {
    final db = await _db;
    return await db.update(
      'archive_jobs',
      {'status': 'running'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markJobCompleted(int id, int recordsAffected, int storageFreed) async {
    final db = await _db;
    return await db.update(
      'archive_jobs',
      {
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'records_affected': recordsAffected,
        'storage_freed': storageFreed,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markJobFailed(int id, String error) async {
    final db = await _db;
    return await db.update(
      'archive_jobs',
      {
        'status': 'failed',
        'error': error,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOldJobs({int daysOld = 90}) async {
    final db = await _db;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'archive_jobs',
      where: 'status IN (?, ?) AND created_at < ?',
      whereArgs: ['completed', 'failed', cutoffDate.toIso8601String()],
    );
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _db;
    final totalJobs = await db.rawQuery('SELECT COUNT(*) as count FROM archive_jobs');
    final completedJobs = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(records_affected) as total_records, SUM(storage_freed) as total_freed FROM archive_jobs WHERE status = ?',
      ['completed']
    );
    final pendingJobs = await db.rawQuery(
      'SELECT COUNT(*) as count FROM archive_jobs WHERE status = ?',
      ['pending']
    );

    return {
      'total_jobs': (totalJobs.first['count'] as int?) ?? 0,
      'completed_jobs': (completedJobs.first['count'] as int?) ?? 0,
      'total_records_archived': (completedJobs.first['total_records'] as int?) ?? 0,
      'total_storage_freed': (completedJobs.first['total_freed'] as int?) ?? 0,
      'pending_jobs': (pendingJobs.first['count'] as int?) ?? 0,
    };
  }

  Future<ArchiveConfig> getConfig() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'archive_config',
      limit: 1,
    );
    if (maps.isEmpty) {
      return ArchiveConfig();
    }
    return ArchiveConfig.fromMap(maps.first);
  }

  Future<void> saveConfig(ArchiveConfig config) async {
    final db = await _db;
    final existing = await db.query('archive_config', limit: 1);

    if (existing.isEmpty) {
      await db.insert('archive_config', config.toMap());
    } else {
      await db.update(
        'archive_config',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<List<int>> runAutoArchive() async {
    final db = await _db;
    final config = await getConfig();
    if (!config.autoArchiveEnabled) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: config.autoArchiveDays));
    final archivedRecordIds = <int>[];

    final records = await db.query(
      'episode_records',
      where: 'occurred_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    for (final record in records) {
      archivedRecordIds.add(record['id'] as int);
    }

    return archivedRecordIds;
  }
}
