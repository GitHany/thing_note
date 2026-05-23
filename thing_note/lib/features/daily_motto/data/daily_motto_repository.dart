import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_motto/domain/daily_motto.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final dailyMottoRepositoryProvider = Provider<DailyMottoRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyMottoRepository(dbAsync);
});

final todayMottoProvider = FutureProvider<DailyMotto?>((ref) async {
  final repo = ref.watch(dailyMottoRepositoryProvider);
  return repo.getMottoByDate(_todayDate());
});

final recentMottosProvider = FutureProvider<List<DailyMotto>>((ref) async {
  final repo = ref.watch(dailyMottoRepositoryProvider);
  return repo.getRecentMottos(7);
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class DailyMottoRepository {
  final AsyncValue<Database> _dbAsync;

  DailyMottoRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMotto(DailyMotto motto) async {
    final db = await _db;
    return db.insert('daily_mottos', motto.toMap());
  }

  Future<int> updateMotto(DailyMotto motto) async {
    final db = await _db;
    return db.update('daily_mottos', motto.toMap(), where: 'id = ?', whereArgs: [motto.id]);
  }

  Future<DailyMotto?> getMottoByDate(String date) async {
    final db = await _db;
    final maps = await db.query('daily_mottos', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return DailyMotto.fromMap(maps.first);
  }

  Future<List<DailyMotto>> getRecentMottos(int days) async {
    final db = await _db;
    final maps = await db.query(
      'daily_mottos',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((m) => DailyMotto.fromMap(m)).toList();
  }

  Future<DailyMotto> getOrCreateTodayMotto() async {
    final date = _todayDate();
    final existing = await getMottoByDate(date);
    if (existing != null) return existing;

    // Auto-generate from library
    final randomIndex = DateTime.now().day % MottoLibrary.defaultMottos.length;
    final selected = MottoLibrary.defaultMottos[randomIndex];
    final motto = DailyMotto(
      date: date,
      quote: selected['quote'],
      author: selected['author'],
      createdAt: DateTime.now(),
    );
    await insertMotto(motto);
    return motto;
  }

  Future<int> updateReflection(int id, String reflection, int moodAfter) async {
    final db = await _db;
    return db.update(
      'daily_mottos',
      {'reflection': reflection, 'mood_after': moodAfter},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return db.update(
      'daily_mottos',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DailyMotto>> getFavoriteMottos() async {
    final db = await _db;
    final maps = await db.query(
      'daily_mottos',
      where: 'is_favorite = 1',
      orderBy: 'date DESC',
    );
    return maps.map((m) => DailyMotto.fromMap(m)).toList();
  }
}
