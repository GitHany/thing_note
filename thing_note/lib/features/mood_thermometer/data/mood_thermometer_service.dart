import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/mood_thermometer_models.dart';

/// 情绪温度计服务提供者
final moodThermometerServiceProvider = Provider<MoodThermometerService>((ref) {
  return MoodThermometerService(ref.read(databaseProvider.future));
});

/// 情绪温度计服务
class MoodThermometerService {
  final Future<Database> _db;

  MoodThermometerService(this._db);

  /// 记录情绪
  Future<int> recordMood(MoodThermometerRecord record) async {
    final db = await _db;
    final id = await db.insert('mood_thermometer_records', record.toMap());
    return id;
  }

  /// 获取最近的记录
  Future<List<MoodThermometerRecord>> getRecentRecords({int limit = 7}) async {
    final db = await _db;
    final rows = await db.query(
      'mood_thermometer_records',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return rows.map((r) => MoodThermometerRecord.fromMap(r)).toList();
  }

  /// 获取指定日期范围的记录
  Future<List<MoodThermometerRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'mood_thermometer_records',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return rows.map((r) => MoodThermometerRecord.fromMap(r)).toList();
  }

  /// 获取统计数据
  Future<MoodThermometerStats> getStats({int days = 30}) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final records = await db.query(
      'mood_thermometer_records',
      where: 'recorded_at >= ?',
      whereArgs: [startDate.toIso8601String()],
    );

    if (records.isEmpty) {
      return MoodThermometerStats(
        totalRecords: 0,
        averageMood: 0,
        highestMood: 0,
        lowestMood: 0,
        distribution: {},
        trend: [],
      );
    }

    final moodRecords = records.map((r) => MoodThermometerRecord.fromMap(r)).toList();

    // 计算统计数据
    int totalMood = 0;
    int highest = 0;
    int lowest = 100;
    final distribution = <int, int>{};

    for (final record in moodRecords) {
      totalMood += record.moodLevel;
      if (record.moodLevel > highest) highest = record.moodLevel;
      if (record.moodLevel < lowest) lowest = record.moodLevel;

      // 按10分组统计
      final bucket = (record.moodLevel ~/ 10) * 10;
      distribution[bucket] = (distribution[bucket] ?? 0) + 1;
    }

    final average = totalMood / moodRecords.length;

    // 生成趋势数据（按天聚合）
    final trendMap = <String, List<int>>{};
    for (final record in moodRecords) {
      final dateKey = '${record.recordedAt.year}-${record.recordedAt.month}-${record.recordedAt.day}';
      trendMap.putIfAbsent(dateKey, () => []);
      trendMap[dateKey]!.add(record.moodLevel);
    }

    final trend = <MoodTrendPoint>[];
    final sortedKeys = trendMap.keys.toList()..sort();
    for (final key in sortedKeys) {
      final moods = trendMap[key]!;
      final avgMood = moods.reduce((a, b) => a + b) ~/ moods.length;
      final parts = key.split('-');
      trend.add(MoodTrendPoint(
        date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        moodLevel: avgMood,
      ));
    }

    return MoodThermometerStats(
      totalRecords: moodRecords.length,
      averageMood: average,
      highestMood: highest,
      lowestMood: lowest,
      distribution: distribution,
      trend: trend,
    );
  }

  /// 获取当前温度
  Future<MoodThermometerRecord?> getCurrentMood() async {
    final db = await _db;
    final rows = await db.query(
      'mood_thermometer_records',
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return MoodThermometerRecord.fromMap(rows.first);
  }

  /// 更新记录
  Future<void> updateRecord(int id, MoodThermometerRecord record) async {
    final db = await _db;
    await db.update(
      'mood_thermometer_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除记录
  Future<void> deleteRecord(int id) async {
    final db = await _db;
    await db.delete(
      'mood_thermometer_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取按类别统计
  Future<Map<String, double>> getCategoryAverages() async {
    final db = await _db;
    final records = await db.query(
      'mood_thermometer_records',
      where: 'category IS NOT NULL',
    );

    if (records.isEmpty) return {};

    final categoryMoods = <String, List<int>>{};
    for (final record in records) {
      final category = record['category'] as String;
      final mood = (record['mood_level'] as int);
      categoryMoods.putIfAbsent(category, () => []);
      categoryMoods[category]!.add(mood);
    }

    final averages = <String, double>{};
    for (final entry in categoryMoods.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      averages[entry.key] = sum / entry.value.length;
    }

    return averages;
  }

  /// 获取按触发因素统计
  Future<Map<String, double>> getTriggerImpacts() async {
    final db = await _db;
    final records = await db.query(
      'mood_thermometer_records',
      where: 'trigger IS NOT NULL',
    );

    if (records.isEmpty) return {};

    final triggerMoods = <String, List<int>>{};
    for (final record in records) {
      final trigger = record['trigger'] as String;
      final mood = (record['mood_level'] as int);
      triggerMoods.putIfAbsent(trigger, () => []);
      triggerMoods[trigger]!.add(mood);
    }

    final impacts = <String, double>{};
    for (final entry in triggerMoods.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      impacts[entry.key] = sum / entry.value.length;
    }

    return impacts;
  }

  /// 获取周对比
  Future<Map<String, double>> getWeekComparison() async {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekRecords = await getRecordsByDateRange(
      thisWeekStart,
      now,
    );

    final lastWeekRecords = await getRecordsByDateRange(
      lastWeekStart,
      thisWeekStart.subtract(const Duration(days: 1)),
    );

    double thisWeekAvg = 0;
    double lastWeekAvg = 0;

    if (thisWeekRecords.isNotEmpty) {
      thisWeekAvg = thisWeekRecords.map((r) => r.moodLevel).reduce((a, b) => a + b) /
          thisWeekRecords.length;
    }

    if (lastWeekRecords.isNotEmpty) {
      lastWeekAvg = lastWeekRecords.map((r) => r.moodLevel).reduce((a, b) => a + b) /
          lastWeekRecords.length;
    }

    return {
      'this_week': thisWeekAvg,
      'last_week': lastWeekAvg,
      'change': thisWeekAvg - lastWeekAvg,
    };
  }
}