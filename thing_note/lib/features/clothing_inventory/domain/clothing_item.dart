class ClothingItem {
  final int? id;
  final String name;
  final String category;
  final String? color;
  final String? brand;
  final String? size;
  final int? purchaseYear;
  final double? price;
  final String? season;
  final String? note;
  final bool isFavorite;
  final int wearCount;
  final String createdAt;

  ClothingItem({
    this.id,
    required this.name,
    required this.category,
    this.color,
    this.brand,
    this.size,
    this.purchaseYear,
    this.price,
    this.season,
    this.note,
    this.isFavorite = false,
    this.wearCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'brand': brand,
      'size': size,
      'purchase_year': purchaseYear,
      'price': price,
      'season': season,
      'note': note,
      'is_favorite': isFavorite ? 1 : 0,
      'wear_count': wearCount,
      'created_at': createdAt,
    };
  }

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      color: map['color'] as String?,
      brand: map['brand'] as String?,
      size: map['size'] as String?,
      purchaseYear: map['purchase_year'] as int?,
      price: (map['price'] as num?)?.toDouble(),
      season: map['season'] as String?,
      note: map['note'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      wearCount: map['wear_count'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  ClothingItem copyWith({
    int? id, String? name, String? category, String? color, String? brand, String? size,
    int? purchaseYear, double? price, String? season, String? note, bool? isFavorite, int? wearCount, String? createdAt,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      purchaseYear: purchaseYear ?? this.purchaseYear,
      price: price ?? this.price,
      season: season ?? this.season,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      wearCount: wearCount ?? this.wearCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> categories = ['上装', '下装', '外套', '鞋子', '配饰', '内衣', '其他'];
  static const List<String> seasons = ['春季', '夏季', '秋季', '冬季', '四季通用'];
}