/// 食谱数据模型
class Recipe {
  final int? id;
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? imagePath;
  final int? rating;
  final int timesCooked;
  final DateTime createdAt;

  const Recipe({
    this.id,
    required this.name,
    this.ingredients = const [],
    this.steps = const [],
    this.servings = 1,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.imagePath,
    this.rating,
    this.timesCooked = 0,
    required this.createdAt,
  });

  Recipe copyWith({
    int? id,
    String? name,
    List<String>? ingredients,
    List<String>? steps,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    String? imagePath,
    int? rating,
    int? timesCooked,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      timesCooked: timesCooked ?? this.timesCooked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'ingredients': ingredients.join('\n'),
      'steps': steps.join('\n'),
      'servings': servings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'image_path': imagePath,
      'rating': rating,
      'times_cooked': timesCooked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    final ingredientsStr = map['ingredients'] as String? ?? '';
    final stepsStr = map['steps'] as String? ?? '';
    
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      ingredients: ingredientsStr.isEmpty ? [] : ingredientsStr.split('\n'),
      steps: stepsStr.isEmpty ? [] : stepsStr.split('\n'),
      servings: map['servings'] as int? ?? 1,
      prepTimeMinutes: map['prep_time_minutes'] as int?,
      cookTimeMinutes: map['cook_time_minutes'] as int?,
      imagePath: map['image_path'] as String?,
      rating: map['rating'] as int?,
      timesCooked: map['times_cooked'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
}

/// 烹饪记录
class CookingLog {
  final int? id;
  final int recipeId;
  final DateTime cookedAt;
  final String? note;
  final int? rating;

  const CookingLog({
    this.id,
    required this.recipeId,
    required this.cookedAt,
    this.note,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'cooked_at': cookedAt.toIso8601String(),
      'note': note,
      'rating': rating,
    };
  }

  factory CookingLog.fromMap(Map<String, dynamic> map) {
    return CookingLog(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      cookedAt: DateTime.parse(map['cooked_at'] as String),
      note: map['note'] as String?,
      rating: map['rating'] as int?,
    );
  }
}