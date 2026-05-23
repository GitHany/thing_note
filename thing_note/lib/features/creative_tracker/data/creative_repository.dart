import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/creative_project.dart';

final creativeRepositoryProvider = Provider<CreativeRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return CreativeRepository(dbAsync);
});

class CreativeRepository {
  final AsyncValue<Database> _dbAsync;

  CreativeRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertProject(CreativeProject project) async {
    final db = await _db;
    return await db.insert('creative_projects', project.toMap());
  }

  Future<List<CreativeProject>> getAllProjects() async {
    final db = await _db;
    final maps = await db.query('creative_projects', orderBy: 'updated_at DESC');
    return maps.map((m) => CreativeProject.fromMap(m)).toList();
  }

  Future<List<CreativeProject>> getProjectsByStatus(String status) async {
    final db = await _db;
    final maps = await db.query(
      'creative_projects',
      where: 'status = ?',
      whereArgs: [status],
    );
    return maps.map((m) => CreativeProject.fromMap(m)).toList();
  }

  Future<int> updateProject(CreativeProject project) async {
    final db = await _db;
    return await db.update(
      'creative_projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> insertSession(CreativeSession session) async {
    final db = await _db;
    return await db.insert('creative_sessions', session.toMap());
  }

  Future<List<CreativeSession>> getSessionsByProject(int projectId) async {
    final db = await _db;
    final maps = await db.query(
      'creative_sessions',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'session_date DESC',
    );
    return maps.map((m) => CreativeSession.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getCreativeStats({int days = 30}) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final projectsResult = await db.rawQuery('''
      SELECT COUNT(*) as total, 
             SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active
      FROM creative_projects
    ''');

    final sessionsResult = await db.rawQuery('''
      SELECT COUNT(*) as sessions,
             SUM(duration_minutes) as total_minutes,
             AVG(creativity_rating) as avg_creativity
      FROM creative_sessions
      WHERE session_date >= ?
    ''', [startDate.toIso8601String()]);

    return {
      ...projectsResult.first,
      ...sessionsResult.first,
    };
  }
}
