class LocationStoryline {
  final int? id;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final int visitCount;
  final String? firstVisitDate;
  final String? lastVisitDate;
  final String? coverPhotoPath;
  final String? storySummary;
  final String? highlights;
  final DateTime createdAt;

  LocationStoryline({
    this.id,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.visitCount = 0,
    this.firstVisitDate,
    this.lastVisitDate,
    this.coverPhotoPath,
    this.storySummary,
    this.highlights,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'visit_count': visitCount,
      'first_visit_date': firstVisitDate,
      'last_visit_date': lastVisitDate,
      'cover_photo_path': coverPhotoPath,
      'story_summary': storySummary,
      'highlights': highlights,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationStoryline.fromMap(Map<String, dynamic> map) {
    return LocationStoryline(
      id: map['id'],
      locationName: map['location_name'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      visitCount: map['visit_count'] ?? 0,
      firstVisitDate: map['first_visit_date'],
      lastVisitDate: map['last_visit_date'],
      coverPhotoPath: map['cover_photo_path'],
      storySummary: map['story_summary'],
      highlights: map['highlights'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  LocationStoryline copyWith({
    int? id,
    String? locationName,
    double? latitude,
    double? longitude,
    int? visitCount,
    String? firstVisitDate,
    String? lastVisitDate,
    String? coverPhotoPath,
    String? storySummary,
    String? highlights,
    DateTime? createdAt,
  }) {
    return LocationStoryline(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visitCount: visitCount ?? this.visitCount,
      firstVisitDate: firstVisitDate ?? this.firstVisitDate,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      storySummary: storySummary ?? this.storySummary,
      highlights: highlights ?? this.highlights,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}