import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_suggestions/domain/suggestion_models.dart';

final smartSuggestionsRepositoryProvider = Provider<SmartSuggestionsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartSuggestionsRepository(dbAsync);
});

final smartSuggestionsProvider = StateNotifierProvider<SmartSuggestionsNotifier, AsyncValue<List<SmartSuggestion>>>((ref) {
  final repository = ref.watch(smartSuggestionsRepositoryProvider);
  return SmartSuggestionsNotifier(repository);
});

final pendingSuggestionsProvider = Provider<List<SmartSuggestion>>((ref) {
  final suggestions = ref.watch(smartSuggestionsProvider);
  return suggestions.whenOrNull(
    data: (list) => list.where((s) => !s.isAccepted).toList(),
  ) ?? [];
});

final moodMatrixProvider = FutureProvider<List<MoodMatrixData>>((ref) async {
  final repository = ref.watch(smartSuggestionsRepositoryProvider);
  return repository.getMoodMatrixData();
});

class SmartSuggestionsRepository {
  final AsyncValue<Database> _dbAsync;

  SmartSuggestionsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Suggestions CRUD
  Future<int> insertSuggestion(SmartSuggestion suggestion) async {
    final db = await _db;
    return db.insert('smart_suggestions', suggestion.toMap());
  }

  Future<int> updateSuggestion(SmartSuggestion suggestion) async {
    final db = await _db;
    return db.update('smart_suggestions', suggestion.toMap(), where: 'id = ?', whereArgs: [suggestion.id]);
  }

  Future<int> deleteSuggestion(int id) async {
    final db = await _db;
    return db.delete('smart_suggestions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SmartSuggestion>> getAllSuggestions() async {
    final db = await _db;
    final maps = await db.query('smart_suggestions', orderBy: 'confidence_score DESC');
    return maps.map((m) => SmartSuggestion.fromMap(m)).toList();
  }

  Future<List<SmartSuggestion>> getPendingSuggestions() async {
    final db = await _db;
    final maps = await db.query(
      'smart_suggestions',
      where: 'is_accepted = 0',
      orderBy: 'confidence_score DESC, created_at DESC',
    );
    return maps.map((m) => SmartSuggestion.fromMap(m)).toList();
  }

  Future<void> acceptSuggestion(int id) async {
    final db = await _db;
    await db.update(
      'smart_suggestions',
      {'is_accepted': 1, 'accepted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // History
  Future<int> addToHistory(SuggestionHistory history) async {
    final db = await _db;
    return db.insert('suggestion_history', history.toMap());
  }

  Future<List<SuggestionHistory>> getHistory({int limit = 50}) async {
    final db = await _db;
    final maps = await db.query('suggestion_history', orderBy: 'created_at DESC', limit: limit);
    return maps.map((m) => SuggestionHistory.fromMap(m)).toList();
  }

  // Mood Matrix
  Future<int> upsertMoodMatrix(MoodMatrixData data) async {
    final db = await _db;
    final existing = await db.query(
      'mood_matrix_data',
      where: 'activity_name = ? AND energy_level = ?',
      whereArgs: [data.activityName, data.energyLevel],
    );
    
    if (existing.isNotEmpty) {
      final current = MoodMatrixData.fromMap(existing.first);
      final updated = current.copyWith(
        moodImpactScore: ((current.moodImpactScore * current.sampleCount) + data.moodImpactScore) / (current.sampleCount + 1),
        sampleCount: current.sampleCount + 1,
        lastUpdated: DateTime.now(),
      );
      return db.update('mood_matrix_data', updated.toMap(), where: 'id = ?', whereArgs: [current.id]);
    } else {
      return db.insert('mood_matrix_data', data.toMap());
    }
  }

  Future<List<MoodMatrixData>> getMoodMatrixData() async {
    final db = await _db;
    final maps = await db.query('mood_matrix_data', orderBy: 'sample_count DESC');
    return maps.map((m) => MoodMatrixData.fromMap(m)).toList();
  }

  // Generate suggestions based on patterns
  Future<List<SmartSuggestion>> generateSuggestions() async {
    final suggestions = <SmartSuggestion>[];
    final db = await _db;

    // Analyze habit patterns
    final habitLogs = await db.rawQuery('''
      SELECT habit_id FROM habit_logs 
      WHERE completed_at >= date('now', '-7 days')
      GROUP BY habit_id
      HAVING COUNT(*) < 3
    ''');

    if (habitLogs.isNotEmpty) {
      suggestions.add(SmartSuggestion(
        suggestionType: 'habit',
        title: '坚持你的习惯',
        description: '你有一些习惯最近打卡较少，尝试每天坚持它们',
        confidenceScore: 0.85,
        createdAt: DateTime.now(),
      ));
    }

    // Analyze record patterns - suggest based on time of day
    final morningRecords = await db.rawQuery('''
      SELECT COUNT(*) as count FROM episode_records
      WHERE occurred_at LIKE '% 06:__:%' OR occurred_at LIKE '% 07:__:%' OR occurred_at LIKE '% 08:__:%'
    ''');

    if ((morningRecords.first['count'] as int) > 5) {
      suggestions.add(SmartSuggestion(
        suggestionType: 'record',
        title: '早间记录习惯',
        description: '你倾向于早起记录，早起后第一件事就记录吧',
        confidenceScore: 0.78,
        createdAt: DateTime.now(),
      ));
    }

    return suggestions;
  }

  // Get best activities for current energy/mood
  Future<List<MoodMatrixData>> getBestActivities(int energyLevel, {int limit = 5}) async {
    final db = await _db;
    final maps = await db.query(
      'mood_matrix_data',
      where: 'energy_level = ?',
      whereArgs: [energyLevel],
      orderBy: 'mood_impact_score DESC',
      limit: limit,
    );
    return maps.map((m) => MoodMatrixData.fromMap(m)).toList();
  }
}

class SmartSuggestionsNotifier extends StateNotifier<AsyncValue<List<SmartSuggestion>>> {
  final SmartSuggestionsRepository _repository;

  SmartSuggestionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSuggestions();
  }

  Future<void> loadSuggestions() async {
    state = const AsyncValue.loading();
    try {
      var suggestions = await _repository.getAllSuggestions();
      
      // Generate new suggestions if needed
      if (suggestions.where((s) => !s.isAccepted).isEmpty) {
        final newSuggestions = await _repository.generateSuggestions();
        for (final s in newSuggestions) {
          await _repository.insertSuggestion(s);
        }
        suggestions = await _repository.getAllSuggestions();
      }
      
      state = AsyncValue.data(suggestions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptSuggestion(int id) async {
    try {
      await _repository.acceptSuggestion(id);
      await _repository.addToHistory(SuggestionHistory(
        suggestionId: id,
        accepted: true,
        createdAt: DateTime.now(),
      ));
      await loadSuggestions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> dismissSuggestion(int id) async {
    try {
      await _repository.deleteSuggestion(id);
      await _repository.addToHistory(SuggestionHistory(
        suggestionId: id,
        accepted: false,
        createdAt: DateTime.now(),
      ));
      await loadSuggestions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}