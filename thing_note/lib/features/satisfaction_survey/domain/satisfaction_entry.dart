/// Satisfaction survey entry
class SatisfactionEntry {
  final int? id;
  final int rating; // 1-5
  final String? comment;
  final List<String> features;
  final DateTime createdAt;

  SatisfactionEntry({
    this.id,
    required this.rating,
    this.comment,
    this.features = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'features': features.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SatisfactionEntry.fromMap(Map<String, dynamic> map) {
    return SatisfactionEntry(
      id: map['id'] as int?,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      features: (map['features'] as String?)?.split(',') ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// App feature for feedback
class AppFeature {
  final String id;
  final String name;
  final String description;
  final String icon;

  const AppFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const List<AppFeature> allFeatures = [
    AppFeature(
      id: 'records',
      name: 'Event Records',
      description: 'Creating and managing event records',
      icon: 'event',
    ),
    AppFeature(
      id: 'photos',
      name: 'Photos',
      description: 'Attaching photos to records',
      icon: 'photo',
    ),
    AppFeature(
      id: 'audio',
      name: 'Audio Recording',
      description: 'Recording audio notes',
      icon: 'mic',
    ),
    AppFeature(
      id: 'video',
      name: 'Video',
      description: 'Attaching videos',
      icon: 'videocam',
    ),
    AppFeature(
      id: 'location',
      name: 'Location',
      description: 'GPS location tagging',
      icon: 'location_on',
    ),
    AppFeature(
      id: 'tags',
      name: 'Tags',
      description: 'Using tags to organize records',
      icon: 'label',
    ),
    AppFeature(
      id: 'search',
      name: 'Search',
      description: 'Searching through records',
      icon: 'search',
    ),
    AppFeature(
      id: 'statistics',
      name: 'Statistics',
      description: 'Viewing statistics and charts',
      icon: 'bar_chart',
    ),
    AppFeature(
      id: 'backup',
      name: 'Backup',
      description: 'Backing up data',
      icon: 'backup',
    ),
    AppFeature(
      id: 'themes',
      name: 'Themes',
      description: 'Customizing app themes',
      icon: 'palette',
    ),
  ];
}