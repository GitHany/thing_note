import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/goal_milestone_alerts/domain/goal_milestone.dart';

final goalMilestoneRepositoryProvider = Provider<GoalMilestoneRepository>((ref) {
  return GoalMilestoneRepository(ref.watch(databaseProvider.future));
});

class GoalMilestoneRepository {
  final Future<Database> _dbFuture;

  GoalMilestoneRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<GoalMilestone>> getAllMilestones() async {
    final db = await _db;
    final results = await db.query('goal_milestones', orderBy: 'created_at DESC');
    return results.map((e) => GoalMilestone.fromMap(e)).toList();
  }

  Future<List<GoalMilestone>> getUncelebratedMilestones() async {
    final db = await _db;
    final results = await db.query(
      'goal_milestones',
      where: 'is_celebrated = ?',
      whereArgs: [0],
      orderBy: 'milestone_value DESC',
    );
    return results.map((e) => GoalMilestone.fromMap(e)).toList();
  }

  Future<int> insertMilestone(GoalMilestone milestone) async {
    final db = await _db;
    return await db.insert('goal_milestones', milestone.toMap()..remove('id'));
  }

  Future<int> markAsCelebrated(int id) async {
    final db = await _db;
    return await db.update(
      'goal_milestones',
      {
        'is_celebrated': 1,
        'celebration_note': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> initializeDefaultMilestones() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM goal_milestones')) ?? 0;

    if (count == 0) {
      final defaults = [
        GoalMilestone(goalId: 1, milestoneType: '50%', milestoneValue: 50),
        GoalMilestone(goalId: 1, milestoneType: '100%', milestoneValue: 100),
        GoalMilestone(goalId: 2, milestoneType: '25%', milestoneValue: 25),
      ];

      for (final milestone in defaults) {
        await db.insert('goal_milestones', milestone.toMap()..remove('id'));
      }
    }
  }
}