import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/momentum_models.dart';

final momentumRepositoryProvider = Provider<MomentumRepository>((ref) {
  return MomentumRepository(ref.watch(databaseProvider).value!);
});

class MomentumRepository {
  final Database _db;

  MomentumRepository(this._db);

  Future<int> insert(GoalMomentum momentum) async {
    return await _db.insert('goal_momentum', momentum.toMap());
  }

  Future<int> update(GoalMomentum momentum) async {
    return await _db.update(
      'goal_momentum',
      momentum.toMap(),
      where: 'id = ?',
      whereArgs: [momentum.id],
    );
  }

  Future<GoalMomentum?> getByGoal(int goalId) async {
    final maps = await _db.query(
      'goal_momentum',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    if (maps.isEmpty) return null;
    return GoalMomentum.fromMap(maps.first);
  }

  Future<List<GoalMomentum>> getAllMomentum() async {
    final maps = await _db.query('goal_momentum', orderBy: 'momentum_score DESC');
    return maps.map((m) => GoalMomentum.fromMap(m)).toList();
  }

  Future<List<GoalMomentum>> getAtRiskMomentum() async {
    final maps = await _db.query(
      'goal_momentum',
      where: 'momentum_score < 40',
      orderBy: 'momentum_score ASC',
    );
    return maps.map((m) => GoalMomentum.fromMap(m)).toList();
  }

  Future<void> updateMomentumForGoal(int goalId, int streakDays, double weeklyProgress) async {
    final momentum = await getByGoal(goalId);
    final score = _calculateMomentumScore(streakDays, weeklyProgress);

    if (momentum != null) {
      final updated = momentum.copyWith(
        streakDays: streakDays,
        weeklyProgress: weeklyProgress,
        momentumScore: score,
        lastUpdated: DateTime.now(),
      );
      await update(updated);
    } else {
      final newMomentum = GoalMomentum(
        goalId: goalId,
        streakDays: streakDays,
        weeklyProgress: weeklyProgress,
        momentumScore: score,
      );
      await insert(newMomentum);
    }
  }

  double _calculateMomentumScore(int streakDays, double weeklyProgress) {
    // Simple momentum calculation
    final streakScore = (streakDays * 5).clamp(0, 50).toDouble();
    final progressScore = (weeklyProgress * 2).clamp(0, 50).toDouble();
    return streakScore + progressScore;
  }
}

extension GoalMomentumCopy on GoalMomentum {
  GoalMomentum copyWith({
    int? id,
    int? goalId,
    double? momentumScore,
    int? streakDays,
    double? weeklyProgress,
    double? monthlyProgress,
    DateTime? predictedCompletion,
    List<String>? riskFactors,
    double? accelerationScore,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return GoalMomentum(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      momentumScore: momentumScore ?? this.momentumScore,
      streakDays: streakDays ?? this.streakDays,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
      predictedCompletion: predictedCompletion ?? this.predictedCompletion,
      riskFactors: riskFactors ?? this.riskFactors,
      accelerationScore: accelerationScore ?? this.accelerationScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}