import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 记录评分服务 Provider
final recordRatingServiceProvider = Provider<RecordRatingService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return RecordRatingService(dbAsync);
});

/// 记录评分列表 Provider
final recordRatingsProvider = FutureProvider<List<RecordRating>>((ref) async {
  final service = ref.watch(recordRatingServiceProvider);
  return service.getAllRatings();
});

/// 评分统计 Provider
final ratingStatsProvider = FutureProvider<RatingStats>((ref) async {
  final service = ref.watch(recordRatingServiceProvider);
  return service.getStats();
});

class RecordRatingService {
  final AsyncValue<Database> _dbAsync;

  RecordRatingService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有评分
  Future<List<RecordRating>> getAllRatings() async {
    final db = await _db;
    final maps = await db.query('record_ratings', orderBy: 'rated_at DESC');
    return maps.map((m) => RecordRating.fromMap(m)).toList();
  }

  /// 获取记录的评分
  Future<RecordRating?> getRatingForRecord(int recordId) async {
    final db = await _db;
    final maps = await db.query(
      'record_ratings',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
    if (maps.isEmpty) return null;
    return RecordRating.fromMap(maps.first);
  }

  /// 添加/更新评分
  Future<int> setRating(int recordId, {int? importanceRating, int? satisfactionRating}) async {
    final db = await _db;

    final existing = await db.query(
      'record_ratings',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    if (existing.isNotEmpty) {
      return db.update(
        'record_ratings',
        {
          if (importanceRating != null) 'importance_rating': importanceRating,
          if (satisfactionRating != null) 'satisfaction_rating': satisfactionRating,
          'rated_at': DateTime.now().toIso8601String(),
        },
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
    } else {
      return db.insert('record_ratings', {
        'record_id': recordId,
        'importance_rating': importanceRating ?? 0,
        'satisfaction_rating': satisfactionRating ?? 0,
        'rated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 删除评分
  Future<int> deleteRating(int recordId) async {
    final db = await _db;
    return db.delete('record_ratings', where: 'record_id = ?', whereArgs: [recordId]);
  }

  /// 获取评分统计
  Future<RatingStats> getStats() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT 
        AVG(importance_rating) as avg_importance,
        AVG(satisfaction_rating) as avg_satisfaction,
        COUNT(*) as total
      FROM record_ratings
    ''');

    final avgImportance = (result.first['avg_importance'] as num?)?.toDouble() ?? 0.0;
    final avgSatisfaction = (result.first['avg_satisfaction'] as num?)?.toDouble() ?? 0.0;
    final total = result.first['total'] as int? ?? 0;

    // 评分分布
    final distribution = await db.rawQuery('''
      SELECT importance_rating, COUNT(*) as count
      FROM record_ratings
      GROUP BY importance_rating
      ORDER BY importance_rating
    ''');

    final distributionMap = <int, int>{};
    for (final row in distribution) {
      distributionMap[row['importance_rating'] as int] = row['count'] as int;
    }

    // 高价值记录
    final highValue = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM record_ratings
      WHERE importance_rating >= 4
    ''');

    return RatingStats(
      avgImportance: avgImportance,
      avgSatisfaction: avgSatisfaction,
      totalRatings: total,
      distribution: distributionMap,
      highValueCount: highValue.first['count'] as int? ?? 0,
    );
  }

  /// 获取高价值记录
  Future<List<Map<String, dynamic>>> getHighValueRecords({int limit = 10}) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT r.*, rr.importance_rating, rr.satisfaction_rating
      FROM episode_records r
      INNER JOIN record_ratings rr ON r.id = rr.record_id
      ORDER BY rr.importance_rating DESC, rr.satisfaction_rating DESC
      LIMIT ?
    ''', [limit]);
  }
}

/// 记录评分模型
class RecordRating {
  final int? id;
  final int recordId;
  final int importanceRating; // 1-5
  final int satisfactionRating; // 1-5
  final DateTime ratedAt;

  RecordRating({
    this.id,
    required this.recordId,
    this.importanceRating = 0,
    this.satisfactionRating = 0,
    DateTime? ratedAt,
  }) : ratedAt = ratedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'importance_rating': importanceRating,
      'satisfaction_rating': satisfactionRating,
      'rated_at': ratedAt.toIso8601String(),
    };
  }

  factory RecordRating.fromMap(Map<String, dynamic> map) {
    return RecordRating(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      importanceRating: map['importance_rating'] as int? ?? 0,
      satisfactionRating: map['satisfaction_rating'] as int? ?? 0,
      ratedAt: DateTime.parse(map['rated_at'] as String),
    );
  }
}

/// 评分统计
class RatingStats {
  final double avgImportance;
  final double avgSatisfaction;
  final int totalRatings;
  final Map<int, int> distribution;
  final int highValueCount;

  RatingStats({
    required this.avgImportance,
    required this.avgSatisfaction,
    required this.totalRatings,
    required this.distribution,
    required this.highValueCount,
  });

  double get avgOverall => (avgImportance + avgSatisfaction) / 2;
}