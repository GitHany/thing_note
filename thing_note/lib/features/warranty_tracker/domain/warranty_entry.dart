class WarrantyEntry {
  final int? id;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? purchaseDate;
  final String? expiryDate;
  final double? purchasePrice;
  final String? store;
  final String? receiptPath;
  final String? note;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  WarrantyEntry({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.expiryDate,
    this.purchasePrice,
    this.store,
    this.receiptPath,
    this.note,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate,
      'expiry_date': expiryDate,
      'purchase_price': purchasePrice,
      'store': store,
      'receipt_path': receiptPath,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory WarrantyEntry.fromMap(Map<String, dynamic> map) {
    return WarrantyEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      purchaseDate: map['purchase_date'] as String?,
      expiryDate: map['expiry_date'] as String?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),
      store: map['store'] as String?,
      receiptPath: map['receipt_path'] as String?,
      note: map['note'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  WarrantyEntry copyWith({
    int? id, String? name, String? brand, String? model, String? serialNumber,
    String? purchaseDate, String? expiryDate, double? purchasePrice, String? store,
    String? receiptPath, String? note, bool? isActive, String? createdAt, String? updatedAt,
  }) {
    return WarrantyEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      store: store ?? this.store,
      receiptPath: receiptPath ?? this.receiptPath,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.parse(expiryDate!).isBefore(DateTime.now());
  }

  int? get daysRemaining {
    if (expiryDate == null) return null;
    final expiry = DateTime.parse(expiryDate!);
    return expiry.difference(DateTime.now()).inDays;
  }

  static const List<String> categories = [
    '电子产品', '家电', '家具', '服装', '珠宝', '汽车', '其他',
  ];
}