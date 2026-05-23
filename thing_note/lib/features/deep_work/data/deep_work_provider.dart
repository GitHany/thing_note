import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

final deepWorkSessionsProvider = FutureProvider<List<DeepWorkSession>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final List<Map<String, dynamic>> maps = await db.query(
    'deep_work_sessions',
    orderBy: 'started_at DESC',
  );
  return maps.map((map) => DeepWorkSession.fromMap(map)).toList();
});

final deepWorkStatsProvider = FutureProvider<DeepWorkStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final todaySessions = await db.query(
    'deep_work_sessions',
    where: 'started_at >= ? AND started_at < ?',
    whereArgs: [todayStart.toIso8601String(), todayEnd.toIso8601String()],
  );

  final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));

  final weekSessions = await db.query(
    'deep_work_sessions',
    where: 'started_at >= ?',
    whereArgs: [weekStart.toIso8601String()],
  );

  int todayMinutes = 0;
  int todayCount = 0;
  int todayFocusScore = 0;

  for (final session in todaySessions) {
    if (session['ended_at'] != null) {
      todayMinutes += (session['duration_minutes'] as int?) ?? 0;
      todayCount++;
      todayFocusScore += (session['focus_score'] as int?) ?? 0;
    }
  }

  int weekMinutes = 0;
  int weekCount = 0;
  int weekFocusScore = 0;

  for (final session in weekSessions) {
    if (session['ended_at'] != null) {
      weekMinutes += (session['duration_minutes'] as int?) ?? 0;
      weekCount++;
      weekFocusScore += (session['focus_score'] as int?) ?? 0;
    }
  }

  return DeepWorkStats(
    todayMinutes: todayMinutes,
    todaySessions: todayCount,
    todayAvgFocus: todayCount > 0 ? todayFocusScore ~/ todayCount : 0,
    weekMinutes: weekMinutes,
    weekSessions: weekCount,
    weekAvgFocus: weekCount > 0 ? weekFocusScore ~/ weekCount : 0,
  );
});

class DeepWorkSession {
  final int? id;
  final String startedAt;
  final String? endedAt;
  final int durationMinutes;
  final int focusScore;
  final int distractionCount;
  final String? linkedRecordId;
  final String? note;
  final String createdAt;

  DeepWorkSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.focusScore = 0,
    this.distractionCount = 0,
    this.linkedRecordId,
    this.note,
    required this.createdAt,
  });

  factory DeepWorkSession.fromMap(Map<String, dynamic> map) {
    return DeepWorkSession(
      id: map['id'] as int?,
      startedAt: map['started_at'] as String,
      endedAt: map['ended_at'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      focusScore: map['focus_score'] as int? ?? 0,
      distractionCount: map['distraction_count'] as int? ?? 0,
      linkedRecordId: map['linked_record_id'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'started_at': startedAt,
      'ended_at': endedAt,
      'duration_minutes': durationMinutes,
      'focus_score': focusScore,
      'distraction_count': distractionCount,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt,
    };
  }

  bool get isActive => endedAt == null;
}

class DeepWorkStats {
  final int todayMinutes;
  final int todaySessions;
  final int todayAvgFocus;
  final int weekMinutes;
  final int weekSessions;
  final int weekAvgFocus;

  DeepWorkStats({
    required this.todayMinutes,
    required this.todaySessions,
    required this.todayAvgFocus,
    required this.weekMinutes,
    required this.weekSessions,
    required this.weekAvgFocus,
  });
}
