class WeatherCorrelation {
  final int? id;
  final DateTime date;
  final double? temperature;
  final double? humidity;
  final String? weatherCondition;
  final double? pressure;
  final double productivityScore;
  final int moodScore;
  final int energyLevel;
  final String? note;
  final DateTime createdAt;

  WeatherCorrelation({
    this.id,
    required this.date,
    this.temperature,
    this.humidity,
    this.weatherCondition,
    this.pressure,
    this.productivityScore = 0,
    this.moodScore = 0,
    this.energyLevel = 0,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().split('T')[0],
      'temperature': temperature,
      'humidity': humidity,
      'weather_condition': weatherCondition,
      'pressure': pressure,
      'productivity_score': productivityScore,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeatherCorrelation.fromMap(Map<String, dynamic> map) {
    return WeatherCorrelation(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      temperature: map['temperature'] as double?,
      humidity: map['humidity'] as double?,
      weatherCondition: map['weather_condition'] as String?,
      pressure: map['pressure'] as double?,
      productivityScore: (map['productivity_score'] as num?)?.toDouble() ?? 0,
      moodScore: map['mood_score'] as int? ?? 0,
      energyLevel: map['energy_level'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class WeatherInsight {
  final String condition;
  final double avgProductivity;
  final int sampleCount;
  final String recommendation;

  WeatherInsight({
    required this.condition,
    required this.avgProductivity,
    required this.sampleCount,
    required this.recommendation,
  });
}