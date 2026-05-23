/// 旅行日志数据模型
class TravelLog {
  final int? id;
  final String title;
  final String? destination;
  final DateTime startDate;
  final DateTime? endDate;
  final String? coverImagePath;
  final String content;
  final List<String> photos;
  final List<String> tags;
  final int? linkedRecordId;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TravelLog({
    this.id,
    required this.title,
    this.destination,
    required this.startDate,
    this.endDate,
    this.coverImagePath,
    this.content = '',
    this.photos = const [],
    this.tags = const [],
    this.linkedRecordId,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TravelLog copyWith({
    int? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImagePath,
    String? content,
    List<String>? photos,
    List<String>? tags,
    int? linkedRecordId,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TravelLog(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      content: content ?? this.content,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get durationDays {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'cover_image_path': coverImagePath,
      'content': content,
      'photos': photos.join(','),
      'tags': tags.join(','),
      'linked_record_id': linkedRecordId,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TravelLog.fromMap(Map<String, dynamic> map) {
    return TravelLog(
      id: map['id'] as int?,
      title: map['title'] as String,
      destination: map['destination'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      coverImagePath: map['cover_image_path'] as String?,
      content: map['content'] as String? ?? '',
      photos: (map['photos'] as String?)?.isNotEmpty == true 
          ? (map['photos'] as String).split(',') 
          : [],
      tags: (map['tags'] as String?)?.isNotEmpty == true 
          ? (map['tags'] as String).split(',') 
          : [],
      linkedRecordId: map['linked_record_id'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}