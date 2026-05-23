class SubscriptionEntry {
  final int? id;
  final String name;
  final String? category;
  final double amount;
  final String billingCycle;
  final String? nextBillingDate;
  final String? website;
  final String? note;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  SubscriptionEntry({
    this.id,
    required this.name,
    this.category,
    required this.amount,
    this.billingCycle = 'monthly',
    this.nextBillingDate,
    this.website,
    this.note,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'billing_cycle': billingCycle,
      'next_billing_date': nextBillingDate,
      'website': website,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory SubscriptionEntry.fromMap(Map<String, dynamic> map) {
    return SubscriptionEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      amount: (map['amount'] as num).toDouble(),
      billingCycle: map['billing_cycle'] as String? ?? 'monthly',
      nextBillingDate: map['next_billing_date'] as String?,
      website: map['website'] as String?,
      note: map['note'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  SubscriptionEntry copyWith({
    int? id,
    String? name,
    String? category,
    double? amount,
    String? billingCycle,
    String? nextBillingDate,
    String? website,
    String? note,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return SubscriptionEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      website: website ?? this.website,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get yearlyAmount {
    switch (billingCycle) {
      case 'daily':
        return amount * 365;
      case 'weekly':
        return amount * 52;
      case 'monthly':
        return amount * 12;
      case 'yearly':
        return amount;
      default:
        return amount * 12;
    }
  }

  static const List<String> categories = [
    '流媒体', '音乐', '云存储', '游戏', '软件', '健身', '新闻', '教育', '其他',
  ];

  static const List<String> billingCycles = [
    'daily', 'weekly', 'monthly', 'quarterly', 'yearly',
  ];
}