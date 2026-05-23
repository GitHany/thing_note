// Privacy Dashboard Models
// 隐私安全仪表板功能 - 监控和管理你的隐私数据

class PrivacyMetric {
  final int? id;
  final String metricType; // 'data_exposure', 'sharing_level', 'location_tracking'
  final String name;
  final double value; // 0-100
  final String status; // 'safe', 'warning', 'danger'
  final List<String> recommendations;
  final DateTime calculatedAt;

  PrivacyMetric({
    this.id,
    required this.metricType,
    required this.name,
    required this.value,
    required this.status,
    required this.recommendations,
    required this.calculatedAt,
  });

  String get statusEmoji {
    switch (status) {
      case 'safe':
        return '🟢';
      case 'warning':
        return '🟡';
      case 'danger':
        return '🔴';
      default:
        return '⚪';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric_type': metricType,
      'name': name,
      'value': value,
      'status': status,
      'recommendations': recommendations.join('|||'),
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory PrivacyMetric.fromMap(Map<String, dynamic> map) {
    final recsStr = map['recommendations'] as String? ?? '';
    return PrivacyMetric(
      id: map['id'] as int?,
      metricType: map['metric_type'] as String,
      name: map['name'] as String,
      value: (map['value'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'safe',
      recommendations: recsStr.isEmpty ? [] : recsStr.split('|||'),
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
    );
  }
}

class DataExposureItem {
  final int? id;
  final String dataType; // 'location', 'photo', 'audio', 'note'
  final String description;
  final String exposureLevel; // 'public', 'shared', 'private'
  final String? sharedWith;
  final bool isIntentional;
  final DateTime lastAccess;

  DataExposureItem({
    this.id,
    required this.dataType,
    required this.description,
    required this.exposureLevel,
    this.sharedWith,
    this.isIntentional = true,
    required this.lastAccess,
  });

  String get dataTypeEmoji {
    switch (dataType) {
      case 'location':
        return '📍';
      case 'photo':
        return '📷';
      case 'audio':
        return '🎤';
      case 'note':
        return '📝';
      default:
        return '📄';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_type': dataType,
      'description': description,
      'exposure_level': exposureLevel,
      'shared_with': sharedWith,
      'is_intentional': isIntentional ? 1 : 0,
      'last_access': lastAccess.toIso8601String(),
    };
  }

  factory DataExposureItem.fromMap(Map<String, dynamic> map) {
    return DataExposureItem(
      id: map['id'] as int?,
      dataType: map['data_type'] as String,
      description: map['description'] as String,
      exposureLevel: map['exposure_level'] as String? ?? 'private',
      sharedWith: map['shared_with'] as String?,
      isIntentional: (map['is_intentional'] as int?) == 1,
      lastAccess: DateTime.parse(map['last_access'] as String),
    );
  }
}

class PrivacyReport {
  final int? id;
  final String period; // 'weekly', 'monthly'
  final int totalRecords;
  final int exposedRecords;
  final double exposureRate;
  final List<PrivacyMetric> metrics;
  final String? overallScore;
  final DateTime generatedAt;

  PrivacyReport({
    this.id,
    required this.period,
    required this.totalRecords,
    required this.exposedRecords,
    required this.exposureRate,
    required this.metrics,
    this.overallScore,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'total_records': totalRecords,
      'exposed_records': exposedRecords,
      'exposure_rate': exposureRate,
      'overall_score': overallScore,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory PrivacyReport.fromMap(Map<String, dynamic> map) {
    return PrivacyReport(
      id: map['id'] as int?,
      period: map['period'] as String,
      totalRecords: map['total_records'] as int? ?? 0,
      exposedRecords: map['exposed_records'] as int? ?? 0,
      exposureRate: (map['exposure_rate'] as num?)?.toDouble() ?? 0,
      metrics: [],
      overallScore: map['overall_score'] as String?,
      generatedAt: DateTime.parse(map['generated_at'] as String),
    );
  }
}