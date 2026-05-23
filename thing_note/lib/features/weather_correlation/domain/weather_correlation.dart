/// 天气状况枚举
enum WeatherCondition {
  sunny('晴天'),
  cloudy('多云'),
  overcast('阴天'),
  rainy('雨天'),
  thunderstorm('雷暴'),
  snowy('雪天'),
  foggy('雾天'),
  windy('大风'),
  hazy('雾霾'),
  unknown('未知');

  final String label;
  const WeatherCondition(this.label);

  static WeatherCondition fromString(String? value) {
    if (value == null) return WeatherCondition.unknown;
    return WeatherCondition.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => WeatherCondition.unknown,
    );
  }
}

/// 天气关联记录模型
class WeatherCorrelation {
  final int? id;
  final String date;
  final double? temperature;
  final double? humidity;
  final String? weatherCondition;
  final double? pressure;
  final double productivityScore;
  final int moodScore;
  final int energyLevel;
  final String? note;
  final String createdAt;

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
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'temperature': temperature,
      'humidity': humidity,
      'weather_condition': weatherCondition,
      'pressure': pressure,
      'productivity_score': productivityScore,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory WeatherCorrelation.fromMap(Map<String, dynamic> map) {
    return WeatherCorrelation(
      id: map['id'] as int?,
      date: map['date'] as String,
      temperature: map['temperature'] as double?,
      humidity: map['humidity'] as double?,
      weatherCondition: map['weather_condition'] as String?,
      pressure: map['pressure'] as double?,
      productivityScore: (map['productivity_score'] as num?)?.toDouble() ?? 0,
      moodScore: map['mood_score'] as int? ?? 0,
      energyLevel: map['energy_level'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  WeatherCorrelation copyWith({
    int? id,
    String? date,
    double? temperature,
    double? humidity,
    String? weatherCondition,
    double? pressure,
    double? productivityScore,
    int? moodScore,
    int? energyLevel,
    String? note,
    String? createdAt,
  }) {
    return WeatherCorrelation(
      id: id ?? this.id,
      date: date ?? this.date,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      pressure: pressure ?? this.pressure,
      productivityScore: productivityScore ?? this.productivityScore,
      moodScore: moodScore ?? this.moodScore,
      energyLevel: energyLevel ?? this.energyLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取天气状况枚举
  WeatherCondition get condition => WeatherCondition.fromString(weatherCondition);

  /// 获取温度范围标签
  static String getTemperatureRange(double? temp) {
    if (temp == null) return '未知';
    if (temp < 0) return '极寒 (<0°C)';
    if (temp < 10) return '寒冷 (0-10°C)';
    if (temp < 20) return '凉爽 (10-20°C)';
    if (temp < 25) return '舒适 (20-25°C)';
    if (temp < 30) return '温暖 (25-30°C)';
    return '炎热 (>30°C)';
  }

  String get temperatureRange => getTemperatureRange(temperature);
}

/// 按天气分组的统计数据
class WeatherStats {
  final String weatherCondition;
  final int count;
  final double avgProductivity;
  final double avgMood;
  final double avgEnergy;
  final double avgTemperature;

  WeatherStats({
    required this.weatherCondition,
    required this.count,
    required this.avgProductivity,
    required this.avgMood,
    required this.avgEnergy,
    required this.avgTemperature,
  });
}

/// 按温度范围分组的统计数据
class TemperatureRangeStats {
  final String rangeLabel;
  final int count;
  final double avgProductivity;
  final double avgMood;
  final double avgEnergy;

  TemperatureRangeStats({
    required this.rangeLabel,
    required this.count,
    required this.avgProductivity,
    required this.avgMood,
    required this.avgEnergy,
  });
}

/// 个性化建议
class WeatherSuggestion {
  final String condition;
  final String suggestion;
  final String reason;

  WeatherSuggestion({
    required this.condition,
    required this.suggestion,
    required this.reason,
  });

  static List<WeatherSuggestion> generateSuggestions(
    WeatherCondition condition,
    double? temperature,
    double avgProductivity,
    double avgMood,
  ) {
    final suggestions = <WeatherSuggestion>[];
    final tempRange = WeatherCorrelation.getTemperatureRange(temperature);

    // 基于天气状况的建议
    switch (condition) {
      case WeatherCondition.sunny:
        suggestions.add(WeatherSuggestion(
          condition: '晴天',
          suggestion: '适合户外工作或散步',
          reason: '阳光充足，有助于提升心情和能量',
        ));
        if (avgProductivity > 7) {
          suggestions.add(WeatherSuggestion(
            condition: '晴天',
            suggestion: '利用好天气完成需要创造力的任务',
            reason: '你的晴天生产力通常较高',
          ));
        }
        break;
      case WeatherCondition.rainy:
        suggestions.add(WeatherSuggestion(
          condition: '雨天',
          suggestion: '适合室内专注工作',
          reason: '雨声有助于集中注意力',
        ));
        if (avgMood < 5) {
          suggestions.add(WeatherSuggestion(
            condition: '雨天',
            suggestion: '听一些轻快的音乐或喝杯热饮',
            reason: '雨天可能影响情绪，适当调节',
          ));
        }
        break;
      case WeatherCondition.overcast:
        suggestions.add(WeatherSuggestion(
          condition: '阴天',
          suggestion: '可以进行整理和规划工作',
          reason: '光线柔和，适合需要冷静思考的任务',
        ));
        break;
      case WeatherCondition.thunderstorm:
        suggestions.add(WeatherSuggestion(
          condition: '雷暴',
          suggestion: '减少外出，专注室内任务',
          reason: '天气不稳定，保持安全第一',
        ));
        break;
      case WeatherCondition.snowy:
        suggestions.add(WeatherSuggestion(
          condition: '雪天',
          suggestion: '适合创意写作或学习',
          reason: '安静的环境有利于深度思考',
        ));
        break;
      case WeatherCondition.foggy:
        suggestions.add(WeatherSuggestion(
          condition: '雾天',
          suggestion: '注意出行安全，减少户外活动',
          reason: '能见度低，安全优先',
        ));
        break;
      case WeatherCondition.windy:
        suggestions.add(WeatherSuggestion(
          condition: '大风',
          suggestion: '适合室内有氧运动',
          reason: '户外运动风险较高',
        ));
        break;
      case WeatherCondition.hazy:
        suggestions.add(WeatherSuggestion(
          condition: '雾霾',
          suggestion: '避免户外运动，使用空气净化器',
          reason: '空气质量差，注意健康防护',
        ));
        break;
      default:
        suggestions.add(WeatherSuggestion(
          condition: '未知',
          suggestion: '记录今天的状态',
          reason: '帮助完善天气数据',
        ));
    }

    // 基于温度范围的建议
    if (tempRange.contains('寒冷') || tempRange.contains('极寒')) {
      suggestions.add(WeatherSuggestion(
        condition: '温度',
        suggestion: '注意保暖，适当运动提升体温',
        reason: '低温环境容易感到疲倦',
      ));
    } else if (tempRange.contains('炎热')) {
      suggestions.add(WeatherSuggestion(
        condition: '温度',
        suggestion: '多喝水，避免高温时段户外活动',
        reason: '高温可能影响注意力和判断力',
      ));
    } else if (tempRange.contains('舒适')) {
      suggestions.add(WeatherSuggestion(
        condition: '温度',
        suggestion: '这是最佳工作温度，抓紧完成任务',
        reason: '舒适温度下生产力通常最高',
      ));
    }

    return suggestions;
  }
}