/// 植物养护数据模型
class Plant {
  final int? id;
  final String name;
  final String? species;
  final String? imagePath;
  final String? location;
  final PlantStatus status;
  final String? careInstructions;
  final DateTime? lastWateredAt;
  final int? wateringFrequencyDays;
  final DateTime? lastFertilizedAt;
  final DateTime? lastPrunedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Plant({
    this.id,
    required this.name,
    this.species,
    this.imagePath,
    this.location,
    this.status = PlantStatus.healthy,
    this.careInstructions,
    this.lastWateredAt,
    this.wateringFrequencyDays,
    this.lastFertilizedAt,
    this.lastPrunedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Plant copyWith({
    int? id,
    String? name,
    String? species,
    String? imagePath,
    String? location,
    PlantStatus? status,
    String? careInstructions,
    DateTime? lastWateredAt,
    int? wateringFrequencyDays,
    DateTime? lastFertilizedAt,
    DateTime? lastPrunedAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imagePath: imagePath ?? this.imagePath,
      location: location ?? this.location,
      status: status ?? this.status,
      careInstructions: careInstructions ?? this.careInstructions,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      lastFertilizedAt: lastFertilizedAt ?? this.lastFertilizedAt,
      lastPrunedAt: lastPrunedAt ?? this.lastPrunedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get needsWater {
    if (lastWateredAt == null || wateringFrequencyDays == null) return false;
    final nextWatering = lastWateredAt!.add(Duration(days: wateringFrequencyDays!));
    return DateTime.now().isAfter(nextWatering);
  }

  int get daysSinceWatered {
    if (lastWateredAt == null) return -1;
    return DateTime.now().difference(lastWateredAt!).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'species': species,
      'image_path': imagePath,
      'location': location,
      'status': status.name,
      'care_instructions': careInstructions,
      'last_watered_at': lastWateredAt?.toIso8601String(),
      'watering_frequency_days': wateringFrequencyDays,
      'last_fertilized_at': lastFertilizedAt?.toIso8601String(),
      'last_pruned_at': lastPrunedAt?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int?,
      name: map['name'] as String,
      species: map['species'] as String?,
      imagePath: map['image_path'] as String?,
      location: map['location'] as String?,
      status: PlantStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PlantStatus.healthy,
      ),
      careInstructions: map['care_instructions'] as String?,
      lastWateredAt: map['last_watered_at'] != null ? DateTime.parse(map['last_watered_at'] as String) : null,
      wateringFrequencyDays: map['watering_frequency_days'] as int?,
      lastFertilizedAt: map['last_fertilized_at'] != null ? DateTime.parse(map['last_fertilized_at'] as String) : null,
      lastPrunedAt: map['last_pruned_at'] != null ? DateTime.parse(map['last_pruned_at'] as String) : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum PlantStatus { healthy, needsAttention, sick, dormant }

extension PlantStatusExtension on PlantStatus {
  String get displayName {
    switch (this) {
      case PlantStatus.healthy: return '健康';
      case PlantStatus.needsAttention: return '需要关注';
      case PlantStatus.sick: return '生病';
      case PlantStatus.dormant: return '休眠';
    }
  }
}