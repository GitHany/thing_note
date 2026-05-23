import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 智能提醒预测服务
class ReminderPredictionService {
  final AsyncValue<Database> _dbAsync;

  ReminderPredictionService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 分析记录时间模式，预测最佳提醒时间
  Future<List<ReminderPrediction>> predictBestReminderTimes({
    required String? thingName,
    int limit = 5,
  }) async {
    final db = await _db;
    
    String query = '''
      SELECT 
        strftime('%H', occurred_at) as hour,
        strftime('%w', occurred_at) as weekday,
        COUNT(*) as count
      FROM episode_records
      WHERE thing_name_id IS NOT NULL
    ''';
    
    final List<String> args = [];
    
    if (thingName != null) {
      query += ' AND thing_name_id = (SELECT id FROM thing_names WHERE name = ?)';
      args.add(thingName);
    }
    
    query += '''
      GROUP BY hour, weekday
      ORDER BY count DESC
      LIMIT ?
    ''';
    args.add(limit.toString());

    final result = await db.rawQuery(query, args);
    
    final predictions = <ReminderPrediction>[];
    final seenHours = <String>{};
    
    for (final row in result) {
      final hour = row['hour'] as String;
      final weekday = row['weekday'] as String;
      final count = row['count'] as int;
      
      if (seenHours.contains(hour)) continue;
      seenHours.add(hour);
      
      final predictedTime = _getNextPredictedTime(int.parse(hour), int.parse(weekday));
      
      predictions.add(ReminderPrediction(
        predictedHour: int.parse(hour),
        predictedMinute: 0,
        confidence: _calculateConfidence(count),
        reason: _generateReason(int.parse(hour), count),
        suggestedTime: predictedTime,
        weekday: int.parse(weekday),
      ));
    }
    
    return predictions;
  }

  /// 分析记录频率，预测下次提醒时间
  Future<ReminderPrediction?> predictNextReminder({
    required String? thingName,
  }) async {
    final db = await _db;
    
    String query = '''
      SELECT 
        AVG(duration_since_last) as avg_interval,
        COUNT(*) as occurrences
      FROM (
        SELECT 
          id,
          occurred_at,
          LAG(occurred_at) OVER (ORDER BY occurred_at) as prev_occurred_at,
          JULIANDAY(occurred_at) - JULIANDAY(LAG(occurred_at) OVER (ORDER BY occurred_at)) as duration_since_last
        FROM episode_records
WHERE thing_name_id IS NOT NULL
    ''';
    
    final List<String> args = [];
    
    if (thingName != null) {
      query += ' AND thing_name_id = (SELECT id FROM thing_names WHERE name = ?)';
      args.add(thingName);
    }
    
    query += '''
      )
      WHERE duration_since_last IS NOT NULL
    ''';

    final result = await db.rawQuery(query, args);
    
    if (result.isEmpty) return null;
    
    final avgInterval = result.first['avg_interval'] as double?;
    final occurrences = result.first['occurrences'] as int?;
    
    if (avgInterval == null || occurrences == null || occurrences < 3) {
      return null;
    }
    
    // 计算置信度
    final double confidence = (occurrences / 20).clamp(0.0, 1.0);
    
    // 计算下次提醒时间
    final lastRecord = await db.query(
      'episode_records',
      orderBy: 'occurred_at DESC',
      limit: 1,
    );
    
    if (lastRecord.isEmpty) return null;
    
    final lastOccurredAt = DateTime.parse(lastRecord.first['occurred_at'] as String);
    final nextTime = lastOccurredAt.add(Duration(days: avgInterval.round()));
    
    return ReminderPrediction(
      predictedHour: nextTime.hour,
      predictedMinute: nextTime.minute,
      confidence: confidence,
      reason: '基于 $occurrences 次记录分析',
      suggestedTime: nextTime,
      weekday: nextTime.weekday,
    );
  }

  /// 获取周期性提醒建议
  Future<List<ReminderPrediction>> suggestRecurringReminders({
    int minOccurrences = 5,
    int limit = 10,
  }) async {
    final db = await _db;
    
    final result = await db.rawQuery('''
      SELECT 
        thing_name_id,
        tn.name as thing_name,
        strftime('%H', occurred_at) as hour,
        COUNT(*) as count
      FROM episode_records r
      INNER JOIN thing_names tn ON r.thing_name_id = tn.id
      GROUP BY thing_name_id, hour
      HAVING count >= ?
      ORDER BY count DESC
      LIMIT ?
    ''', [minOccurrences, limit]);

    final predictions = <ReminderPrediction>[];
    final seenThingNames = <int>{};

    for (final row in result) {
      final thingNameId = row['thing_name_id'] as int;
      if (seenThingNames.contains(thingNameId)) continue;
      seenThingNames.add(thingNameId);

      final hour = int.parse(row['hour'] as String);
      final count = row['count'] as int;
      final thingName = row['thing_name'] as String;

      // 找到最近一次该事情的时间，计算下次时间
      final lastRecord = await db.rawQuery('''
        SELECT occurred_at FROM episode_records
        WHERE thing_name_id = ?
        ORDER BY occurred_at DESC LIMIT 1
      ''', [thingNameId]);

      if (lastRecord.isEmpty) continue;

      final lastTime = DateTime.parse(lastRecord.first['occurred_at'] as String);
      final suggestedTime = DateTime(
        lastTime.year,
        lastTime.month,
        lastTime.day,
        hour,
        0,
      );

      predictions.add(ReminderPrediction(
        predictedHour: hour,
        predictedMinute: 0,
        confidence: _calculateConfidence(count),
        reason: '$thingName 经常在 $hour:00 左右记录',
        suggestedTime: suggestedTime,
        weekday: suggestedTime.weekday,
      ));
    }

    return predictions;
  }

  DateTime _getNextPredictedTime(int hour, int weekday) {
    final now = DateTime.now();
    var nextTime = DateTime(now.year, now.month, now.day, hour);
    
    if (nextTime.isBefore(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }
    
    return nextTime;
  }

  double _calculateConfidence(int count) {
    // 基于出现次数计算置信度
    if (count >= 20) return 0.95;
    if (count >= 15) return 0.85;
    if (count >= 10) return 0.75;
    if (count >= 5) return 0.60;
    if (count >= 3) return 0.45;
    return 0.30;
  }

  String _generateReason(int hour, int count) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:00';
    return '经常在 $timeStr 左右记录 ($count 次)';
  }
}

/// 提醒预测数据模型
class ReminderPrediction {
  final int predictedHour;
  final int predictedMinute;
  final double confidence;
  final String reason;
  final DateTime suggestedTime;
  final int? weekday;

  const ReminderPrediction({
    required this.predictedHour,
    required this.predictedMinute,
    required this.confidence,
    required this.reason,
    required this.suggestedTime,
    this.weekday,
  });

  String get formattedTime {
    return '${predictedHour.toString().padLeft(2, '0')}:${predictedMinute.toString().padLeft(2, '0')}';
  }

  String get confidencePercent => '${(confidence * 100).toInt()}%';
}

final reminderPredictionServiceProvider = Provider<ReminderPredictionService>((ref) {
    final dbAsync = ref.watch(databaseProvider);
    return ReminderPredictionService(dbAsync);
});