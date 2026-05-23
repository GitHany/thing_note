import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 习惯模板服务 Provider
final habitTemplatesServiceProvider = Provider<HabitTemplatesService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HabitTemplatesService(dbAsync);
});

/// 习惯模板列表 Provider
final habitTemplatesProvider = FutureProvider<List<HabitTemplate>>((ref) async {
  final service = ref.watch(habitTemplatesServiceProvider);
  return service.getAllTemplates();
});

/// 推荐模板 Provider
final recommendedTemplatesProvider = FutureProvider<List<HabitTemplate>>((ref) async {
  final service = ref.watch(habitTemplatesServiceProvider);
  return service.getRecommendedTemplates();
});

class HabitTemplatesService {
  final AsyncValue<Database> _dbAsync;

  HabitTemplatesService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有模板
  Future<List<HabitTemplate>> getAllTemplates() async {
    final db = await _db;
    final maps = await db.query('habit_templates', orderBy: 'success_rate DESC');
    return maps.map((m) => HabitTemplate.fromMap(m)).toList();
  }

  /// 获取推荐模板
  Future<List<HabitTemplate>> getRecommendedTemplates() async {
    final db = await _db;
    final maps = await db.query(
      'habit_templates',
      orderBy: 'use_count DESC',
      limit: 5,
    );
    return maps.map((m) => HabitTemplate.fromMap(m)).toList();
  }

  /// 获取分类模板
  Future<List<HabitTemplate>> getTemplatesByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      'habit_templates',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((m) => HabitTemplate.fromMap(m)).toList();
  }

  /// 添加模板
  Future<int> addTemplate(HabitTemplate template) async {
    final db = await _db;
    return db.insert('habit_templates', template.toMap()..remove('id'));
  }

  /// 使用模板创建习惯
  Future<int> createHabitFromTemplate(HabitTemplate template) async {
    final db = await _db;
    
    // 增加使用次数
    await db.rawQuery(
      'UPDATE habit_templates SET use_count = use_count + 1 WHERE id = ?',
      [template.id],
    );

    // 创建习惯
    return db.insert('habits', {
      'name': template.name,
      'description': template.description,
      'frequency': template.frequency,
      'target_days': template.targetDays,
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  }
}

/// 习惯模板模型
class HabitTemplate {
  final int? id;
  final String name;
  final String? description;
  final String category; // health, study, work, social
  final String frequency; // daily, weekly
  final int targetDays;
  final int useCount;
  final double successRate;
  final DateTime createdAt;

  HabitTemplate({
    this.id,
    required this.name,
    this.description,
    required this.category,
    this.frequency = 'daily',
    this.targetDays = 21,
    this.useCount = 0,
    this.successRate = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'frequency': frequency,
      'target_days': targetDays,
      'use_count': useCount,
      'success_rate': successRate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitTemplate.fromMap(Map<String, dynamic> map) {
    return HabitTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      targetDays: map['target_days'] as int? ?? 21,
      useCount: map['use_count'] as int? ?? 0,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'health':
        return '健康';
      case 'study':
        return '学习';
      case 'work':
        return '工作';
      case 'social':
        return '社交';
      default:
        return category;
    }
  }
}