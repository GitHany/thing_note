class WeatherLog {
  final int? id;
  final DateTime recordedAt;
  final double? temperature;
  final double? humidity;
  final String? weatherCondition;
  final int? aqi;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? note;
  final DateTime createdAt;

  WeatherLog({
    this.id,
    required this.recordedAt,
    this.temperature,
    this.humidity,
    this.weatherCondition,
    this.aqi,
    this.locationName,
    this.latitude,
    this.longitude,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const weatherConditions = {
    'sunny': {'name': '晴天', 'icon': '☀️'},
    'cloudy': {'name': '多云', 'icon': '⛅'},
    'overcast': {'name': '阴天', 'icon': '☁️'},
    'rainy': {'name': '雨天', 'icon': '🌧️'},
    'stormy': {'name': '暴风雨', 'icon': '⛈️'},
    'snowy': {'name': '雪天', 'icon': '❄️'},
    'foggy': {'name': '雾天', 'icon': '🌫️'},
    'windy': {'name': '大风', 'icon': '💨'},
  };

  String get conditionIcon {
    return weatherConditions[weatherCondition]?['icon'] ?? '🌤️';
  }

  String get conditionName {
    return weatherConditions[weatherCondition]?['name'] ?? '未知';
  }

  String get aqiDescription {
    if (aqi == null) return '未知';
    if (aqi! <= 50) return '优';
    if (aqi! <= 100) return '良';
    if (aqi! <= 150) return '轻度污染';
    if (aqi! <= 200) return '中度污染';
    return '重度污染';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recorded_at': recordedAt.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'weather_condition': weatherCondition,
      'aqi': aqi,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeatherLog.fromMap(Map<String, dynamic> map) {
    return WeatherLog(
      id: map['id'] as int?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      temperature: (map['temperature'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      weatherCondition: map['weather_condition'] as String?,
      aqi: map['aqi'] as int?,
      locationName: map['location_name'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
