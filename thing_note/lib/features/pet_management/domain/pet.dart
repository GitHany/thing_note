/// 宠物管理数据模型
class Pet {
  final int? id;
  final String name;
  final PetType type;
  final String? breed;
  final DateTime? birthDate;
  final String? imagePath;
  final String? notes;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pet({
    this.id,
    required this.name,
    required this.type,
    this.breed,
    this.birthDate,
    this.imagePath,
    this.notes,
    this.color = '#607D8B',
    required this.createdAt,
    required this.updatedAt,
  });

  Pet copyWith({
    int? id,
    String? name,
    PetType? type,
    String? breed,
    DateTime? birthDate,
    String? imagePath,
    String? notes,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get ageInYears {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'breed': breed,
      'birth_date': birthDate?.toIso8601String(),
      'image_path': imagePath,
      'notes': notes,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: PetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PetType.other,
      ),
      breed: map['breed'] as String?,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
      color: map['color'] as String? ?? '#607D8B',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum PetType { dog, cat, bird, fish, rabbit, hamster, turtle, other }

extension PetTypeExtension on PetType {
  String get displayName {
    switch (this) {
      case PetType.dog: return '狗';
      case PetType.cat: return '猫';
      case PetType.bird: return '鸟';
      case PetType.fish: return '鱼';
      case PetType.rabbit: return '兔子';
      case PetType.hamster: return '仓鼠';
      case PetType.turtle: return '乌龟';
      case PetType.other: return '其他';
    }
  }

  String get icon {
    switch (this) {
      case PetType.dog: return '🐕';
      case PetType.cat: return '🐱';
      case PetType.bird: return '🐦';
      case PetType.fish: return '🐟';
      case PetType.rabbit: return '🐰';
      case PetType.hamster: return '🐹';
      case PetType.turtle: return '🐢';
      case PetType.other: return '🐾';
    }
  }
}