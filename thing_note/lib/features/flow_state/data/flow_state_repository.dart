import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/flow_state/domain/flow_state.dart';

final flowStateRepositoryProvider = Provider<FlowStateRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FlowStateRepository(dbAsync);
});

class FlowStateRepository {
  final AsyncValue<Database> _dbAsync;

  FlowStateRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insert(FlowState flowState) async {
    final db = await _db;
    return await db.insert('flow_states', flowState.toMap());
  }

  Future<int> update(FlowState flowState) async {
    final db = await _db;
    return await db.update(
      'flow_states',
      flowState.toMap(),
      where: 'id = ?',
      whereArgs: [flowState.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'flow_states',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<FlowState?> getById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FlowState.fromMap(maps.first);
  }

  Future<FlowState?> getActiveFlowState() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FlowState.fromMap(maps.first);
  }

  Future<List<FlowState>> getRecent(int limit) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((map) => FlowState.fromMap(map)).toList();
  }

  Future<List<FlowState>> getTodayFlowStates() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      where: 'date(started_at) = ?',
      whereArgs: [today],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => FlowState.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as session_count,
        SUM(duration_minutes) as total_minutes,
        AVG(focus_rating) as avg_focus_rating,
        SUM(distraction_count) as total_distractions
      FROM flow_states
      WHERE date(started_at) = ? AND ended_at IS NOT NULL
    ''', [today]);

    final sessions = result.first;
    return {
      'sessionCount': sessions['session_count'] as int? ?? 0,
      'totalMinutes': sessions['total_minutes'] as int? ?? 0,
      'avgFocusRating': (sessions['avg_focus_rating'] as num?)?.toDouble() ?? 0,
      'totalDistractions': sessions['total_distractions'] as int? ?? 0,
    };
  }

  Future<Map<String, dynamic>> getWeekStats() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as session_count,
        SUM(duration_minutes) as total_minutes,
        AVG(focus_rating) as avg_focus_rating
      FROM flow_states
      WHERE started_at >= datetime('now', '-7 days') AND ended_at IS NOT NULL
    ''');

    final sessions = result.first;
    return {
      'sessionCount': sessions['session_count'] as int? ?? 0,
      'totalMinutes': sessions['total_minutes'] as int? ?? 0,
      'avgFocusRating': (sessions['avg_focus_rating'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<FlowState>> getFlowStatesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      where: 'date(started_at) >= ? AND date(started_at) <= ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => FlowState.fromMap(map)).toList();
  }

  Future<List<FlowState>> getLinkedRecordFlowStates(int recordId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'flow_states',
      where: 'linked_record_id = ?',
      whereArgs: [recordId],
      orderBy: 'started_at DESC',
    );
    return maps.map((map) => FlowState.fromMap(map)).toList();
  }
}
