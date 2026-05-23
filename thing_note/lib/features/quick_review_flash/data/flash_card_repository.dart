import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_review_flash/domain/quick_flash_card.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final flashCardRepositoryProvider = Provider<FlashCardRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FlashCardRepository(dbAsync);
});

final flashCardsDueProvider = FutureProvider<List<QuickFlashCard>>((ref) async {
  final repo = ref.watch(flashCardRepositoryProvider);
  return repo.getDueCards();
});

final flashCardsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(flashCardRepositoryProvider);
  return repo.getTotalCount();
});

class FlashCardRepository {
  final AsyncValue<Database> _dbAsync;

  FlashCardRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCard(QuickFlashCard card) async {
    final db = await _db;
    return db.insert('quick_flash_cards', card.toMap());
  }

  Future<int> updateCard(QuickFlashCard card) async {
    final db = await _db;
    return db.update('quick_flash_cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<int> deleteCard(int id) async {
    final db = await _db;
    return db.delete('quick_flash_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuickFlashCard>> getAllCards() async {
    final db = await _db;
    final maps = await db.query('quick_flash_cards', orderBy: 'created_at DESC');
    return maps.map((m) => QuickFlashCard.fromMap(m)).toList();
  }

  Future<List<QuickFlashCard>> getDueCards() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'quick_flash_cards',
      where: 'next_review IS NULL OR next_review <= ?',
      whereArgs: [now],
      orderBy: 'next_review ASC',
    );
    return maps.map((m) => QuickFlashCard.fromMap(m)).toList();
  }

  Future<List<QuickFlashCard>> getCardsByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      'quick_flash_cards',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => QuickFlashCard.fromMap(m)).toList();
  }

  Future<int> reviewCard(int cardId, int quality) async {
    final db = await _db;
    final maps = await db.query('quick_flash_cards', where: 'id = ?', whereArgs: [cardId]);
    if (maps.isEmpty) return 0;

    final card = QuickFlashCard.fromMap(maps.first);
    final updated = card.applyReview(quality);

    // Log review
    await db.insert('flash_card_reviews', {
      'card_id': cardId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'quality': quality,
      'ease_factor': updated.easeFactor,
      'interval_days': updated.intervalDays,
    });

    return db.update('quick_flash_cards', updated.toMap(), where: 'id = ?', whereArgs: [cardId]);
  }

  Future<int> getTotalCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM quick_flash_cards');
    return result.first['count'] as int? ?? 0;
  }

  Future<Map<String, int>> getStats() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM quick_flash_cards');
    final due = await db.rawQuery('SELECT COUNT(*) as count FROM quick_flash_cards WHERE next_review IS NULL OR next_review <= ?', [now]);
    final mastered = await db.rawQuery('SELECT COUNT(*) as count FROM quick_flash_cards WHERE review_count >= 5');
    return {
      'total': total.first['count'] as int? ?? 0,
      'due': due.first['count'] as int? ?? 0,
      'mastered': mastered.first['count'] as int? ?? 0,
    };
  }
}
