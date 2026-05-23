import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/monthly_milestones/domain/monthly_milestone.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final milestonesRepositoryProvider = Provider<MilestonesRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MilestonesRepository(dbAsync);
});

final currentMonthMilestonesProvider = FutureProvider<List<MonthlyMilestone>>((ref) async {
  final repo = ref.watch(milestonesRepositoryProvider);
  final now = DateTime.now();
  return repo.getMilestonesForMonth(now.year, now.month);
});

class MilestonesRepository {
  final AsyncValue<Database> _dbAsync;

  MilestonesRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMilestone(MonthlyMilestone milestone) async {
    final db = await _db;
    return db.insert('monthly_milestones', milestone.toMap());
  }

  Future<int> updateMilestone(MonthlyMilestone milestone) async {
    final db = await _db;
    return db.update('monthly_milestones', milestone.toMap(), where: 'id = ?', whereArgs: [milestone.id]);
  }

  Future<int> deleteMilestone(int id) async {
    final db = await _db;
    return db.delete('monthly_milestones', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateProgress(int milestoneId, double progress, double currentValue) async {
    final db = await _db;
    final isCompleted = progress >= 1.0;
    return db.update(
      'monthly_milestones',
      {
        'current_value': currentValue,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [milestoneId],
    );
  }

  Future<List<MonthlyMilestone>> getMilestonesForMonth(int year, int month) async {
    final db = await _db;
    final maps = await db.query(
      'monthly_milestones',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => MonthlyMilestone.fromMap(m)).toList();
  }

  Future<List<MonthlyMilestone>> getActiveMilestones() async {
    final db = await _db;
    final now = DateTime.now();
    final maps = await db.query(
      'monthly_milestones',
      where: 'year > ? OR (year = ? AND month >= ?)',
      whereArgs: [now.year, now.year, now.month],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => MonthlyMilestone.fromMap(m)).toList();
  }

  Future<List<MonthlyMilestone>> getAllMilestones() async {
    final db = await _db;
    final maps = await db.query('monthly_milestones', orderBy: 'year DESC, month DESC');
    return maps.map((m) => MonthlyMilestone.fromMap(m)).toList();
  }

  Future<int> insertProgress(MilestoneProgress progress) async {
    final db = await _db;
    return db.insert('milestone_progress', progress.toMap());
  }

  Future<List<MilestoneProgress>> getProgressHistory(int milestoneId) async {
    final db = await _db;
    final maps = await db.query(
      'milestone_progress',
      where: 'milestone_id = ?',
      whereArgs: [milestoneId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => MilestoneProgress.fromMap(m)).toList();
  }

  Future<Map<String, int>> getMonthSummary(int year, int month) async {
    final milestones = await getMilestonesForMonth(year, month);
    final int total = milestones.length;
    final int completed = milestones.where((m) => m.isCompleted).length;
    return {'total': total, 'completed': completed};
  }
}
