import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/template_models.dart';

/// 模板市场服务 Provider
final templateMarketplaceServiceProvider = Provider<TemplateMarketplaceService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TemplateMarketplaceService(dbAsync);
});

/// 模板列表 Provider
final marketplaceTemplatesProvider = FutureProvider<List<MarketplaceTemplate>>((ref) async {
  final service = ref.watch(templateMarketplaceServiceProvider);
  return service.getAllTemplates();
});

/// 模板分类列表 Provider
final templatesByCategoryProvider = FutureProvider.family<List<MarketplaceTemplate>, String>((ref, category) async {
  final service = ref.watch(templateMarketplaceServiceProvider);
  return service.getTemplatesByCategory(category);
});

/// 热门模板 Provider
final featuredTemplatesProvider = FutureProvider<List<MarketplaceTemplate>>((ref) async {
  final service = ref.watch(templateMarketplaceServiceProvider);
  return service.getFeaturedTemplates();
});

class TemplateMarketplaceService {
  final AsyncValue<Database> _dbAsync;

  TemplateMarketplaceService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有模板
  Future<List<MarketplaceTemplate>> getAllTemplates() async {
    final db = await _db;
    final maps = await db.query(
      'marketplace_templates',
      orderBy: 'download_count DESC, rating DESC',
    );
    return maps.map((m) => MarketplaceTemplate.fromMap(m)).toList();
  }

  /// 获取分类模板
  Future<List<MarketplaceTemplate>> getTemplatesByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      'marketplace_templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'download_count DESC, rating DESC',
    );
    return maps.map((m) => MarketplaceTemplate.fromMap(m)).toList();
  }

  /// 获取精选模板
  Future<List<MarketplaceTemplate>> getFeaturedTemplates() async {
    final db = await _db;
    final maps = await db.query(
      'marketplace_templates',
      where: 'is_featured = 1',
      orderBy: 'rating DESC',
      limit: 5,
    );
    return maps.map((m) => MarketplaceTemplate.fromMap(m)).toList();
  }

  /// 获取模板详情
  Future<MarketplaceTemplate?> getTemplateById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'marketplace_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MarketplaceTemplate.fromMap(maps.first);
  }

  /// 搜索模板
  Future<List<MarketplaceTemplate>> searchTemplates(String query) async {
    final db = await _db;
    final maps = await db.query(
      'marketplace_templates',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'download_count DESC',
    );
    return maps.map((m) => MarketplaceTemplate.fromMap(m)).toList();
  }

  /// 添加模板
  Future<int> addTemplate(MarketplaceTemplate template) async {
    final db = await _db;
    return db.insert('marketplace_templates', template.toMap()..remove('id'));
  }

  /// 更新模板
  Future<int> updateTemplate(MarketplaceTemplate template) async {
    final db = await _db;
    return db.update(
      'marketplace_templates',
      template.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// 删除模板
  Future<int> deleteTemplate(int id) async {
    final db = await _db;
    return db.delete('marketplace_templates', where: 'id = ?', whereArgs: [id]);
  }

  /// 增加下载次数
  Future<void> incrementDownloadCount(int templateId) async {
    final db = await _db;
    final template = await getTemplateById(templateId);
    if (template != null) {
      await db.update(
        'marketplace_templates',
        {'download_count': template.downloadCount + 1},
        where: 'id = ?',
        whereArgs: [templateId],
      );
    }
  }

  /// 添加评分
  Future<int> addRating(TemplateRating rating) async {
    final db = await _db;
    final id = await db.insert('template_ratings', rating.toMap()..remove('id'));

    // 更新模板平均评分
    final ratings = await db.query(
      'template_ratings',
      where: 'template_id = ?',
      whereArgs: [rating.templateId],
    );

    double totalRating = 0;
    for (final r in ratings) {
      totalRating += r['rating'] as int;
    }
    final avgRating = totalRating / ratings.length;

    await db.update(
      'marketplace_templates',
      {'rating': avgRating},
      where: 'id = ?',
      whereArgs: [rating.templateId],
    );

    return id;
  }

  /// 获取模板评分列表
  Future<List<TemplateRating>> getTemplateRatings(int templateId) async {
    final db = await _db;
    final maps = await db.query(
      'template_ratings',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => TemplateRating.fromMap(m)).toList();
  }

  /// 导入模板到本地
  Future<int> importTemplate(MarketplaceTemplate template) async {
    final db = await _db;

    // 解析模板数据
    final templateData = template.templateData;
    
    // 创建本地模板
    return db.insert('templates', {
      'name': template.name,
      'category': template.category,
      'description': template.description,
      'default_thing_name': templateData,
      'default_tags': '',
      'default_duration': 0,
      'use_count': 0,
      'is_favorite': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}