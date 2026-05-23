import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/skill_log_model.dart';

final skillLogRepositoryProvider = Provider<SkillLogRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SkillLogRepository(dbAsync);
});

class SkillLogRepository {
  final AsyncValue<Database> _dbAsync;

  SkillLogRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSkill(SkillLog skill) async {
    final db = await _db;
    return await db.insert('skill_logs', skill.toMap());
  }

  Future<int> updateSkill(SkillLog skill) async {
    final db = await _db;
    return await db.update(
      'skill_logs',
      skill.toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  Future<int> deleteSkill(int id) async {
    final db = await _db;
    return await db.delete(
      'skill_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SkillLog>> getAllSkills() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'skill_logs',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SkillLog.fromMap(map)).toList();
  }

  Future<List<SkillSession>> getSessionsBySkillId(int skillId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'skill_sessions',
      where: 'skill_id = ?',
      whereArgs: [skillId],
      orderBy: 'session_date DESC',
    );
    return maps.map((map) => SkillSession.fromMap(map)).toList();
  }

  Future<int> insertSession(SkillSession session) async {
    final db = await _db;
    final id = await db.insert('skill_sessions', session.toMap());
    
    final skill = await getSkillById(session.skillId);
    if (skill != null) {
      final newTotalHours = skill.totalHours + (session.durationMinutes ~/ 60);
      await updateSkill(skill.copyWith(
        totalHours: newTotalHours,
        updatedAt: DateTime.now().toIso8601String(),
      ));
      
      await checkAndUpdateLevel(skill, newTotalHours);
    }
    
    return id;
  }

  Future<SkillLog?> getSkillById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'skill_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SkillLog.fromMap(maps.first);
    }
    return null;
  }

  Future<void> checkAndUpdateLevel(SkillLog skill, int newTotalHours) async {
    String newLevel = skill.currentLevel;
    
    if (newTotalHours >= 1000) {
      newLevel = 'expert';
    } else if (newTotalHours >= 500) {
      newLevel = 'advanced';
    } else if (newTotalHours >= 200) {
      newLevel = 'intermediate';
    } else if (newTotalHours >= 50) {
      newLevel = 'elementary';
    }
    
    if (newLevel != skill.currentLevel) {
      await updateSkill(skill.copyWith(
        currentLevel: newLevel,
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }
  }

  Future<Map<String, dynamic>> getSkillStatistics(int skillId) async {
    final db = await _db;
    
    final totalHours = await db.rawQuery('''
      SELECT SUM(duration_minutes) as total FROM skill_sessions WHERE skill_id = ?
    ''', [skillId]);
    
    final sessionsCount = await db.rawQuery('''
      SELECT COUNT(*) as count FROM skill_sessions WHERE skill_id = ?
    ''', [skillId]);
    
    final avgRating = await db.rawQuery('''
      SELECT AVG(rating) as avg FROM skill_sessions WHERE skill_id = ?
    ''', [skillId]);
    
    final thisWeek = await db.rawQuery('''
      SELECT SUM(duration_minutes) as total FROM skill_sessions 
      WHERE skill_id = ? AND session_date >= date('now', '-7 days')
    ''', [skillId]);
    
    return {
      'total_minutes': totalHours.first['total'] as int? ?? 0,
      'sessions_count': sessionsCount.first['count'] as int? ?? 0,
      'avg_rating': avgRating.first['avg'] as double? ?? 0,
      'this_week_minutes': thisWeek.first['total'] as int? ?? 0,
    };
  }

  Future<Map<String, int>> getOverallStatistics() async {
    final db = await _db;
    
    final totalSkills = await db.rawQuery('SELECT COUNT(*) as count FROM skill_logs WHERE is_active = 1');
    final totalHours = await db.rawQuery('SELECT SUM(duration_minutes) as total FROM skill_sessions');
    final totalSessions = await db.rawQuery('SELECT COUNT(*) as count FROM skill_sessions');
    
    return {
      'active_skills': totalSkills.first['count'] as int? ?? 0,
      'total_minutes': totalHours.first['total'] as int? ?? 0,
      'total_sessions': totalSessions.first['count'] as int? ?? 0,
    };
  }
}
