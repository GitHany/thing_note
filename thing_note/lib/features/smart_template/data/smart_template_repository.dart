import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/smart_template/domain/smart_template.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartTemplateRepositoryProvider = Provider((ref) => SmartTemplateRepository(ref: ref));

class SmartTemplateRepository {
  final Ref _ref;

  SmartTemplateRepository({required Ref ref}) : _ref = ref;

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<void> initDefaultTemplates() async {
    final db = await _db;
    
    // Check if templates already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM smart_templates'),
    );
    
    if (count != null && count > 0) return;

    // Create default templates
    final defaultTemplates = [
      SmartTemplate(
        name: '工作',
        icon: '💼',
        color: '#2196F3',
        defaultDurationMinutes: 60,
        category: '工作',
        createdAt: DateTime.now(),
      ),
      SmartTemplate(
        name: '学习',
        icon: '📚',
        color: '#4CAF50',
        defaultDurationMinutes: 45,
        category: '学习',
        createdAt: DateTime.now(),
      ),
      SmartTemplate(
        name: '运动',
        icon: '🏃',
        color: '#FF9800',
        defaultDurationMinutes: 30,
        category: '健康',
        createdAt: DateTime.now(),
      ),
      SmartTemplate(
        name: '休息',
        icon: '☕',
        color: '#9C27B0',
        defaultDurationMinutes: 15,
        category: '生活',
        createdAt: DateTime.now(),
      ),
      SmartTemplate(
        name: '吃饭',
        icon: '🍽️',
        color: '#E91E63',
        defaultDurationMinutes: 30,
        category: '生活',
        createdAt: DateTime.now(),
      ),
      SmartTemplate(
        name: '阅读',
        icon: '📖',
        color: '#00BCD4',
        defaultDurationMinutes: 30,
        category: '学习',
        createdAt: DateTime.now(),
      ),
    ];

    for (final template in defaultTemplates) {
      await db.insert('smart_templates', template.toMap());
    }
  }

  Future<List<SmartTemplate>> getAllTemplates() async {
    final db = await _db;
    final results = await db.query(
      'smart_templates',
      orderBy: 'use_count DESC, is_favorite DESC, created_at DESC',
    );
    return results.map((e) => SmartTemplate.fromMap(e)).toList();
  }

  Future<List<SmartTemplate>> getTemplatesByCategory(String category) async {
    final db = await _db;
    final results = await db.query(
      'smart_templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'use_count DESC',
    );
    return results.map((e) => SmartTemplate.fromMap(e)).toList();
  }

  Future<List<SmartTemplate>> getFavoriteTemplates() async {
    final db = await _db;
    final results = await db.query(
      'smart_templates',
      where: 'is_favorite = 1',
      orderBy: 'use_count DESC',
    );
    return results.map((e) => SmartTemplate.fromMap(e)).toList();
  }

  Future<List<SmartTemplate>> getMostUsedTemplates({int limit = 5}) async {
    final db = await _db;
    final results = await db.query(
      'smart_templates',
      orderBy: 'use_count DESC',
      limit: limit,
    );
    return results.map((e) => SmartTemplate.fromMap(e)).toList();
  }

  Future<int> insertTemplate(SmartTemplate template) async {
    final db = await _db;
    return await db.insert('smart_templates', template.toMap());
  }

  Future<int> updateTemplate(SmartTemplate template) async {
    final db = await _db;
    return await db.update(
      'smart_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await _db;
    return await db.delete(
      'smart_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_templates SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> toggleFavorite(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_templates SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  /// Analyze usage patterns to suggest templates
  Future<List<TemplateSuggestion>> getSuggestions() async {
    final db = await _db;

    // Get templates that match the time pattern (simplified logic)
    final results = await db.rawQuery('''
      SELECT t.*, COUNT(r.id) as record_count
      FROM smart_templates t
      LEFT JOIN episode_records r ON t.name = (SELECT name FROM thing_names WHERE id = r.thing_name_id)
      GROUP BY t.id
      ORDER BY t.use_count DESC, record_count DESC
      LIMIT 5
    ''');

    return results.map((e) {
      final template = SmartTemplate.fromMap(e);
      return TemplateSuggestion(
        template: template,
        confidence: 0.7 + (template.useCount * 0.02).clamp(0, 0.3),
        reason: 'Based on your usage pattern',
      );
    }).toList();
  }

  /// Get templates used at similar times
  Future<List<SmartTemplate>> getTemplatesForTimeSlot() async {
    final db = await _db;
    final now = DateTime.now();
    final hour = now.hour;
    
    // Simplified time-based suggestion
    List<Map<String, dynamic>> results;
    
    if (hour >= 6 && hour < 12) {
      // Morning: work and exercise templates
      results = await db.query(
        'smart_templates',
        where: 'category IN (?, ?)',
        whereArgs: ['工作', '健康'],
        orderBy: 'use_count DESC',
        limit: 3,
      );
    } else if (hour >= 12 && hour < 14) {
      // Lunch: meal templates
      results = await db.query(
        'smart_templates',
        where: 'name LIKE ?',
        whereArgs: ['%吃饭%'],
        limit: 3,
      );
    } else if (hour >= 14 && hour < 18) {
      // Afternoon: work and study
      results = await db.query(
        'smart_templates',
        where: 'category IN (?, ?)',
        whereArgs: ['工作', '学习'],
        orderBy: 'use_count DESC',
        limit: 3,
      );
    } else if (hour >= 18 && hour < 22) {
      // Evening: leisure and rest
      results = await db.query(
        'smart_templates',
        where: 'category IN (?, ?)',
        whereArgs: ['生活', '健康'],
        orderBy: 'use_count DESC',
        limit: 3,
      );
    } else {
      // Night: rest
      results = await db.query(
        'smart_templates',
        where: 'name LIKE ?',
        whereArgs: ['%休息%'],
        limit: 3,
      );
    }

    if (results.isEmpty) {
      // Fallback to most used
      results = await db.query(
        'smart_templates',
        orderBy: 'use_count DESC',
        limit: 3,
      );
    }

    return results.map((e) => SmartTemplate.fromMap(e)).toList();
  }
}