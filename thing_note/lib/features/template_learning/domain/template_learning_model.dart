class TemplateLearningModel {
  final int? id;
  final String modelType;
  final String modelData;
  final double accuracyScore;
  final int sampleCount;
  final String lastUpdated;
  final DateTime createdAt;

  TemplateLearningModel({
    this.id,
    required this.modelType,
    required this.modelData,
    this.accuracyScore = 0,
    this.sampleCount = 0,
    required this.lastUpdated,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_type': modelType,
      'model_data': modelData,
      'accuracy_score': accuracyScore,
      'sample_count': sampleCount,
      'last_updated': lastUpdated,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TemplateLearningModel.fromMap(Map<String, dynamic> map) {
    return TemplateLearningModel(
      id: map['id'],
      modelType: map['model_type'],
      modelData: map['model_data'],
      accuracyScore: (map['accuracy_score'] ?? 0).toDouble(),
      sampleCount: map['sample_count'] ?? 0,
      lastUpdated: map['last_updated'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  TemplateLearningModel copyWith({
    int? id,
    String? modelType,
    String? modelData,
    double? accuracyScore,
    int? sampleCount,
    String? lastUpdated,
    DateTime? createdAt,
  }) {
    return TemplateLearningModel(
      id: id ?? this.id,
      modelType: modelType ?? this.modelType,
      modelData: modelData ?? this.modelData,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      sampleCount: sampleCount ?? this.sampleCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ModelType {
  thingName('事情名称'),
  tags('标签组合'),
  timePreference('时间偏好'),
  noteLength('备注长度'),
  mediaUsage('媒体使用');

  final String label;
  const ModelType(this.label);
}