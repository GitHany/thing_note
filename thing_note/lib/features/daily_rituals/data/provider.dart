import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/models.dart';

final dailyRitualsProvider = StateNotifierProvider<DailyRitualsNotifier, List<DailyRitual>>((ref) {
  return DailyRitualsNotifier(ref);
});

final ritualCompletionsProvider = FutureProvider.family<List<RitualCompletion>, DateTime>((ref, date) async {
  final db = await ref.read(databaseProvider.future);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final maps = await db.query(
    'ritual_completions',
    where: 'completed_at >= ? AND completed_at < ?',
    whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
  );

  return maps.map((m) => RitualCompletion.fromMap(m)).toList();
});

class DailyRitualsNotifier extends StateNotifier<List<DailyRitual>> {
  final Ref ref;

  DailyRitualsNotifier(this.ref) : super([]) {
    loadRituals();
  }

  Future<void> loadRituals() async {
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('daily_rituals', orderBy: 'order_index ASC');
    state = maps.map((m) => DailyRitual.fromMap(m)).toList();
  }

  Future<int> addRitual(DailyRitual ritual) async {
    final db = await ref.read(databaseProvider.future);
    final id = await db.insert('daily_rituals', ritual.toMap()..remove('id'));
    await loadRituals();
    return id;
  }

  Future<void> updateRitual(DailyRitual ritual) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('daily_rituals', ritual.toMap(), where: 'id = ?', whereArgs: [ritual.id]);
    await loadRituals();
  }

  Future<void> deleteRitual(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('daily_rituals', where: 'id = ?', whereArgs: [id]);
    await db.delete('ritual_completions', where: 'ritual_id = ?', whereArgs: [id]);
    await loadRituals();
  }

  Future<void> reorderRituals(List<DailyRitual> rituals) async {
    final db = await ref.read(databaseProvider.future);
    for (int i = 0; i < rituals.length; i++) {
      await db.update('daily_rituals', {'order_index': i}, where: 'id = ?', whereArgs: [rituals[i].id]);
    }
    await loadRituals();
  }

  Future<void> completeRitual(RitualCompletion completion) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('ritual_completions', completion.toMap()..remove('id'));
    ref.invalidate(ritualCompletionsProvider(DateTime.now()));
  }

  Future<void> uncompleteRitual(int ritualId, DateTime date) async {
    final db = await ref.read(databaseProvider.future);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    await db.delete(
      'ritual_completions',
      where: 'ritual_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [ritualId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    ref.invalidate(ritualCompletionsProvider(date));
  }
}