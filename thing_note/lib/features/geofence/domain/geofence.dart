class Geofence {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String triggerType; // 'enter' | 'exit' | 'dwell'
  final bool isEnabled;
  final String actionType; // 'reminder' | 'notification' | 'record'
  final String? actionData;
  final DateTime createdAt;

  Geofence({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    this.triggerType = 'enter',
    this.isEnabled = true,
    this.actionType = 'reminder',
    this.actionData,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'trigger_type': triggerType,
      'is_enabled': isEnabled ? 1 : 0,
      'action_type': actionType,
      'action_data': actionData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'] as int?,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      radiusMeters: map['radius_meters'] as double? ?? 100,
      triggerType: map['trigger_type'] as String? ?? 'enter',
      isEnabled: (map['is_enabled'] as int?) == 1,
      actionType: map['action_type'] as String? ?? 'reminder',
      actionData: map['action_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Geofence copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? triggerType,
    bool? isEnabled,
    String? actionType,
    String? actionData,
    DateTime? createdAt,
  }) {
    return Geofence(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      triggerType: triggerType ?? this.triggerType,
      isEnabled: isEnabled ?? this.isEnabled,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double distanceTo(double lat, double lng) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);
    final double a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(latitude)) * Math.cos(_toRadians(lat)) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  bool isInside(double lat, double lng) {
    return distanceTo(lat, lng) <= radiusMeters;
  }

  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }
}

class Math {
  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static double sqrt(double x) => _sqrt(x);
  static double atan2(double y, double x) => _atan2(y, x);

  static double _sin(double x) {
    // Taylor series approximation
    double result = x;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) {
    // Taylor series approximation
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      result += term;
    }
    return result;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  static double _atan(double x) {
    // Taylor series for atan
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.141592653589793 / 2 - _atan(1 / x);
    }
    double result = x;
    double term = x;
    for (int n = 1; n <= 20; n++) {
      term *= -x * x;
      result += term / (2 * n + 1);
    }
    return result;
  }
}