/// 维修记录数据模型
class MaintenanceItem {
  final int? id;
  final String name;
  final String? category;
  final String? brand;
  final String? model;
  final DateTime? purchaseDate;
  final DateTime? warrantyEndDate;
  final String? imagePath;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceItem({
    this.id,
    required this.name,
    this.category,
    this.brand,
    this.model,
    this.purchaseDate,
    this.warrantyEndDate,
    this.imagePath,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  MaintenanceItem copyWith({
    int? id,
    String? name,
    String? category,
    String? brand,
    String? model,
    DateTime? purchaseDate,
    DateTime? warrantyEndDate,
    String? imagePath,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUnderWarranty {
    if (warrantyEndDate == null) return false;
    return warrantyEndDate!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'purchase_date': purchaseDate?.toIso8601String(),
      'warranty_end_date': warrantyEndDate?.toIso8601String(),
      'image_path': imagePath,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceItem.fromMap(Map<String, dynamic> map) {
    return MaintenanceItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date'] as String) : null,
      warrantyEndDate: map['warranty_end_date'] != null ? DateTime.parse(map['warranty_end_date'] as String) : null,
      imagePath: map['image_path'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 维修记录
class MaintenanceLog {
  final int? id;
  final int itemId;
  final String title;
  final String? description;
  final double? cost;
  final String? currency;
  final DateTime? serviceDate;
  final String? serviceProvider;
  final String? contact;
  final DateTime createdAt;

  const MaintenanceLog({
    this.id,
    required this.itemId,
    required this.title,
    this.description,
    this.cost,
    this.currency = 'CNY',
    this.serviceDate,
    this.serviceProvider,
    this.contact,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'title': title,
      'description': description,
      'cost': cost,
      'currency': currency,
      'service_date': serviceDate?.toIso8601String(),
      'service_provider': serviceProvider,
      'contact': contact,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MaintenanceLog.fromMap(Map<String, dynamic> map) {
    return MaintenanceLog(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      currency: map['currency'] as String? ?? 'CNY',
      serviceDate: map['service_date'] != null ? DateTime.parse(map['service_date'] as String) : null,
      serviceProvider: map['service_provider'] as String?,
      contact: map['contact'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}