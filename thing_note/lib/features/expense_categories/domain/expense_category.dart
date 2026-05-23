class ExpenseCategory {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final int budgetAmount;
  final bool isDefault;
  final String createdAt;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetAmount = 0,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'budget_amount': budgetAmount,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      budgetAmount: map['budget_amount'] as int? ?? 0,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? budgetAmount,
    bool? isDefault,
    String? createdAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<ExpenseCategory> get defaultCategories {
    final now = DateTime.now().toIso8601String();
    return [
      ExpenseCategory(name: '餐饮', icon: 'restaurant', color: '#FF5722', isDefault: true, createdAt: now),
      ExpenseCategory(name: '交通', icon: 'directions_car', color: '#2196F3', isDefault: true, createdAt: now),
      ExpenseCategory(name: '购物', icon: 'shopping_bag', color: '#E91E63', isDefault: true, createdAt: now),
      ExpenseCategory(name: '娱乐', icon: 'movie', color: '#9C27B0', isDefault: true, createdAt: now),
      ExpenseCategory(name: '医疗', icon: 'local_hospital', color: '#F44336', isDefault: true, createdAt: now),
      ExpenseCategory(name: '教育', icon: 'school', color: '#4CAF50', isDefault: true, createdAt: now),
      ExpenseCategory(name: '住房', icon: 'home', color: '#795548', isDefault: true, createdAt: now),
      ExpenseCategory(name: '通讯', icon: 'phone', color: '#00BCD4', isDefault: true, createdAt: now),
      ExpenseCategory(name: '其他', icon: 'more_horiz', color: '#607D8B', isDefault: true, createdAt: now),
    ];
  }
}