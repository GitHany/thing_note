class LocationCheckin {
  final int? id;
  final String placeName;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime checkInAt;
  final String? note;
  final String? photoPath;
  final DateTime createdAt;

  LocationCheckin({
    this.id,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.checkInAt,
    this.note,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'check_in_at': checkInAt.toIso8601String(),
      'note': note,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationCheckin.fromMap(Map<String, dynamic> map) {
    return LocationCheckin(
      id: map['id'] as int?,
      placeName: map['place_name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      checkInAt: DateTime.parse(map['check_in_at'] as String),
      note: map['note'] as String?,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}