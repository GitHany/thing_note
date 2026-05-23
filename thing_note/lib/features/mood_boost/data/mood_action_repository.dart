import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_boost/domain/mood_action.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final moodActionRepositoryProvider = Provider<MoodActionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodActionRepository(dbAsync);
});

final moodActionsProvider = StateNotifierProvider<MoodActionsNotifier, AsyncValue<List<MoodAction>>>((ref) {
  final repository = ref.watch(moodActionRepositoryProvider);
  return MoodActionsNotifier(repository);
});

final currentMoodProvider = StateProvider<int>((ref) => 3);

class MoodActionRepository {
  final AsyncValue<Database> _dbAsync;

  MoodActionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertAction(MoodAction action) async {
    final db = await _db;
    return db.insert('mood_actions', action.toMap());
  }

  Future<List<MoodAction>> getActionsByMoodLevel(int moodLevel) async {
    final db = await _db;
    final maps = await db.query(
      'mood_actions',
      where: 'mood_level = ?',
      whereArgs: [moodLevel],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => MoodAction.fromMap(m)).toList();
  }

  Future<int> deleteAction(int id) async {
    final db = await _db;
    return db.delete('mood_actions', where: 'id = ?', whereArgs: [id]);
  }
}

class MoodActionsNotifier extends StateNotifier<AsyncValue<List<MoodAction>>> {
  final MoodActionRepository _repository;

  MoodActionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadActions();
  }

  Future<void> loadActions() async {
    state = const AsyncValue.loading();
    try {
      // Load preset actions for each mood level
      final actions = <MoodAction>[];
      for (int i = 1; i <= 5; i++) {
        final preset = PresetMoodAction.presets.firstWhere(
          (p) => p.moodLevel == i,
          orElse: () => PresetMoodAction(
            moodLevel: i,
            actionName: '休息',
            icon: Icons.self_improvement,
            actionType: 'rest',
          ),
        );
        actions.add(MoodAction(
          moodLevel: i,
          actionName: preset.actionName,
          actionType: preset.actionType,
          createdAt: DateTime.now(),
        ));
      }
      state = AsyncValue.data(actions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAction(MoodAction action) async {
    try {
      await _repository.insertAction(action);
      await loadActions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}