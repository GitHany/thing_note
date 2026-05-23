import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/flashcard/domain/flashcard.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return FlashcardRepository(db);
});

class FlashcardRepository {
  final Database _db;

  FlashcardRepository(this._db);

  Future<int> insert(Flashcard flashcard) async {
    return _db.insert('flashcards', flashcard.toMap()..remove('id'));
  }

  Future<int> update(Flashcard flashcard) async {
    return _db.update(
      'flashcards',
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<Flashcard?> getById(int id) async {
    final results = await _db.query(
      'flashcards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Flashcard.fromMap(results.first);
  }

  Future<List<Flashcard>> getAll() async {
    final results = await _db.query('flashcards', orderBy: 'created_at DESC');
    return results.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<Flashcard>> getDueForReview() async {
    final now = DateTime.now().toIso8601String();
    final results = await _db.query(
      'flashcards',
      where: 'next_review_at IS NULL OR next_review_at <= ?',
      whereArgs: [now],
      orderBy: 'next_review_at ASC',
    );
    return results.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<Flashcard>> getByCategory(String category) async {
    final results = await _db.query(
      'flashcards',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<List<String>> getCategories() async {
    final results = await _db.rawQuery(
      'SELECT DISTINCT category FROM flashcards WHERE category IS NOT NULL ORDER BY category',
    );
    return results.map((e) => e['category'] as String).toList();
  }

  Future<int> getDueCount() async {
    final now = DateTime.now().toIso8601String();
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE next_review_at IS NULL OR next_review_at <= ?',
      [now],
    );
    return result.first['count'] as int;
  }

  Future<int> insertReview(FlashcardReview review) async {
    return _db.insert('flashcard_reviews', review.toMap()..remove('id'));
  }

  Future<List<FlashcardReview>> getReviewsByFlashcardId(int flashcardId) async {
    final results = await _db.query(
      'flashcard_reviews',
      where: 'flashcard_id = ?',
      whereArgs: [flashcardId],
      orderBy: 'reviewed_at DESC',
    );
    return results.map((e) => FlashcardReview.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getStudyStats() async {
    final total = await _db.rawQuery('SELECT COUNT(*) as count FROM flashcards');
    final dueCount = await getDueCount();
    final reviews = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcard_reviews WHERE date(reviewed_at) = date("now")',
    );
    return {
      'total': total.first['count'],
      'dueCount': dueCount,
      'todayReviews': reviews.first['count'],
    };
  }
}