import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_tournament/domain/tournament_models.dart';

final habitTournamentRepositoryProvider = Provider<HabitTournamentRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitTournamentRepository(dbAsync);
});

final habitTournamentsProvider = StateNotifierProvider<HabitTournamentsNotifier, AsyncValue<List<HabitTournament>>>((ref) {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return HabitTournamentsNotifier(repository);
});

final tournamentParticipantsProvider = FutureProvider.family<List<TournamentParticipant>, int>((ref, tournamentId) async {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return repository.getParticipants(tournamentId);
});

final goalTreesProvider = StateNotifierProvider<GoalTreesNotifier, AsyncValue<List<GoalTree>>>((ref) {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return GoalTreesNotifier(repository);
});

final reminderPatternsProvider = StateNotifierProvider<ReminderPatternsNotifier, AsyncValue<List<ReminderPattern>>>((ref) {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return ReminderPatternsNotifier(repository);
});

final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, AsyncValue<Map<String, String>>>((ref) {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return PrivacySettingsNotifier(repository);
});

final moodJournalsProvider = StateNotifierProvider<MoodJournalsNotifier, AsyncValue<List<MoodJournal>>>((ref) {
  final repository = ref.watch(habitTournamentRepositoryProvider);
  return MoodJournalsNotifier(repository);
});

class HabitTournamentRepository {
  final AsyncValue<Database> _dbAsync;

  HabitTournamentRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Tournament CRUD
  Future<int> insertTournament(HabitTournament tournament) async {
    final db = await _db;
    return db.insert('habit_tournaments', tournament.toMap());
  }

  Future<int> updateTournament(HabitTournament tournament) async {
    final db = await _db;
    return db.update('habit_tournaments', tournament.toMap(), where: 'id = ?', whereArgs: [tournament.id]);
  }

  Future<int> deleteTournament(int id) async {
    final db = await _db;
    return db.delete('habit_tournaments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitTournament>> getAllTournaments() async {
    final db = await _db;
    final maps = await db.query('habit_tournaments', orderBy: 'start_date DESC');
    return maps.map((m) => HabitTournament.fromMap(m)).toList();
  }

  Future<List<HabitTournament>> getActiveTournaments() async {
    final db = await _db;
    final maps = await db.query(
      'habit_tournaments',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => HabitTournament.fromMap(m)).toList();
  }

  // Participant CRUD
  Future<int> joinTournament(TournamentParticipant participant) async {
    final db = await _db;
    return db.insert('tournament_participants', participant.toMap());
  }

  Future<List<TournamentParticipant>> getParticipants(int tournamentId) async {
    final db = await _db;
    final maps = await db.query(
      'tournament_participants',
      where: 'tournament_id = ?',
      whereArgs: [tournamentId],
      orderBy: 'rank ASC',
    );
    return maps.map((m) => TournamentParticipant.fromMap(m)).toList();
  }

  Future<void> updateParticipantStats(int participantId, int streak, int score) async {
    final db = await _db;
    await db.update(
      'tournament_participants',
      {'current_streak': streak, 'total_score': score},
      where: 'id = ?',
      whereArgs: [participantId],
    );
  }

  // Goal Tree CRUD
  Future<int> insertGoalTree(GoalTree tree) async {
    final db = await _db;
    return db.insert('goal_trees', tree.toMap());
  }

  Future<int> deleteGoalTree(int id) async {
    final db = await _db;
    return db.delete('goal_trees', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GoalTree>> getAllGoalTrees() async {
    final db = await _db;
    final maps = await db.query('goal_trees', orderBy: 'created_at DESC');
    return maps.map((m) => GoalTree.fromMap(m)).toList();
  }

  Future<List<GoalNode>> getGoalNodes(int treeId) async {
    final db = await _db;
    final maps = await db.query(
      'goal_nodes',
      where: 'tree_id = ?',
      whereArgs: [treeId],
      orderBy: 'level ASC, sort_order ASC',
    );
    return maps.map((m) => GoalNode.fromMap(m)).toList();
  }

  Future<int> insertGoalNode(GoalNode node) async {
    final db = await _db;
    return db.insert('goal_nodes', node.toMap());
  }

  // Reminder Pattern CRUD
  Future<int> insertReminderPattern(ReminderPattern pattern) async {
    final db = await _db;
    return db.insert('reminder_patterns', pattern.toMap());
  }

  Future<List<ReminderPattern>> getAllReminderPatterns() async {
    final db = await _db;
    final maps = await db.query('reminder_patterns', orderBy: 'success_rate DESC');
    return maps.map((m) => ReminderPattern.fromMap(m)).toList();
  }

  Future<void> updatePatternStats(int patternId, bool triggered, bool success) async {
    final db = await _db;
    final maps = await db.query('reminder_patterns', where: 'id = ?', whereArgs: [patternId]);
    if (maps.isEmpty) return;
    
    final pattern = ReminderPattern.fromMap(maps.first);
    final newTriggers = pattern.totalTriggers + 1;
    final newSuccessRate = triggered && success 
        ? (pattern.successRate * pattern.totalTriggers + 1) / newTriggers
        : (pattern.successRate * pattern.totalTriggers) / newTriggers;
    
    await db.update(
      'reminder_patterns',
      {
        'total_triggers': newTriggers,
        'success_rate': newSuccessRate,
        'last_triggered': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [patternId],
    );
  }

  // Privacy Settings CRUD
  Future<void> setPrivacySetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'privacy_settings',
      {
        'setting_key': key,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPrivacySetting(String key) async {
    final db = await _db;
    final maps = await db.query(
      'privacy_settings',
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['setting_value'] as String;
  }

  Future<Map<String, String>> getAllPrivacySettings() async {
    final db = await _db;
    final maps = await db.query('privacy_settings');
    return {for (final m in maps) m['setting_key'] as String: m['setting_value'] as String};
  }

  // Mood Journal CRUD
  Future<int> insertMoodJournal(MoodJournal journal) async {
    final db = await _db;
    return db.insert('mood_journals', journal.toMap());
  }

  Future<int> updateMoodJournal(MoodJournal journal) async {
    final db = await _db;
    return db.update('mood_journals', journal.toMap(), where: 'id = ?', whereArgs: [journal.id]);
  }

  Future<int> deleteMoodJournal(int id) async {
    final db = await _db;
    return db.delete('mood_journals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoodJournal>> getAllMoodJournals() async {
    final db = await _db;
    final maps = await db.query('mood_journals', orderBy: 'date DESC');
    return maps.map((m) => MoodJournal.fromMap(m)).toList();
  }

  Future<MoodJournal?> getMoodJournalByDate(DateTime date) async {
    final db = await _db;
    final maps = await db.query(
      'mood_journals',
      where: 'date(date) = date(?)',
      whereArgs: [date.toIso8601String()],
    );
    if (maps.isEmpty) return null;
    return MoodJournal.fromMap(maps.first);
  }

  Future<List<MoodJournal>> getMoodJournalsRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'mood_journals',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => MoodJournal.fromMap(m)).toList();
  }
}

class HabitTournamentsNotifier extends StateNotifier<AsyncValue<List<HabitTournament>>> {
  final HabitTournamentRepository _repository;

  HabitTournamentsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    state = const AsyncValue.loading();
    try {
      final tournaments = await _repository.getAllTournaments();
      state = AsyncValue.data(tournaments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTournament(HabitTournament tournament) async {
    try {
      await _repository.insertTournament(tournament);
      await loadTournaments();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinTournament(int tournamentId, String name) async {
    try {
      final participant = TournamentParticipant(
        tournamentId: tournamentId,
        participantName: name,
        joinedAt: DateTime.now(),
      );
      await _repository.joinTournament(participant);
    } catch (_) {}
  }
}

class GoalTreesNotifier extends StateNotifier<AsyncValue<List<GoalTree>>> {
  final HabitTournamentRepository _repository;

  GoalTreesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTrees();
  }

  Future<void> loadTrees() async {
    state = const AsyncValue.loading();
    try {
      final trees = await _repository.getAllGoalTrees();
      state = AsyncValue.data(trees);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTree(GoalTree tree) async {
    try {
      await _repository.insertGoalTree(tree);
      await loadTrees();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTree(int id) async {
    try {
      await _repository.deleteGoalTree(id);
      await loadTrees();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ReminderPatternsNotifier extends StateNotifier<AsyncValue<List<ReminderPattern>>> {
  final HabitTournamentRepository _repository;

  ReminderPatternsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPatterns();
  }

  Future<void> loadPatterns() async {
    state = const AsyncValue.loading();
    try {
      final patterns = await _repository.getAllReminderPatterns();
      state = AsyncValue.data(patterns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PrivacySettingsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  final HabitTournamentRepository _repository;

  PrivacySettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getAllPrivacySettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      await _repository.setPrivacySetting(key, value);
      await loadSettings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class MoodJournalsNotifier extends StateNotifier<AsyncValue<List<MoodJournal>>> {
  final HabitTournamentRepository _repository;

  MoodJournalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadJournals();
  }

  Future<void> loadJournals() async {
    state = const AsyncValue.loading();
    try {
      final journals = await _repository.getAllMoodJournals();
      state = AsyncValue.data(journals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addJournal(MoodJournal journal) async {
    try {
      await _repository.insertMoodJournal(journal);
      await loadJournals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateJournal(MoodJournal journal) async {
    try {
      await _repository.updateMoodJournal(journal);
      await loadJournals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteJournal(int id) async {
    try {
      await _repository.deleteMoodJournal(id);
      await loadJournals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}