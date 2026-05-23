/// 药物提醒数据模型
class Medication {
  final int? id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final String? sideEffects;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.sideEffects,
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    String? sideEffects,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
      sideEffects: sideEffects ?? this.sideEffects,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'side_effects': sideEffects,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String?,
      instructions: map['instructions'] as String?,
      sideEffects: map['side_effects'] as String?,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 服药记录
class MedicationLog {
  final int? id;
  final int medicationId;
  final DateTime takenAt;
  final String? note;
  final DateTime createdAt;

  const MedicationLog({
    this.id,
    required this.medicationId,
    required this.takenAt,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medication_id': medicationId,
      'taken_at': takenAt.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      takenAt: DateTime.parse(map['taken_at'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}