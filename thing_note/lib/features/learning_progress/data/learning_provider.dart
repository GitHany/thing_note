// Deep Work feature
// Version: 1.0
// Description: 深度工作会话追踪，记录专注时长、专注评分和分心次数

import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Learning Progress Provider
final learningProgressProvider = FutureProvider<List<LearningProgress>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final List<Map<String, dynamic>> maps = await db.query(
    'learning_progress',
    orderBy: 'last_studied DESC',
  );
  return maps.map((map) => LearningProgress.fromMap(map)).toList();
});

final skillMasteryProvider = FutureProvider<Map<String, double>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      subject,
      AVG(proficiency_level) as avg_proficiency,
      COUNT(*) as total_sessions
    FROM learning_sessions
    WHERE completed_at IS NOT NULL
    GROUP BY subject
  ''');
  
  final Map<String, double> mastery = {};
  for (final map in maps) {
    mastery[map['subject'] as String] = (map['avg_proficiency'] as num?)?.toDouble() ?? 0.0;
  }
  
  return mastery;
});

class LearningProgress {
  final int? id;
  final String subject;
  final String description;
  final int totalHours;
  final int targetHours;
  final double proficiencyLevel;
  final String status;
  final String? lastStudied;
  final String? nextMilestone;
  final String createdAt;
  final String updatedAt;

  LearningProgress({
    this.id,
    required this.subject,
    this.description = '',
    this.totalHours = 0,
    this.targetHours = 100,
    this.proficiencyLevel = 0.0,
    this.status = 'active',
    this.lastStudied,
    this.nextMilestone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      description: map['description'] as String? ?? '',
      totalHours: map['total_hours'] as int? ?? 0,
      targetHours: map['target_hours'] as int? ?? 100,
      proficiencyLevel: (map['proficiency_level'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'active',
      lastStudied: map['last_studied'] as String?,
      nextMilestone: map['next_milestone'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'description': description,
      'total_hours': totalHours,
      'target_hours': targetHours,
      'proficiency_level': proficiencyLevel,
      'status': status,
      'last_studied': lastStudied,
      'next_milestone': nextMilestone,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  double get progressPercent => targetHours > 0 ? (totalHours / targetHours * 100).clamp(0, 100) : 0;
}

class LearningSession {
  final int? id;
  final String subject;
  final String? topic;
  final int durationMinutes;
  final double proficiencyLevel;
  final String? notes;
  final String? resource;
  final String? completedAt;
  final String sessionDate;
  final String createdAt;

  LearningSession({
    this.id,
    required this.subject,
    this.topic,
    this.durationMinutes = 0,
    this.proficiencyLevel = 0.0,
    this.notes,
    this.resource,
    this.completedAt,
    required this.sessionDate,
    required this.createdAt,
  });

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      topic: map['topic'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      proficiencyLevel: (map['proficiency_level'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      resource: map['resource'] as String?,
      completedAt: map['completed_at'] as String?,
      sessionDate: map['session_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'topic': topic,
      'duration_minutes': durationMinutes,
      'proficiency_level': proficiencyLevel,
      'notes': notes,
      'resource': resource,
      'completed_at': completedAt,
      'session_date': sessionDate,
      'created_at': createdAt,
    };
  }
}

// Learning Repository
class LearningRepository {
  final Database db;

  LearningRepository(this.db);

  Future<int> addProgress(LearningProgress progress) async {
    return await db.insert('learning_progress', progress.toMap());
  }

  Future<void> updateProgress(LearningProgress progress) async {
    await db.update(
      'learning_progress',
      progress.toMap(),
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }

  Future<List<LearningSession>> getRecentSessions({int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_sessions',
      orderBy: 'session_date DESC',
      limit: limit,
    );
    return maps.map((map) => LearningSession.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getSubjectStats(String subject) async {
    final sessions = await db.query(
      'learning_sessions',
      where: 'subject = ?',
      whereArgs: [subject],
    );
    
    int totalMinutes = 0;
    double totalProficiency = 0;
    int completedCount = 0;
    
    for (final session in sessions) {
      totalMinutes += (session['duration_minutes'] as int?) ?? 0;
      totalProficiency += (session['proficiency_level'] as num?)?.toDouble() ?? 0;
      if (session['completed_at'] != null) completedCount++;
    }
    
    return {
      'total_sessions': sessions.length,
      'total_minutes': totalMinutes,
      'avg_proficiency': sessions.isNotEmpty ? totalProficiency / sessions.length : 0,
      'completed_count': completedCount,
    };
  }
}