import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/quick_review_model.dart';

final quickReviewRepositoryProvider = Provider<QuickReviewRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickReviewRepository(dbAsync);
});

class QuickReviewRepository {
  final AsyncValue<Database> _dbAsync;

  QuickReviewRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCard(QuickReviewCard card) async {
    final db = await _db;
    return await db.insert('quick_review_cards', card.toMap());
  }

  Future<int> updateCard(QuickReviewCard card) async {
    final db = await _db;
    return await db.update(
      'quick_review_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await _db;
    return await db.delete(
      'quick_review_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<QuickReviewCard>> getAllCards() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_review_cards',
      orderBy: 'next_review_at ASC, created_at DESC',
    );
    return maps.map((map) => QuickReviewCard.fromMap(map)).toList();
  }

  Future<List<QuickReviewCard>> getDueCards() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_review_cards',
      where: 'next_review_at IS NULL OR next_review_at <= ?',
      whereArgs: [now],
      orderBy: 'next_review_at ASC',
    );
    return maps.map((map) => QuickReviewCard.fromMap(map)).toList();
  }

  Future<List<QuickReviewCard>> getCardsByCategory(String category) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_review_cards',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => QuickReviewCard.fromMap(map)).toList();
  }

  Future<int> recordReview(CardReview review) async {
    final db = await _db;
    return await db.insert('card_reviews', review.toMap());
  }

  Future<List<String>> getAllCategories() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT DISTINCT category FROM quick_review_cards 
      WHERE category IS NOT NULL AND category != ''
    ''');
    return result.map((r) => r['category'] as String).toList();
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await _db;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM quick_review_cards');
    final total = totalResult.first['count'] as int? ?? 0;
    
    final dueResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM quick_review_cards 
      WHERE next_review_at IS NULL OR next_review_at <= ?
    ''', [DateTime.now().toIso8601String()]);
    final due = dueResult.first['count'] as int? ?? 0;
    
    final masteredResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM quick_review_cards WHERE ease_factor >= 2.5
    ''');
    final mastered = masteredResult.first['count'] as int? ?? 0;
    
    return {
      'total_cards': total,
      'due_cards': due,
      'mastered_cards': mastered,
    };
  }

  QuickReviewCard updateCardWithReview(QuickReviewCard card, int quality) {
    double newEaseFactor = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEaseFactor < 1.3) newEaseFactor = 1.3;
    
    int newInterval;
    if (quality < 3) {
      newInterval = 1;
    } else if (card.reviewCount == 0) {
      newInterval = 1;
    } else if (card.reviewCount == 1) {
      newInterval = 6;
    } else {
      newInterval = (card.intervalDays * newEaseFactor).round();
    }
    
    final nextReview = DateTime.now().add(Duration(days: newInterval));
    
    return card.copyWith(
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
      nextReviewAt: nextReview.toIso8601String(),
      reviewCount: card.reviewCount + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
