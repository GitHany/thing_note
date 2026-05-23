import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/quick_template/domain/quick_template.dart';

class QuickTemplateRepository {
  final Ref _ref;

  QuickTemplateRepository(this._ref);

  static final defaultTemplates = [
    QuickTemplate(
      name: '工作',
      icon: '💼',
      color: '#2196F3',
      defaultDurationMinutes: 60,
      createdAt: DateTime.now(),
    ),
    QuickTemplate(
      name: '学习',
      icon: '📚',
      color: '#4CAF50',
      defaultDurationMinutes: 45,
      createdAt: DateTime.now(),
    ),
    QuickTemplate(
      name: '运动',
      icon: '🏃',
      color: '#FF9800',
      defaultDurationMinutes: 30,
      createdAt: DateTime.now(),
    ),
    QuickTemplate(
      name: '休息',
      icon: '😴',
      color: '#9C27B0',
      defaultDurationMinutes: 15,
      createdAt: DateTime.now(),
    ),
    QuickTemplate(
      name: '吃饭',
      icon: '🍽️',
      color: '#E91E63',
      defaultDurationMinutes: 30,
      createdAt: DateTime.now(),
    ),
    QuickTemplate(
      name: '通勤',
      icon: '🚗',
      color: '#607D8B',
      defaultDurationMinutes: 30,
      createdAt: DateTime.now(),
    ),
  ];

  Future<List<QuickTemplate>> getAllTemplates() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'quick_templates',
      orderBy: 'use_count DESC, is_favorite DESC',
    );
    return result.map((e) => QuickTemplate.fromMap(e)).toList();
  }

  Future<List<QuickTemplate>> getFavoriteTemplates() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'quick_templates',
      where: 'is_favorite = 1',
      orderBy: 'use_count DESC',
    );
    return result.map((e) => QuickTemplate.fromMap(e)).toList();
  }

  Future<List<QuickTemplate>> getMostUsedTemplates({int limit = 6}) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'quick_templates',
      orderBy: 'use_count DESC',
      limit: limit,
    );
    return result.map((e) => QuickTemplate.fromMap(e)).toList();
  }

  Future<int> insertTemplate(QuickTemplate template) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('quick_templates', template.toMap()..remove('id'));
  }

  Future<int> updateTemplate(QuickTemplate template) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'quick_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('quick_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorite(int id) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query('quick_templates', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return 0;

    final currentFavorite = (result.first['is_favorite'] as int?) == 1;
    return db.update(
      'quick_templates',
      {'is_favorite': currentFavorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementUseCount(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.rawUpdate(
      'UPDATE quick_templates SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> initDefaultTemplates() async {
    final db = await _ref.read(databaseProvider.future);
    final count = await db.rawQuery('SELECT COUNT(*) as cnt FROM quick_templates');
    if ((count.first['cnt'] as int) == 0) {
      for (final template in defaultTemplates) {
        await insertTemplate(template);
      }
    }
  }
}