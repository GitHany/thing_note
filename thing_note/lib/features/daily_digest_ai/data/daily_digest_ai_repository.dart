import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/daily_digest_ai.dart';

final dailyDigestAIRepositoryProvider = Provider<DailyDigestAIRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyDigestAIRepository(dbAsync);
});

class DailyDigestAIRepository {
  final AsyncValue<Database> _dbAsync;

  DailyDigestAIRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // 保存每日摘要
  Future<int> saveDailyDigest(DailyDigestAI digest) async {
    final db = await _db;
    return await db.insert(
      'daily_digest_ai',
      digest.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取指定日期的摘要
  Future<DailyDigestAI?> getDailyDigest(String date) async {
    final db = await _db;
    final results = await db.query(
      'daily_digest_ai',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (results.isEmpty) return null;
    return DailyDigestAI.fromMap(results.first);
  }

  // 获取日期范围的摘要
  Future<List<DailyDigestAI>> getDigestRange(String startDate, String endDate) async {
    final db = await _db;
    final results = await db.query(
      'daily_digest_ai',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return results.map((e) => DailyDigestAI.fromMap(e)).toList();
  }

  // 获取最近的N条摘要
  Future<List<DailyDigestAI>> getRecentDigests(int limit) async {
    final db = await _db;
    final results = await db.query(
      'daily_digest_ai',
      orderBy: 'date DESC',
      limit: limit,
    );
    return results.map((e) => DailyDigestAI.fromMap(e)).toList();
  }

  // 删除摘要
  Future<int> deleteDigest(int id) async {
    final db = await _db;
    return await db.delete(
      'daily_digest_ai',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 保存配置
  Future<int> saveConfig(DigestConfig config) async {
    final db = await _db;
    return await db.insert(
      'daily_digest_ai_config',
      config.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取配置
  Future<DigestConfig> getConfig() async {
    final db = await _db;
    final results = await db.query('daily_digest_ai_config', limit: 1);
    if (results.isEmpty) {
      return DigestConfig();
    }
    return DigestConfig.fromMap(results.first);
  }

  // 保存每周摘要
  Future<int> saveWeeklyDigest(WeeklyDigest digest) async {
    final db = await _db;
    return await db.insert(
      'weekly_digest_ai',
      digest.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取指定周的摘要
  Future<WeeklyDigest?> getWeeklyDigest(int weekNumber, int year) async {
    final db = await _db;
    final results = await db.query(
      'weekly_digest_ai',
      where: 'week_number = ? AND year = ?',
      whereArgs: [weekNumber, year],
    );
    if (results.isEmpty) return null;
    return WeeklyDigest.fromMap(results.first);
  }
}