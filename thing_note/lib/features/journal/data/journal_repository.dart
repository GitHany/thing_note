import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/journal/domain/journal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return JournalRepository(db);
});

class JournalRepository {
  final Database _db;

  JournalRepository(this._db);

  Future<int> insert(Journal journal) async {
    return _db.insert('journals', journal.toMap()..remove('id'));
  }

  Future<int> update(Journal journal) async {
    return _db.update(
      'journals',
      journal.toMap(),
      where: 'id = ?',
      whereArgs: [journal.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('journals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Journal?> getByDate(String date) async {
    final results = await _db.query(
      'journals',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (results.isEmpty) return null;
    return Journal.fromMap(results.first);
  }

  Future<Journal?> getById(int id) async {
    final results = await _db.query(
      'journals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Journal.fromMap(results.first);
  }

  Future<List<Journal>> getAll() async {
    final results = await _db.query('journals', orderBy: 'date DESC');
    return results.map((e) => Journal.fromMap(e)).toList();
  }

  Future<List<Journal>> getByDateRange(String startDate, String endDate) async {
    final results = await _db.query(
      'journals',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return results.map((e) => Journal.fromMap(e)).toList();
  }

  Future<List<Journal>> search(String keyword) async {
    final results = await _db.query(
      'journals',
      where: 'content LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'date DESC',
    );
    return results.map((e) => Journal.fromMap(e)).toList();
  }

  Future<List<Journal>> getByMood(String mood) async {
    final results = await _db.query(
      'journals',
      where: 'mood = ?',
      whereArgs: [mood],
      orderBy: 'date DESC',
    );
    return results.map((e) => Journal.fromMap(e)).toList();
  }
}