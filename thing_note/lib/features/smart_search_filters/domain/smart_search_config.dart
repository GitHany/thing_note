// Smart Search Filter Config Model

class SmartSearchConfig {
  final int? id;
  final String configKey;
  final String configValue;
  final DateTime updatedAt;

  const SmartSearchConfig({
    this.id,
    required this.configKey,
    required this.configValue,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'config_key': configKey,
      'config_value': configValue,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SmartSearchConfig.fromMap(Map<String, dynamic> map) {
    return SmartSearchConfig(
      id: map['id'] as int?,
      configKey: map['config_key'] as String,
      configValue: map['config_value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SmartSearchConfig copyWith({
    int? id,
    String? configKey,
    String? configValue,
    DateTime? updatedAt,
  }) {
    return SmartSearchConfig(
      id: id ?? this.id,
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final List<SmartSearchConfig> defaultConfigs = [
    SmartSearchConfig(configKey: 'fuzzy_match', configValue: 'true', updatedAt: DateTime(2024, 1, 1)),
    SmartSearchConfig(configKey: 'auto_correct', configValue: 'true', updatedAt: DateTime(2024, 1, 1)),
    SmartSearchConfig(configKey: 'suggestions_enabled', configValue: 'true', updatedAt: DateTime(2024, 1, 1)),
  ];
}