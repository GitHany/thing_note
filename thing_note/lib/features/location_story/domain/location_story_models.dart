/// 位置故事 - Location Story
/// 基于位置的记录故事展示
library;

/// 位置故事模型
class LocationStory {
  final int id;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? address;
  final List<StoryChapter> chapters;
  final DateTime firstVisit;
  final DateTime lastVisit;
  final int visitCount;
  final Duration totalDuration;
  final String? coverImagePath;

  LocationStory({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.chapters = const [],
    required this.firstVisit,
    required this.lastVisit,
    this.visitCount = 0,
    this.totalDuration = Duration.zero,
    this.coverImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'first_visit': firstVisit.toIso8601String(),
      'last_visit': lastVisit.toIso8601String(),
      'visit_count': visitCount,
      'total_duration_sec': totalDuration.inSeconds,
      'cover_image_path': coverImagePath,
    };
  }

  factory LocationStory.fromMap(Map<String, dynamic> map) {
    return LocationStory(
      id: map['id'] as int,
      locationName: map['location_name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      firstVisit: DateTime.parse(map['first_visit'] as String),
      lastVisit: DateTime.parse(map['last_visit'] as String),
      visitCount: (map['visit_count'] as int?) ?? 0,
      totalDuration: Duration(seconds: (map['total_duration_sec'] as int?) ?? 0),
      coverImagePath: map['cover_image_path'] as String?,
    );
  }
}

/// 故事章节
class StoryChapter {
  final DateTime date;
  final String title;
  final String? description;
  final List<int> recordIds;
  final List<String> photoPaths;
  final Duration duration;

  StoryChapter({
    required this.date,
    required this.title,
    this.description,
    this.recordIds = const [],
    this.photoPaths = const [],
    this.duration = Duration.zero,
  });
}

/// 位置聚合
class LocationCluster {
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final int recordCount;
  final Duration totalDuration;
  final List<LocationStory> stories;
  final String? icon;
  final int color;

  LocationCluster({
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    this.recordCount = 0,
    this.totalDuration = Duration.zero,
    this.stories = const [],
    this.icon,
    this.color = 0xFF2196F3,
  });
}

/// 位置故事时间线
class LocationTimeline {
  final List<TimelineItem> items;
  final DateTime startDate;
  final DateTime endDate;

  LocationTimeline({
    this.items = const [],
    required this.startDate,
    required this.endDate,
  });
}

/// 时间线项目
class TimelineItem {
  final DateTime date;
  final TimelineItemType type;
  final String title;
  final String? subtitle;
  final String? locationName;
  final List<String> photoPaths;
  final Duration? duration;

  TimelineItem({
    required this.date,
    required this.type,
    required this.title,
    this.subtitle,
    this.locationName,
    this.photoPaths = const [],
    this.duration,
  });
}

enum TimelineItemType {
  arrival, // 到达
  departure, // 离开
  activity, // 活动
  photo, // 拍照
  note, // 笔记
}