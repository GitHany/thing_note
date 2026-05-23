import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_quote/domain/daily_quote.dart';

final dailyQuoteRepositoryProvider = Provider<DailyQuoteRepository>((ref) {
  return DailyQuoteRepository(ref.watch(databaseProvider.future));
});

class DailyQuoteRepository {
  final Future<Database> _dbFuture;

  DailyQuoteRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<DailyQuote>> getAllQuotes() async {
    final db = await _db;
    final results = await db.query('daily_quotes', orderBy: 'created_at DESC');
    return results.map((e) => DailyQuote.fromMap(e)).toList();
  }

  Future<List<DailyQuote>> getQuotesByCategory(String category) async {
    final db = await _db;
    final results = await db.query(
      'daily_quotes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => DailyQuote.fromMap(e)).toList();
  }

  Future<DailyQuote?> getTodayQuote() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final results = await db.query(
      'daily_quotes',
      where: "DATE(created_at) = ?",
      whereArgs: [today],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return DailyQuote.fromMap(results.first);
    }

    final allQuotes = await getAllQuotes();
    if (allQuotes.isEmpty) {
      return null;
    }

    final randomIndex = DateTime.now().day % allQuotes.length;
    return allQuotes[randomIndex];
  }

  Future<int> insertQuote(DailyQuote quote) async {
    final db = await _db;
    return await db.insert('daily_quotes', quote.toMap()..remove('id'));
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return await db.update(
      'daily_quotes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> initializeDefaultQuotes() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM daily_quotes')) ?? 0;

    if (count == 0) {
      final defaults = [
        DailyQuote(quoteText: '每天进步一点点，成功就在眼前。', author: '未知', category: 'inspiration', actionSuggestion: '设定一个小目标并完成它'),
        DailyQuote(quoteText: '生活不是等待风暴过去，而是学会在雨中跳舞。', author: '维维安·格林', category: 'wisdom', actionSuggestion: '面对困难时保持积极心态'),
        DailyQuote(quoteText: '最困难的选择，莫过于选择开始。', author: '未知', category: 'motivation', actionSuggestion: '今天就迈出第一步'),
        DailyQuote(quoteText: '不要等待机会，而要创造机会。', author: '乔治·萧伯纳', category: 'wisdom', actionSuggestion: '主动承担一个小任务'),
        DailyQuote(quoteText: '坚持不是永不动摇，而是犹豫着、退缩着、但还在继续走。', author: '未知', category: 'inspiration', actionSuggestion: '继续做你正在做的事'),
      ];

      for (final quote in defaults) {
        await db.insert('daily_quotes', quote.toMap()..remove('id'));
      }
    }
  }
}