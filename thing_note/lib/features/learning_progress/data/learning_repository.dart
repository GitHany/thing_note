import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/learning_progress/domain/learning_model.dart';

/// Repository for Learning Progress data operations
class LearningRepository {
  final Database db;

  LearningRepository(this.db);

  // ========== Subject Operations ==========

  /// Create a new learning subject
  Future<int> createSubject(LearningSubject subject) async {
    return await db.insert('learning_progress', {
      'subject': subject.subject,
      'description': subject.description,
      'total_hours': subject.totalHours,
      'target_hours': subject.targetHours,
      'proficiency_level': subject.proficiencyLevel,
      'status': subject.status,
      'last_studied': subject.lastStudied?.toIso8601String(),
      'next_milestone': subject.nextMilestone,
      'created_at': subject.createdAt.toIso8601String(),
      'updated_at': subject.updatedAt.toIso8601String(),
    });
  }

  /// Update a learning subject
  Future<int> updateSubject(LearningSubject subject) async {
    return await db.update(
      'learning_progress',
      {
        'subject': subject.subject,
        'description': subject.description,
        'total_hours': subject.totalHours,
        'target_hours': subject.targetHours,
        'proficiency_level': subject.proficiencyLevel,
        'status': subject.status,
        'last_studied': subject.lastStudied?.toIso8601String(),
        'next_milestone': subject.nextMilestone,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  /// Get all learning subjects
  Future<List<LearningSubject>> getAllSubjects() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_progress',
      orderBy: 'last_studied DESC, created_at DESC',
    );
    return maps.map((map) => LearningSubject.fromMap(map)).toList();
  }

  /// Get active subjects
  Future<List<LearningSubject>> getActiveSubjects() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_progress',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'last_studied DESC',
    );
    return maps.map((map) => LearningSubject.fromMap(map)).toList();
  }

  /// Get subject by ID
  Future<LearningSubject?> getSubjectById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_progress',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return LearningSubject.fromMap(maps.first);
  }

  /// Delete a subject
  Future<int> deleteSubject(int id) async {
    return await db.delete(
      'learning_progress',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get subjects by status
  Future<List<LearningSubject>> getSubjectsByStatus(String status) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_progress',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LearningSubject.fromMap(map)).toList();
  }

  // ========== Session Operations ==========

  /// Create a learning session
  Future<int> createSession(LearningSession session) async {
    return await db.insert('learning_sessions', session.toMap());
  }

  /// Get sessions by subject
  Future<List<LearningSession>> getSessionsBySubject(String subject) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_sessions',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'session_date DESC',
    );
    return maps.map((map) => LearningSession.fromMap(map)).toList();
  }

  /// Get sessions by date range
  Future<List<LearningSession>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_sessions',
      where: 'session_date >= ? AND session_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'session_date DESC',
    );
    return maps.map((map) => LearningSession.fromMap(map)).toList();
  }

  /// Get recent sessions
  Future<List<LearningSession>> getRecentSessions({int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_sessions',
      orderBy: 'session_date DESC',
      limit: limit,
    );
    return maps.map((map) => LearningSession.fromMap(map)).toList();
  }

  // ========== Statistics Operations ==========

  /// Get learning statistics
  Future<LearningStats> getStats() async {
    // Get subject counts
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM learning_progress');
    final active = await db.rawQuery(
      'SELECT COUNT(*) as count FROM learning_progress WHERE status = ?',
      ['active'],
    );
    final completed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM learning_progress WHERE status = ?',
      ['completed'],
    );

    // Get hours for this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekSessions = await getSessionsByDateRange(weekStartDate, now);
    int weekMinutes = 0;
    for (final session in weekSessions) {
      weekMinutes += session.durationMinutes;
    }

    // Get hours for this month
    final monthStart = DateTime(now.year, now.month, 1);
    final monthSessions = await getSessionsByDateRange(monthStart, now);
    int monthMinutes = 0;
    for (final session in monthSessions) {
      monthMinutes += session.durationMinutes;
    }

    // Get average proficiency
    final avgProficiency = await db.rawQuery(
      'SELECT AVG(proficiency_level) as avg FROM learning_progress WHERE status = ?',
      ['active'],
    );

    // Get most studied subject
    final subjectHours = await db.rawQuery('''
      SELECT subject, SUM(duration_minutes) as total_minutes 
      FROM learning_sessions 
      GROUP BY subject 
      ORDER BY total_minutes DESC 
      LIMIT 1
    ''');

    return LearningStats(
      totalSubjects: (total.first['count'] as int?) ?? 0,
      activeSubjects: (active.first['count'] as int?) ?? 0,
      completedSubjects: (completed.first['count'] as int?) ?? 0,
      totalHoursThisWeek: weekMinutes ~/ 60,
      totalHoursThisMonth: monthMinutes ~/ 60,
      averageProficiency: (avgProficiency.first['avg'] as num?)?.toDouble() ?? 0,
      mostStudiedSubject: subjectHours.isNotEmpty 
          ? (subjectHours.first['subject'] as String?) ?? '' 
          : '',
      currentStreak: 0, // Calculate from consecutive days
    );
  }

  /// Get subject progress
  Future<double> getSubjectProgress(int subjectId) async {
    final subject = await getSubjectById(subjectId);
    if (subject == null) return 0;
    return subject.progressPercentage;
  }

  /// Update subject hours
  Future<void> updateSubjectHours(int subjectId, int additionalMinutes) async {
    final subject = await getSubjectById(subjectId);
    if (subject == null) return;

    await db.update(
      'learning_progress',
      {
        'total_hours': subject.totalHours + (additionalMinutes ~/ 60),
        'last_studied': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subjectId],
    );
  }

  /// Search subjects
  Future<List<LearningSubject>> searchSubjects(String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'learning_progress',
      where: 'subject LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((map) => LearningSubject.fromMap(map)).toList();
  }
}