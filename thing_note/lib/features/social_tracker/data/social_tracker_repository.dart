import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/social_tracker/domain/social_interaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final socialTrackerRepositoryProvider = Provider<SocialTrackerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SocialTrackerRepository(dbAsync);
});

final socialInteractionsProvider = StateNotifierProvider<SocialInteractionsNotifier, AsyncValue<List<SocialInteraction>>>((ref) {
  final repository = ref.watch(socialTrackerRepositoryProvider);
  return SocialInteractionsNotifier(repository);
});

final recentContactsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final interactions = ref.watch(socialInteractionsProvider);
  return interactions.whenData((list) {
    final contacts = list
        .where((i) => i.contactName != null && i.contactName!.isNotEmpty)
        .map((i) => i.contactName!)
        .toSet()
        .toList();
    return contacts.take(10).toList();
  });
});

class SocialTrackerRepository {
  final AsyncValue<Database> _dbAsync;

  SocialTrackerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertInteraction(SocialInteraction interaction) async {
    final db = await _db;
    return db.insert('social_interactions', interaction.toMap());
  }

  Future<int> deleteInteraction(int id) async {
    final db = await _db;
    return db.delete('social_interactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SocialInteraction>> getAllInteractions() async {
    final db = await _db;
    final maps = await db.query('social_interactions', orderBy: 'occurred_at DESC');
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<SocialInteraction>> getInteractionsByDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'social_interactions',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'occurred_at DESC',
    );
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<List<SocialInteraction>> getInteractionsByContact(String contactName) async {
    final db = await _db;
    final maps = await db.query(
      'social_interactions',
      where: 'contact_name = ?',
      whereArgs: [contactName],
      orderBy: 'occurred_at DESC',
    );
    return maps.map((m) => SocialInteraction.fromMap(m)).toList();
  }

  Future<int> getInteractionCountThisWeek() async {
    final db = await _db;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM social_interactions WHERE occurred_at >= ?',
      [startOfWeek.toIso8601String()],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}

class SocialInteractionsNotifier extends StateNotifier<AsyncValue<List<SocialInteraction>>> {
  final SocialTrackerRepository _repository;

  SocialInteractionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInteractions();
  }

  Future<void> loadInteractions() async {
    state = const AsyncValue.loading();
    try {
      final interactions = await _repository.getAllInteractions();
      state = AsyncValue.data(interactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addInteraction(SocialInteraction interaction) async {
    try {
      await _repository.insertInteraction(interaction);
      await loadInteractions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteInteraction(int id) async {
    try {
      await _repository.deleteInteraction(id);
      await loadInteractions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<SocialInteraction>> getInteractionsByDate(DateTime date) async {
    return _repository.getInteractionsByDate(date);
  }
}