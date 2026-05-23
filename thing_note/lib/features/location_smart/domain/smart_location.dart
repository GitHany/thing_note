/// Smart location entry with visit patterns
class SmartLocation {
  final int? id;
  final String name;
  final String? alias;
  final double latitude;
  final double longitude;
  final String? address;
  final String icon;
  final String color;
  final String? category;
  final int visitCount;
  final int totalDurationSec;
  final DateTime? lastVisitedAt;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;

  SmartLocation({
    this.id,
    required this.name,
    this.alias,
    required this.latitude,
    required this.longitude,
    this.address,
    this.icon = '📍',
    this.color = '#607D8B',
    this.category,
    this.visitCount = 0,
    this.totalDurationSec = 0,
    this.lastVisitedAt,
    this.isFavorite = false,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'alias': alias,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'icon': icon,
      'color': color,
      'category': category,
      'visit_count': visitCount,
      'total_duration_sec': totalDurationSec,
      'last_visited_at': lastVisitedAt?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartLocation.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return SmartLocation(
      id: map['id'] as int?,
      name: map['name'] as String,
      alias: map['alias'] as String?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      address: map['address'] as String?,
      icon: map['icon'] as String? ?? '📍',
      color: map['color'] as String? ?? '#607D8B',
      category: map['category'] as String?,
      visitCount: map['visit_count'] as int? ?? 0,
      totalDurationSec: map['total_duration_sec'] as int? ?? 0,
      lastVisitedAt: map['last_visited_at'] != null ? DateTime.parse(map['last_visited_at'] as String) : null,
      isFavorite: (map['is_favorite'] as int?) == 1,
      tags: tagsStr != null && tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SmartLocation copyWith({
    int? id,
    String? name,
    String? alias,
    double? latitude,
    double? longitude,
    String? address,
    String? icon,
    String? color,
    String? category,
    int? visitCount,
    int? totalDurationSec,
    DateTime? lastVisitedAt,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return SmartLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      visitCount: visitCount ?? this.visitCount,
      totalDurationSec: totalDurationSec ?? this.totalDurationSec,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate average visit duration
  double get averageVisitMinutes => visitCount > 0 ? (totalDurationSec / visitCount / 60) : 0;
}

/// Location check-in entry
class LocationCheckIn {
  final int? id;
  final int locationId;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final String? note;
  final String? photoPath;

  LocationCheckIn({
    this.id,
    required this.locationId,
    required this.checkInAt,
    this.checkOutAt,
    this.note,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'location_id': locationId,
      'check_in_at': checkInAt.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'note': note,
      'photo_path': photoPath,
    };
  }

  factory LocationCheckIn.fromMap(Map<String, dynamic> map) {
    return LocationCheckIn(
      id: map['id'] as int?,
      locationId: map['location_id'] as int,
      checkInAt: DateTime.parse(map['check_in_at'] as String),
      checkOutAt: map['check_out_at'] != null ? DateTime.parse(map['check_out_at'] as String) : null,
      note: map['note'] as String?,
      photoPath: map['photo_path'] as String?,
    );
  }

  int get durationSec => checkOutAt != null ? checkOutAt!.difference(checkInAt).inSeconds : 0;
}