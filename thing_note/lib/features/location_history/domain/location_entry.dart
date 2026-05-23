class LocationEntry {
  final int? id;
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final DateTime recordedAt;
  final DateTime createdAt;

  LocationEntry({
    this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    required this.recordedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'place_name': placeName,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationEntry.fromMap(Map<String, dynamic> map) {
    return LocationEntry(
      id: map['id'] as int?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      address: map['address'] as String?,
      placeName: map['place_name'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}