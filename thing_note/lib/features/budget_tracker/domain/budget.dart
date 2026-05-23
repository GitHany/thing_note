/// 预算数据模型
class Budget {
  final int? id;
  final String name;
  final double amount;
  final String period;
  final String? category;
  final String startDate;
  final String? endDate;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.name,
    required this.amount,
    this.period = 'monthly',
    this.category,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  Budget copyWith({
    int? id,
    String? name,
    double? amount,
    String? period,
    String? category,
    String? startDate,
    String? endDate,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'period': period,
      'category': category,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String? ?? 'monthly',
      category: map['category'] as String?,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 支出记录数据模型
class Expense {
  final int? id;
  final int? budgetId;
  final double amount;
  final String category;
  final String? merchant;
  final String? note;
  final String date;
  final int? linkedRecordId;
  final DateTime createdAt;

  const Expense({
    this.id,
    this.budgetId,
    required this.amount,
    required this.category,
    this.merchant,
    this.note,
    required this.date,
    this.linkedRecordId,
    required this.createdAt,
  });

  Expense copyWith({
    int? id,
    int? budgetId,
    double? amount,
    String? category,
    String? merchant,
    String? note,
    String? date,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      date: date ?? this.date,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'budget_id': budgetId,
      'amount': amount,
      'category': category,
      'merchant': merchant,
      'note': note,
      'date': date,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      budgetId: map['budget_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      merchant: map['merchant'] as String?,
      note: map['note'] as String?,
      date: map['date'] as String,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 支出分类常量
class ExpenseCategory {
  static const food = '餐饮';
  static const transport = '交通';
  static const shopping = '购物';
  static const entertainment = '娱乐';
  static const health = '健康';
  static const education = '教育';
  static const housing = '住房';
  static const utilities = '水电费';
  static const other = '其他';

  static const all = [food, transport, shopping, entertainment, health, education, housing, utilities, other];
}