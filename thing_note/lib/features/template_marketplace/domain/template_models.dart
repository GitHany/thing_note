import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 模板分类
enum TemplateCategory { work, health, learning, life, other }

extension TemplateCategoryExtension on TemplateCategory {
  String get label {
    switch (this) {
      case TemplateCategory.work: return '工作';
      case TemplateCategory.health: return '健康';
      case TemplateCategory.learning: return '学习';
      case TemplateCategory.life: return '生活';
      case TemplateCategory.other: return '其他';
    }
  }

  String get value => name;
}

/// Helper function to parse TemplateCategory from string value
TemplateCategory parseTemplateCategory(String value) {
  return TemplateCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TemplateCategory.other,
  );
}

/// 模板评分
class TemplateRating {
  final int id;
  final int templateId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  const TemplateRating({
    required this.id,
    required this.templateId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  // 兼容旧代码：无参数的默认构造
  factory TemplateRating.empty() => TemplateRating(
    id: 0,
    templateId: 0,
    rating: 0,
    createdAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'template_id': templateId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };

  factory TemplateRating.fromMap(Map<String, dynamic> map) => TemplateRating(
    id: map['id'] as int,
    templateId: map['template_id'] as int,
    rating: map['rating'] as int,
    comment: map['comment'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

/// 模板市场模板（来自网络/API）
class MarketplaceTemplate {
  final int id;
  final String name;
  final String category;
  final String? description;
  final String? authorName;
  final int downloadCount;
  final double rating;
  final bool isFeatured;
  final String templateData;
  final DateTime? createdAt;

  MarketplaceTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.authorName,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.isFeatured = false,
    this.templateData = '{}',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 兼容旧代码：无参数的默认构造
  factory MarketplaceTemplate.empty() => MarketplaceTemplate(
    id: 0,
    name: '',
    category: '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'author_name': authorName,
    'download_count': downloadCount,
    'rating': rating,
    'is_featured': isFeatured ? 1 : 0,
    'template_data': templateData,
  };

  factory MarketplaceTemplate.fromMap(Map<String, dynamic> map) => MarketplaceTemplate(
    id: map['id'] as int,
    name: map['name'] as String,
    category: map['category'] as String,
    description: map['description'] as String?,
    authorName: map['author_name'] as String?,
    downloadCount: map['download_count'] as int? ?? 0,
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    isFeatured: (map['is_featured'] as int?) == 1,
    templateData: map['template_data'] as String? ?? '{}',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
  );

  // 兼容旧代码：fromValue
  factory MarketplaceTemplate.fromValue(String value) {
    return MarketplaceTemplate(
      id: int.tryParse(value) ?? 0,
      name: '',
      category: '',
    );
  }
}

/// 模板项
class TemplateItem {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String defaultThingName;
  final List<String> defaultTags;
  final int durationMinutes;
  final int useCount;
  final bool isFavorite;
  final String icon;

  const TemplateItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.defaultThingName,
    required this.defaultTags,
    this.durationMinutes = 60,
    this.useCount = 0,
    this.isFavorite = false,
    this.icon = '📝',
  });
}

/// 模板市场 Provider
final templateMarketProvider = StateNotifierProvider<TemplateMarketNotifier, AsyncValue<List<TemplateItem>>>((ref) {
  return TemplateMarketNotifier();
});

class TemplateMarketNotifier extends StateNotifier<AsyncValue<List<TemplateItem>>> {
  TemplateMarketNotifier() : super(const AsyncValue.loading());

  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data([
        const TemplateItem(id: '1', name: '工作会议', category: '工作', defaultThingName: '会议', defaultTags: ['重要'], icon: '💼'),
        const TemplateItem(id: '2', name: '晨间运动', category: '健康', defaultThingName: '运动', defaultTags: ['健康', '早起'], icon: '🏃'),
        const TemplateItem(id: '3', name: '阅读学习', category: '学习', defaultThingName: '阅读', defaultTags: ['学习'], icon: '📚'),
        const TemplateItem(id: '4', name: '团队协作', category: '工作', defaultThingName: '团队', defaultTags: ['协作'], icon: '👥'),
        const TemplateItem(id: '5', name: '冥想放松', category: '健康', defaultThingName: '冥想', defaultTags: ['放松'], icon: '🧘'),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<String> get categories {
    final items = state.value ?? [];
    return items.map((e) => e.category).toSet().toList()..sort();
  }

  Future<void> toggleFavorite(String id) async {
    state.whenData((templates) {
      state = AsyncValue.data(
        templates.map((t) => t.id == id ? TemplateItem(icon: t.icon, id: t.id, name: t.name, category: t.category, description: t.description, defaultThingName: t.defaultThingName, defaultTags: t.defaultTags, durationMinutes: t.durationMinutes, useCount: t.useCount, isFavorite: !t.isFavorite) : t).toList(),
      );
    });
  }
}