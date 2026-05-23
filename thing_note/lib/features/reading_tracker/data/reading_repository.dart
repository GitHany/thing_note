import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/reading_models.dart';

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository(ref.watch(databaseProvider).value!);
});

class ReadingRepository {
  final Database _db;

  ReadingRepository(this._db);

  Future<int> insertSession(ReadingSession session) async {
    return await _db.insert('reading_sessions', session.toMap());
  }

  Future<int> updateSession(ReadingSession session) async {
    return await _db.update(
      'reading_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<ReadingSession>> getAllSessions() async {
    final maps = await _db.query('reading_sessions', orderBy: 'session_date DESC');
    return maps.map((m) => ReadingSession.fromMap(m)).toList();
  }

  Future<List<ReadingSession>> getSessionsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final maps = await _db.query(
      'reading_sessions',
      where: 'session_date >= ? AND session_date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    return maps.map((m) => ReadingSession.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getReadingStats({int days = 7}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        COALESCE(SUM(duration_minutes), 0) as total_minutes,
        COALESCE(SUM(pages_read), 0) as total_pages,
        COALESCE(AVG(duration_minutes), 0) as avg_duration
      FROM reading_sessions
      WHERE session_date >= ?
    ''', [startDate.toIso8601String()]);

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getReadingByBook() async {
    return await _db.rawQuery('''
      SELECT 
        book_title,
        book_author,
        COUNT(*) as sessions,
        SUM(duration_minutes) as total_minutes,
        SUM(pages_read) as total_pages,
        MAX(session_date) as last_read
      FROM reading_sessions
      GROUP BY book_title
      ORDER BY last_read DESC
    ''');
  }
}