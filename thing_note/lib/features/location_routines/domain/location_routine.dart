class LocationRoutine {
  final int? id;
  final String locationName;
  final String? locationType;
  final String routines;
  final int isAutoDetect;
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final DateTime createdAt;

  LocationRoutine({
    this.id,
    required this.locationName,
    this.locationType,
    this.routines = '',
    this.isAutoDetect = 0,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'location_name': locationName,
      'location_type': locationType,
      'routines': routines,
      'is_auto_detect': isAutoDetect,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationRoutine.fromMap(Map<String, dynamic> map) {
    return LocationRoutine(
      id: map['id'] as int?,
      locationName: map['location_name'] as String,
      locationType: map['location_type'] as String?,
      routines: map['routines'] as String? ?? '',
      isAutoDetect: map['is_auto_detect'] as int? ?? 0,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 100,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<String> get routineList =>
      routines.split(',').where((s) => s.trim().isNotEmpty).toList();

  LocationRoutine copyWith({
    int? id,
    String? locationName,
    String? locationType,
    String? routines,
    int? isAutoDetect,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    DateTime? createdAt,
  }) {
    return LocationRoutine(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      locationType: locationType ?? this.locationType,
      routines: routines ?? this.routines,
      isAutoDetect: isAutoDetect ?? this.isAutoDetect,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> locationTypes = [
    'home',
    'office',
    'cafe',
    'gym',
    'outdoor',
    'traveling',
    'other',
  ];

  static const Map<String, String> typeLabels = {
    'home': '家',
    'office': '办公室',
    'cafe': '咖啡馆',
    'gym': '健身房',
    'outdoor': '户外',
    'traveling': '旅途中',
    'other': '其他',
  };

  static const Map<String, String> typeIcons = {
    'home': '🏠',
    'office': '🏢',
    'cafe': '☕',
    'gym': '💪',
    'outdoor': '🌳',
    'traveling': '✈️',
    'other': '📍',
  };
}