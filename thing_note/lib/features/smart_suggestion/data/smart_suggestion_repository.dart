import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class SmartSuggestion {
  final int? id;
  final String suggestionType;
  final String title;
  final String? description;
  final String? actionData;
  final double confidenceScore;
  final bool isAccepted;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  const SmartSuggestion({
    this.id,
    required this.suggestionType,
    required this.title,
    this.description,
    this.actionData,
    this.confidenceScore = 0,
    this.isAccepted = false,
    this.acceptedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'suggestion_type': suggestionType,
      'title': title,
      'description': description,
      'action_data': actionData,
      'confidence_score': confidenceScore,
      'is_accepted': isAccepted ? 1 : 0,
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartSuggestion.fromMap(Map<String, dynamic> map) {
    return SmartSuggestion(
      id: map['id'] as int?,
      suggestionType: map['suggestion_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      actionData: map['action_data'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 0,
      isAccepted: map['is_accepted'] == 1,
      acceptedAt: map['accepted_at'] != null ? DateTime.parse(map['accepted_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SmartSuggestion copyWith({bool? isAccepted}) {
    return SmartSuggestion(
      id: id,
      suggestionType: suggestionType,
      title: title,
      description: description,
      actionData: actionData,
      confidenceScore: confidenceScore,
      isAccepted: isAccepted ?? this.isAccepted,
      acceptedAt: acceptedAt,
      createdAt: createdAt,
    );
  }
}

final smartSuggestionRepositoryProvider = Provider<SmartSuggestionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartSuggestionRepository(dbAsync);
});

final smartSuggestionsProvider = StateNotifierProvider<SmartSuggestionsNotifier, AsyncValue<List<SmartSuggestion>>>((ref) {
  final repository = ref.watch(smartSuggestionRepositoryProvider);
  return SmartSuggestionsNotifier(repository);
});

final todaySuggestionsProvider = Provider<AsyncValue<List<SmartSuggestion>>>((ref) {
  final suggestions = ref.watch(smartSuggestionsProvider);
  return suggestions.whenData((data) {
    return data.where((s) => !s.isAccepted).take(5).toList();
  });
});

class SmartSuggestionRepository {
  final AsyncValue<Database> _dbAsync;

  SmartSuggestionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSuggestion(SmartSuggestion suggestion) async {
    final db = await _db;
    return db.insert('smart_suggestions', suggestion.toMap());
  }

  Future<int> acceptSuggestion(int id) async {
    final db = await _db;
    return db.update(
      'smart_suggestions',
      {'is_accepted': 1, 'accepted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SmartSuggestion>> getSuggestions() async {
    final db = await _db;
    final maps = await db.query('smart_suggestions', orderBy: 'confidence_score DESC');
    return maps.map((m) => SmartSuggestion.fromMap(m)).toList();
  }
}

class SmartSuggestionsNotifier extends StateNotifier<AsyncValue<List<SmartSuggestion>>> {
  final SmartSuggestionRepository _repository;

  SmartSuggestionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSuggestions();
  }

  Future<void> loadSuggestions() async {
    state = const AsyncValue.loading();
    try {
      final suggestions = await _repository.getSuggestions();
      state = AsyncValue.data(suggestions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptSuggestion(int id) async {
    try {
      await _repository.acceptSuggestion(id);
      await loadSuggestions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSuggestion(SmartSuggestion suggestion) async {
    try {
      await _repository.insertSuggestion(suggestion);
      await loadSuggestions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}