import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/models.dart';

final milestonesProvider = StateNotifierProvider<MilestonesNotifier, List<PersonalMilestone>>((ref) {
  return MilestonesNotifier(ref);
});

final activeMilestonesProvider = Provider<List<PersonalMilestone>>((ref) {
  final milestones = ref.watch(milestonesProvider);
  return milestones.where((m) => !m.isCompleted).toList();
});

final completedMilestonesProvider = Provider<List<PersonalMilestone>>((ref) {
  final milestones = ref.watch(milestonesProvider);
  return milestones.where((m) => m.isCompleted).toList();
});

class MilestonesNotifier extends StateNotifier<List<PersonalMilestone>> {
  final Ref ref;

  MilestonesNotifier(this.ref) : super([]) {
    loadMilestones();
  }

  Future<void> loadMilestones() async {
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('personal_milestones', orderBy: 'created_at DESC');
    state = maps.map((m) => PersonalMilestone.fromMap(m)).toList();
  }

  Future<int> addMilestone(PersonalMilestone milestone) async {
    final db = await ref.read(databaseProvider.future);
    final id = await db.insert('personal_milestones', milestone.toMap()..remove('id'));
    await loadMilestones();
    return id;
  }

  Future<void> updateMilestone(PersonalMilestone milestone) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('personal_milestones', milestone.toMap(), where: 'id = ?', whereArgs: [milestone.id]);
    await loadMilestones();
  }

  Future<void> updateProgress(int id, int newValue) async {
    final db = await ref.read(databaseProvider.future);
    final milestone = state.firstWhere((m) => m.id == id);
    final isCompleted = newValue >= milestone.targetValue;
    await db.update(
      'personal_milestones',
      {
        'current_value': newValue,
        'is_completed': isCompleted ? 1 : 0,
        if (isCompleted) 'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadMilestones();
  }

  Future<void> deleteMilestone(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('personal_milestones', where: 'id = ?', whereArgs: [id]);
    await loadMilestones();
  }
}