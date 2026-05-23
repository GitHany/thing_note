import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/record_version/domain/record_version.dart';

class RecordVersionRepository {
  final Database db;

  RecordVersionRepository(this.db);

  Future<int> createVersion(RecordVersion version) async {
    return await db.insert('record_versions', version.toMap());
  }

  Future<List<RecordVersion>> getVersionsForRecord(int recordId) async {
    final maps = await db.query(
      'record_versions',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'version_at DESC',
    );
    return maps.map((m) => RecordVersion.fromMap(m)).toList();
  }

  Future<RecordVersion?> getVersion(int id) async {
    final maps = await db.query(
      'record_versions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RecordVersion.fromMap(maps.first);
  }

  Future<RecordVersion?> getLatestVersion(int recordId) async {
    final maps = await db.query(
      'record_versions',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'version_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RecordVersion.fromMap(maps.first);
  }

  Future<int> deleteVersion(int id) async {
    return await db.delete(
      'record_versions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVersionsForRecord(int recordId) async {
    return await db.delete(
      'record_versions',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  Future<int> getVersionCount(int recordId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM record_versions WHERE record_id = ?',
      [recordId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<List<RecordVersion>> getRecentVersions({int limit = 10}) async {
    final maps = await db.query(
      'record_versions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => RecordVersion.fromMap(m)).toList();
  }
}