import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/data_integrity/domain/data_integrity_model.dart';

final dataIntegrityRepositoryProvider = Provider<DataIntegrityRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DataIntegrityRepository(dbAsync);
});

class DataIntegrityRepository {
  final AsyncValue<Database> _dbAsync;

  DataIntegrityRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<DataHealthScore> runFullCheck() async {
    final db = await _db;
    final issues = <DataIntegrityIssue>[];

    issues.addAll(await _checkOrphanedRecords());
    issues.addAll(await _checkMissingMedia());
    issues.addAll(await _checkInvalidDates());
    issues.addAll(await _checkLargeFiles());

    final totalRecords = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records');
    final total = (totalRecords.first['count'] as int?) ?? 1;

    final issueCount = issues.length;
    final penalty = (issueCount / total * 100).clamp(0, 50);
    final overallScore = (100 - penalty).round();

    return DataHealthScore(
      overallScore: overallScore,
      orphanCount: issues.where((i) => i.issueType == 'orphaned_record').length,
      missingMediaCount: issues.where((i) => i.issueType == 'missing_media').length,
      invalidDateCount: issues.where((i) => i.issueType == 'invalid_date').length,
      largeFileCount: issues.where((i) => i.issueType == 'large_file').length,
      issues: issues,
    );
  }

  Future<List<DataIntegrityIssue>> _checkOrphanedRecords() async {
    final db = await _db;
    final issues = <DataIntegrityIssue>[];

    final records = await db.query('episode_records');
    final thingNames = await db.query('thing_names');
    final validIds = thingNames.map((t) => t['id']).toSet();

    for (final record in records) {
      final thingNameId = record['thing_name_id'];
      if (thingNameId != null && !validIds.contains(thingNameId)) {
        issues.add(DataIntegrityIssue(
          issueType: 'orphaned_record',
          severity: 'medium',
          description: '记录 ${record['id']} 引用了不存在的事情名称',
          recordId: record['id'].toString(),
        ));
      }
    }

    return issues;
  }

  Future<List<DataIntegrityIssue>> _checkMissingMedia() async {
    return [];
  }

  Future<List<DataIntegrityIssue>> _checkInvalidDates() async {
    final db = await _db;
    final issues = <DataIntegrityIssue>[];

    final records = await db.query('episode_records');

    for (final record in records) {
      final occurredAt = record['occurred_at'] as String?;
      if (occurredAt != null) {
        try {
          final date = DateTime.parse(occurredAt);
          if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
            issues.add(DataIntegrityIssue(
              issueType: 'invalid_date',
              severity: 'low',
              description: '记录 ${record['id']} 的日期在未来',
              recordId: record['id'].toString(),
            ));
          }
        } catch (e) {
          issues.add(DataIntegrityIssue(
            issueType: 'invalid_date',
            severity: 'high',
            description: '记录 ${record['id']} 的日期格式无效',
            recordId: record['id'].toString(),
          ));
        }
      }
    }

    return issues;
  }

  Future<List<DataIntegrityIssue>> _checkLargeFiles() async {
    return [];
  }

  Future<int> saveIssue(DataIntegrityIssue issue) async {
    final db = await _db;
    return await db.insert('data_integrity_issues', issue.toMap());
  }

  Future<List<DataIntegrityIssue>> getAllIssues() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_integrity_issues',
      orderBy: 'severity DESC, detected_at DESC',
    );
    return maps.map((map) => DataIntegrityIssue.fromMap(map)).toList();
  }

  Future<List<DataIntegrityIssue>> getUnresolvedIssues() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'data_integrity_issues',
      where: 'is_resolved = 0',
      orderBy: 'severity DESC, detected_at DESC',
    );
    return maps.map((map) => DataIntegrityIssue.fromMap(map)).toList();
  }

  Future<int> markIssueResolved(int id) async {
    final db = await _db;
    return await db.update(
      'data_integrity_issues',
      {'is_resolved': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteResolvedIssues() async {
    final db = await _db;
    return await db.delete(
      'data_integrity_issues',
      where: 'is_resolved = 1',
    );
  }
}
