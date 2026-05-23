import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_template_marketplace/domain/habit_template.dart';

final habitTemplateRepositoryProvider = Provider<HabitTemplateRepository>((ref) {
  return HabitTemplateRepository(ref.watch(databaseProvider.future));
});

class HabitTemplateRepository {
  final Future<Database> _dbFuture;

  HabitTemplateRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<HabitTemplate>> getAllTemplates() async {
    final db = await _db;
    final results = await db.query('habit_templates', orderBy: 'use_count DESC');
    return results.map((e) => HabitTemplate.fromMap(e)).toList();
  }

  Future<List<HabitTemplate>> getTemplatesByCategory(String category) async {
    final db = await _db;
    final results = await db.query(
      'habit_templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'rating DESC',
    );
    return results.map((e) => HabitTemplate.fromMap(e)).toList();
  }

  Future<List<HabitTemplate>> searchTemplates(String query) async {
    final db = await _db;
    final results = await db.query(
      'habit_templates',
      where: 'template_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'rating DESC',
    );
    return results.map((e) => HabitTemplate.fromMap(e)).toList();
  }

  Future<int> insertTemplate(HabitTemplate template) async {
    final db = await _db;
    return await db.insert('habit_templates', template.toMap()..remove('id'));
  }

  Future<int> updateTemplate(HabitTemplate template) async {
    final db = await _db;
    return await db.update(
      'habit_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await _db;
    return await db.delete('habit_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE habit_templates SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<Map<String, int>> getCategoryStats() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM habit_templates
      GROUP BY category
    ''');
    return {for (var r in results) r['category'] as String: r['count'] as int};
  }

  Future<void> initializeDefaultTemplates() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM habit_templates')) ?? 0;

    if (count == 0) {
      final defaults = [
        HabitTemplate(templateName: '每日早起', category: '生活', description: '养成早睡早起的好习惯'),
        HabitTemplate(templateName: '每日阅读30分钟', category: '学习', description: '每天阅读半小时，提升知识储备'),
        HabitTemplate(templateName: '晨间冥想', category: '冥想', description: '早晨冥想10分钟，开启美好一天'),
        HabitTemplate(templateName: '每日运动', category: '运动', description: '每天运动30分钟，保持健康'),
        HabitTemplate(templateName: '喝水提醒', category: '健康', description: '每小时喝水，保持水分'),
        HabitTemplate(templateName: '写日记', category: '生活', description: '每晚写日记，记录一天'),
      ];

      for (final template in defaults) {
        await db.insert('habit_templates', template.toMap()..remove('id'));
      }
    }
  }
}