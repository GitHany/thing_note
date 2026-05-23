class InvestmentEntry {
  final int? id;
  final String name;
  final String type;
  final double amount;
  final double? currentValue;
  final String? purchaseDate;
  final String? ticker;
  final String? note;
  final String createdAt;
  final String? updatedAt;

  InvestmentEntry({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.currentValue,
    this.purchaseDate,
    this.ticker,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'current_value': currentValue,
      'purchase_date': purchaseDate,
      'ticker': ticker,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InvestmentEntry.fromMap(Map<String, dynamic> map) {
    return InvestmentEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currentValue: (map['current_value'] as num?)?.toDouble(),
      purchaseDate: map['purchase_date'] as String?,
      ticker: map['ticker'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  InvestmentEntry copyWith({
    int? id, String? name, String? type, double? amount, double? currentValue,
    String? purchaseDate, String? ticker, String? note, String? createdAt, String? updatedAt,
  }) {
    return InvestmentEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      ticker: ticker ?? this.ticker,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get returnRate {
    if (currentValue == null || amount == 0) return 0;
    return ((currentValue! - amount) / amount) * 100;
  }

  static const List<String> types = [
    '股票', '基金', '债券', '房产', '黄金', '数字货币', '定期存款', '理财', '其他',
  ];
}

class InvestmentTransaction {
  final int? id;
  final int investmentId;
  final String type;
  final double amount;
  final String date;
  final double? price;
  final int? quantity;
  final String? note;
  final String createdAt;

  InvestmentTransaction({
    this.id,
    required this.investmentId,
    required this.type,
    required this.amount,
    required this.date,
    this.price,
    this.quantity,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investment_id': investmentId,
      'type': type,
      'amount': amount,
      'date': date,
      'price': price,
      'quantity': quantity,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory InvestmentTransaction.fromMap(Map<String, dynamic> map) {
    return InvestmentTransaction(
      id: map['id'] as int?,
      investmentId: map['investment_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      price: (map['price'] as num?)?.toDouble(),
      quantity: map['quantity'] as int?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}