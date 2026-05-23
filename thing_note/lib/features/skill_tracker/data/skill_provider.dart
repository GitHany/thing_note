// Skill Tracker Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/skill_tracker/domain/skill_models.dart';

// All skills provider
final skillsProvider = FutureProvider<List<Skill>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('skills', orderBy: 'last_practiced_at DESC');
  return results.map((r) => Skill.fromMap(r)).toList();
});

// Skills by category provider
final skillsByCategoryProvider = FutureProvider.family<List<Skill>, String>((ref, category) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'skills',
    where: 'category = ?',
    whereArgs: [category],
    orderBy: 'last_practiced_at DESC',
  );
  return results.map((r) => Skill.fromMap(r)).toList();
});

// Active learning skills
final activeSkillsProvider = FutureProvider<List<Skill>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'skills',
    where: 'status != ?',
    whereArgs: ['mastered'],
    orderBy: 'last_practiced_at DESC',
  );
  return results.map((r) => Skill.fromMap(r)).toList();
});

// Skill milestones provider
final skillMilestonesProvider = FutureProvider.family<List<SkillMilestone>, int>((ref, skillId) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'skill_milestones',
    where: 'skill_id = ?',
    whereArgs: [skillId],
    orderBy: 'target_hours ASC',
  );
  return results.map((r) => SkillMilestone.fromMap(r)).toList();
});

// Skill statistics provider
final skillStatsProvider = FutureProvider<SkillStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final allSkills = await db.query('skills');
  final activeSkills = await db.query(
    'skills',
    where: 'status != ?',
    whereArgs: ['mastered'],
  );
  final masteredSkills = await db.query(
    'skills',
    where: 'status = ?',
    whereArgs: ['mastered'],
  );
  
  int totalHours = 0;
  for (final skill in allSkills) {
    totalHours += skill['total_hours'] as int? ?? 0;
  }
  
  return SkillStats(
    totalSkills: allSkills.length,
    activeSkills: activeSkills.length,
    masteredSkills: masteredSkills.length,
    totalHours: totalHours,
  );
});

class SkillStats {
  final int totalSkills;
  final int activeSkills;
  final int masteredSkills;
  final int totalHours;
  
  SkillStats({
    required this.totalSkills,
    required this.activeSkills,
    required this.masteredSkills,
    required this.totalHours,
  });
}

class SkillRepository {
  final dynamic db;
  
  SkillRepository(this.db);
  
  Future<int> createSkill(Skill skill) async {
    return await db.insert('skills', skill.toMap());
  }
  
  Future<void> updateSkill(Skill skill) async {
    await db.update(
      'skills',
      {
        ...skill.toMap(),
        'last_practiced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }
  
  Future<void> deleteSkill(int id) async {
    await db.delete('skill_milestones', where: 'skill_id = ?', whereArgs: [id]);
    await db.delete('skills', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> updateSkillProgress(int skillId, int hoursToAdd) async {
    final skill = await db.query('skills', where: 'id = ?', whereArgs: [skillId]);
    if (skill.isEmpty) return;
    
    final currentHours = skill.first['total_hours'] as int? ?? 0;
    final newHours = currentHours + hoursToAdd;
    
    // Check if level up
    final targetLevel = skill.first['target_level'] as int? ?? 10;
    final newLevel = (newHours ~/ 100).clamp(1, targetLevel);
    
    await db.update(
      'skills',
      {
        'total_hours': newHours,
        'current_level': newLevel,
        'status': newLevel >= targetLevel ? 'mastered' : 'learning',
        'last_practiced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [skillId],
    );
  }
  
  Future<int> addMilestone(SkillMilestone milestone) async {
    return await db.insert('skill_milestones', milestone.toMap());
  }
  
  Future<void> updateMilestone(SkillMilestone milestone) async {
    await db.update('skill_milestones', milestone.toMap(), where: 'id = ?', whereArgs: [milestone.id]);
  }
  
  Future<void> deleteMilestone(int id) async {
    await db.delete('skill_milestones', where: 'id = ?', whereArgs: [id]);
  }
}