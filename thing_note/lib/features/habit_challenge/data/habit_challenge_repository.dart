import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_challenge/domain/habit_challenge.dart';

class HabitChallengeRepository {
  final Ref _ref;

  HabitChallengeRepository(this._ref);

  Future<List<HabitChallenge>> getAllChallenges() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'habit_challenges',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => HabitChallenge.fromMap(e)).toList();
  }

  Future<List<HabitChallenge>> getActiveChallenges() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'habit_challenges',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => HabitChallenge.fromMap(e)).toList();
  }

  Future<int> insertChallenge(HabitChallenge challenge) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('habit_challenges', challenge.toMap()..remove('id'));
  }

  Future<int> updateChallenge(HabitChallenge challenge) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'habit_challenges',
      challenge.toMap(),
      where: 'id = ?',
      whereArgs: [challenge.id],
    );
  }

  Future<int> deleteChallenge(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('habit_challenges', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementStreak(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.rawUpdate(
      'UPDATE habit_challenges SET current_streak = current_streak + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> resetStreak(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'habit_challenges',
      {'current_streak': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> archiveChallenge(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'habit_challenges',
      {'is_active': 0, 'end_date': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}