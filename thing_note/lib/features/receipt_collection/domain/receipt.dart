/// 发票收集数据模型
class Receipt {
  final int? id;
  final String? merchant;
  final double? amount;
  final String? currency;
  final String? category;
  final DateTime? purchaseDate;
  final String? imagePath;
  final String? note;
  final bool isVerified;
  final bool isClaimed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Receipt({
    this.id,
    this.merchant,
    this.amount,
    this.currency = 'CNY',
    this.category,
    this.purchaseDate,
    this.imagePath,
    this.note,
    this.isVerified = false,
    this.isClaimed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Receipt copyWith({
    int? id,
    String? merchant,
    double? amount,
    String? currency,
    String? category,
    DateTime? purchaseDate,
    String? imagePath,
    String? note,
    bool? isVerified,
    bool? isClaimed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      isVerified: isVerified ?? this.isVerified,
      isClaimed: isClaimed ?? this.isClaimed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'amount': amount,
      'currency': currency,
      'category': category,
      'purchase_date': purchaseDate?.toIso8601String(),
      'image_path': imagePath,
      'note': note,
      'is_verified': isVerified ? 1 : 0,
      'is_claimed': isClaimed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as int?,
      merchant: map['merchant'] as String?,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      currency: map['currency'] as String? ?? 'CNY',
      category: map['category'] as String?,
      purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date'] as String) : null,
      imagePath: map['image_path'] as String?,
      note: map['note'] as String?,
      isVerified: (map['is_verified'] as int?) == 1,
      isClaimed: (map['is_claimed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}