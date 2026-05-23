/// 宠物护理记录数据模型
class PetCareLog {
  final int? id;
  final int petId;
  final CareType careType;
  final DateTime date;
  final String? note;
  final String? imagePath;
  final DateTime createdAt;

  const PetCareLog({
    this.id,
    required this.petId,
    required this.careType,
    required this.date,
    this.note,
    this.imagePath,
    required this.createdAt,
  });

  PetCareLog copyWith({
    int? id,
    int? petId,
    CareType? careType,
    DateTime? date,
    String? note,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return PetCareLog(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      careType: careType ?? this.careType,
      date: date ?? this.date,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'care_type': careType.name,
      'date': date.toIso8601String(),
      'note': note,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PetCareLog.fromMap(Map<String, dynamic> map) {
    return PetCareLog(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      careType: CareType.values.firstWhere(
        (e) => e.name == map['care_type'],
        orElse: () => CareType.other,
      ),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum CareType { feeding, walking, grooming, veterinary, medication, training, play, other }

extension CareTypeExtension on CareType {
  String get displayName {
    switch (this) {
      case CareType.feeding: return '喂食';
      case CareType.walking: return '遛狗';
      case CareType.grooming: return '美容';
      case CareType.veterinary: return '就医';
      case CareType.medication: return '用药';
      case CareType.training: return '训练';
      case CareType.play: return '玩耍';
      case CareType.other: return '其他';
    }
  }

  String get icon {
    switch (this) {
      case CareType.feeding: return '🍖';
      case CareType.walking: return '🚶';
      case CareType.grooming: return '✂️';
      case CareType.veterinary: return '🏥';
      case CareType.medication: return '💊';
      case CareType.training: return '🎓';
      case CareType.play: return '🎾';
      case CareType.other: return '📝';
    }
  }
}