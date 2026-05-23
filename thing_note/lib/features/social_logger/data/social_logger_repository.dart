import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/social_interaction.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(databaseProvider).value!);
});

// Statistics providers
final socialStatsProvider = FutureProvider<SocialStats>((ref) async {
  return await ref.watch(socialRepositoryProvider).getStats();
});

final interactionSummaryProvider = FutureProvider<List<PersonSummary>>((ref) async {
  return await ref.watch(socialRepositoryProvider).getPersonSummary();
});

final pendingFollowUpsProvider = FutureProvider<List<SocialInteraction>>((ref) async {
  return await ref.watch(socialRepositoryProvider).getPendingFollowUps();
});

// Main state notifier
final socialLoggerProvider = StateNotifierProvider<SocialLoggerNotifier, SocialLoggerState>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return SocialLoggerNotifier(repository);
});

class SocialLoggerState {
  final List<SocialInteraction> interactions;
  final bool isLoading;
  final String? error;

  const SocialLoggerState({
    this.interactions = const [],
    this.isLoading = false,
    this.error,
  });

  SocialLoggerState copyWith({
    List<SocialInteraction>? interactions,
    bool? isLoading,
    String? error,
  }) {
    return SocialLoggerState(
      interactions: interactions ?? this.interactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SocialLoggerNotifier extends StateNotifier<SocialLoggerState> {
  final SocialRepository _repository;

  SocialLoggerNotifier(this._repository) : super(const SocialLoggerState()) {
    loadInteractions();
  }

  Future<void> loadInteractions() async {
    state = state.copyWith(isLoading: true);
    try {
      final interactions = await _repository.getAllInteractions();
      state = state.copyWith(interactions: interactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addInteraction(SocialInteraction interaction) async {
    try {
      await _repository.insertInteraction(interaction);
      await loadInteractions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteInteraction(int id) async {
    try {
      await _repository.deleteInteraction(id);
      await loadInteractions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateInteraction(SocialInteraction interaction) async {
    try {
      await _repository.updateInteraction(interaction);
      await loadInteractions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Statistics models
class SocialStats {
  final int totalInteractions;
  final int uniquePeople;
  final int totalMinutes;
  final double avgQuality;

  const SocialStats({
    this.totalInteractions = 0,
    this.uniquePeople = 0,
    this.totalMinutes = 0,
    this.avgQuality = 0,
  });

  factory SocialStats.fromMap(Map<String, dynamic> map) {
    return SocialStats(
      totalInteractions: (map['total_interactions'] as int?) ?? 0,
      uniquePeople: (map['unique_people'] as int?) ?? 0,
      totalMinutes: (map['total_minutes'] as int?) ?? 0,
      avgQuality: (map['avg_quality'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PersonSummary {
  final String personName;
  final int interactionCount;
  final int totalMinutes;
  final double avgQuality;

  const PersonSummary({
    required this.personName,
    this.interactionCount = 0,
    this.totalMinutes = 0,
    this.avgQuality = 0,
  });

  factory PersonSummary.fromMap(Map<String, dynamic> map) {
    return PersonSummary(
      personName: map['person_name'] as String,
      interactionCount: (map['interaction_count'] as int?) ?? 0,
      totalMinutes: (map['total_minutes'] as int?) ?? 0,
      avgQuality: (map['avg_quality'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SocialRepository {
  final Database _db;

  SocialRepository(this._db);

  Future<int> insertInteraction(SocialInteraction interaction) async {
    return await _db.insert('social_interactions', interaction.toMap());
  }

  Future<int> updateInteraction(SocialInteraction interaction) async {
    return await _db.update(
      'social_interactions',
      interaction.toMap(),
      where: 'id = ?',
      whereArgs: [interaction.id],
    );
  }

  Future<int> deleteInteraction(int id) async {
    return await _db.delete(
      'social_interactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SocialInteraction>> getAllInteractions() async {
    final maps = await _db.query('social_interactions', orderBy: 'interaction_date DESC');
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<SocialInteraction>> getInteractionsByPerson(String personName) async {
    final maps = await _db.query(
      'social_interactions',
      where: 'person_name = ?',
      whereArgs: [personName],
      orderBy: 'interaction_date DESC',
    );
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<SocialInteraction>> getInteractionsByDateRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'social_interactions',
      where: 'interaction_date >= ? AND interaction_date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'interaction_date DESC',
    );
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<SocialInteraction>> getPendingFollowUps() async {
    final maps = await _db.query(
      'social_interactions',
      where: 'follow_up_needed = ?',
      whereArgs: [1],
      orderBy: 'interaction_date DESC',
    );
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<PersonSummary>> getPersonSummary({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT person_name,
             COUNT(*) as interaction_count,
             SUM(duration_minutes) as total_minutes,
             AVG(quality_rating) as avg_quality
      FROM social_interactions
      WHERE interaction_date >= ?
      GROUP BY person_name
      ORDER BY interaction_count DESC
    ''', [startDate.toIso8601String()]);
    return result.map((m) => PersonSummary.fromMap(m)).toList();
  }

  Future<SocialStats> getStats({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as total_interactions,
             COUNT(DISTINCT person_name) as unique_people,
             SUM(duration_minutes) as total_minutes,
             AVG(quality_rating) as avg_quality
      FROM social_interactions
      WHERE interaction_date >= ?
    ''', [startDate.toIso8601String()]);
    return SocialStats.fromMap(result.first);
  }
}