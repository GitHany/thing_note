import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/habit_brick_model.dart';

final habitBricksRepositoryProvider = Provider<HabitBricksRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitBricksRepository(dbAsync);
});

class HabitBricksRepository {
  final AsyncValue<Database> _dbAsync;

  HabitBricksRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertBrick(HabitBrick brick) async {
    final db = await _db;
    return await db.insert('habit_bricks', brick.toMap());
  }

  Future<int> updateBrick(HabitBrick brick) async {
    final db = await _db;
    return await db.update(
      'habit_bricks',
      brick.toMap(),
      where: 'id = ?',
      whereArgs: [brick.id],
    );
  }

  Future<int> deleteBrick(int id) async {
    final db = await _db;
    return await db.delete(
      'habit_bricks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HabitBrick>> getAllBricks() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_bricks',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => HabitBrick.fromMap(map)).toList();
  }

  Future<List<BrickProgress>> getProgressByBrickId(int brickId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'brick_progress',
      where: 'brick_id = ?',
      whereArgs: [brickId],
      orderBy: 'record_date DESC',
    );
    return maps.map((map) => BrickProgress.fromMap(map)).toList();
  }

  Future<BrickProgress?> getTodayProgress(int brickId) async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'brick_progress',
      where: 'brick_id = ? AND record_date = ?',
      whereArgs: [brickId, today],
    );
    if (maps.isNotEmpty) {
      return BrickProgress.fromMap(maps.first);
    }
    return null;
  }

  Future<int> saveProgress(BrickProgress progress) async {
    final db = await _db;
    final existing = await db.query(
      'brick_progress',
      where: 'brick_id = ? AND record_date = ?',
      whereArgs: [progress.brickId, progress.recordDate],
    );
    
    if (existing.isNotEmpty) {
      return await db.update(
        'brick_progress',
        progress.toMap(),
        where: 'brick_id = ? AND record_date = ?',
        whereArgs: [progress.brickId, progress.recordDate],
      );
    } else {
      return await db.insert('brick_progress', progress.toMap());
    }
  }

  Future<int> getCurrentStreak(int brickId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT record_date FROM brick_progress 
      WHERE brick_id = ? AND completed_bricks >= total_bricks
      ORDER BY record_date DESC
    ''', [brickId]);
    
    if (maps.isEmpty) return 0;
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final map in maps) {
      final date = DateTime.parse(map['record_date'] as String);
      final diff = currentDate.difference(date).inDays;
      
      if (diff <= 1) {
        streak++;
        currentDate = date;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<Map<String, dynamic>> getBrickStatistics(int brickId) async {
    final db = await _db;
    
    final totalDays = await db.rawQuery('''
      SELECT COUNT(*) as count FROM brick_progress 
      WHERE brick_id = ? AND completed_bricks >= total_bricks
    ''', [brickId]);
    
    final thisMonth = await db.rawQuery('''
      SELECT SUM(completed_bricks) as total, SUM(total_bricks) as target 
      FROM brick_progress 
      WHERE brick_id = ? AND record_date LIKE ?
    ''', [brickId, '${DateTime.now().toIso8601String().substring(0, 7)}%']);
    
    return {
      'total_completed_days': totalDays.first['count'] as int? ?? 0,
      'month_bricks': thisMonth.first['total'] as int? ?? 0,
      'month_target': thisMonth.first['target'] as int? ?? 0,
    };
  }
}
