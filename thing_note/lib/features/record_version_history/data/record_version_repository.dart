import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/record_version_history/domain/record_version.dart';

final recordVersionRepositoryProvider = Provider<RecordVersionRepository>((ref) {
  return RecordVersionRepository(ref.watch(databaseProvider.future));
});

class RecordVersionRepository {
  final Future<Database> _dbFuture;

  RecordVersionRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<RecordVersion>> getVersionsForRecord(int recordId) async {
    final db = await _db;
    final results = await db.query(
      'record_versions',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'version_number DESC',
    );
    return results.map((e) => RecordVersion.fromMap(e)).toList();
  }

  Future<int> createVersion(int recordId, String versionData, {String? changeSummary}) async {
    final db = await _db;

    final maxVersion = Sqflite.firstIntValue(
      await db.rawQuery('SELECT MAX(version_number) FROM record_versions WHERE record_id = ?', [recordId])
    ) ?? 0;

    return await db.insert('record_versions', {
      'record_id': recordId,
      'version_number': maxVersion + 1,
      'version_data': versionData,
      'change_summary': changeSummary,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> restoreVersion(int recordId, int versionNumber) async {
    final db = await _db;

    final version = await db.query(
      'record_versions',
      where: 'record_id = ? AND version_number = ?',
      whereArgs: [recordId, versionNumber],
    );

    if (version.isNotEmpty) {
      final versionData = version.first['version_data'] as String;
      await createVersion(recordId, versionData, changeSummary: '恢复到版本 $versionNumber');
    }
  }

  Future<void> initializeDefaultVersions() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM record_versions')) ?? 0;

    if (count == 0) {
      await db.insert('record_versions', {
        'record_id': 1,
        'version_number': 1,
        'version_data': '{"note": "初始版本"}',
        'change_summary': '初始创建',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}