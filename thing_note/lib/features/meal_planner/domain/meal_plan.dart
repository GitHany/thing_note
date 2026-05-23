class MealPlan {
  final int? id;
  final String date;
  final String mealType;
  final String? title;
  final String? description;
  final List<String>? ingredients;
  final int? calories;
  final String? recipeId;
  final bool isCompleted;
  final String createdAt;

  MealPlan({
    this.id,
    required this.date,
    required this.mealType,
    this.title,
    this.description,
    this.ingredients,
    this.calories,
    this.recipeId,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'meal_type': mealType,
      'title': title,
      'description': description,
      'ingredients': ingredients?.join(','),
      'calories': calories,
      'recipe_id': recipeId,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealType: map['meal_type'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      ingredients: map['ingredients'] != null ? (map['ingredients'] as String).split(',') : null,
      calories: map['calories'] as int?,
      recipeId: map['recipe_id'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  MealPlan copyWith({
    int? id, String? date, String? mealType, String? title, String? description,
    List<String>? ingredients, int? calories, String? recipeId, bool? isCompleted, String? createdAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      calories: calories ?? this.calories,
      recipeId: recipeId ?? this.recipeId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> mealTypes = ['早餐', '午餐', '晚餐', '宵夜', '零食'];
}

class GroceryItem {
  final int? id;
  final String name;
  final String? category;
  final int quantity;
  final String unit;
  final bool isPurchased;
  final String? note;
  final String createdAt;

  GroceryItem({
    this.id,
    required this.name,
    this.category,
    this.quantity = 1,
    this.unit = '个',
    this.isPurchased = false,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'is_purchased': isPurchased ? 1 : 0,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      unit: map['unit'] as String? ?? '个',
      isPurchased: (map['is_purchased'] as int? ?? 0) == 1,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}