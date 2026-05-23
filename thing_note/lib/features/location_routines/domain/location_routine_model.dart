/// Location Routine model
class LocationRoutine {
  final int? id;
  final String name;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final String triggerType;
  final String actionType;
  final String? actionConfig;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  static const triggerTypes = {
    'enter': '进入位置时',
    'exit': '离开位置时',
    'dwell': '停留超过设定时间',
  };

  static const actionTypes = {
    'start_timer': '开始计时',
    'stop_timer': '停止计时',
    'create_record': '创建记录',
    'send_notification': '发送通知',
    'show_reminder': '显示提醒',
  };

  LocationRoutine({
    this.id,
    required this.name,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100,
    this.triggerType = 'enter',
    required this.actionType,
    this.actionConfig,
    this.isEnabled = true,
    this.lastTriggered,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get triggerLabel => triggerTypes[triggerType] ?? triggerType;
  String get actionLabel => actionTypes[actionType] ?? actionType;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'trigger_type': triggerType,
      'action_type': actionType,
      'action_config': actionConfig,
      'is_enabled': isEnabled ? 1 : 0,
      'last_triggered': lastTriggered?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationRoutine.fromMap(Map<String, dynamic> map) {
    return LocationRoutine(
      id: map['id'] as int?,
      name: map['name'] as String,
      locationName: map['location_name'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 100,
      triggerType: map['trigger_type'] as String? ?? 'enter',
      actionType: map['action_type'] as String,
      actionConfig: map['action_config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LocationRoutine copyWith({
    int? id,
    String? name,
    String? locationName,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? triggerType,
    String? actionType,
    String? actionConfig,
    bool? isEnabled,
    DateTime? lastTriggered,
    DateTime? createdAt,
  }) {
    return LocationRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      triggerType: triggerType ?? this.triggerType,
      actionType: actionType ?? this.actionType,
      actionConfig: actionConfig ?? this.actionConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}