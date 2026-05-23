/// 归档记录数据模型
class ArchivedRecord {
  final int? id;
  final int originalId;
  final String occurredAt;
  final int durationSec;
  final String note;
  final String photoPaths;
  final String audioPaths;
  final String audioDurationsSec;
  final int? thingNameId;
  final String? annotations;
  final int hasReminder;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String videoPaths;
  final String documentPaths;
  final int isFavorite;
  final String repeatType;
  final String createdAt;
  final String updatedAt;
  final String tagIds;
  final String? linkedRecordIds;
  final int? rating;
  final int? importance;
  final String archivedAt;
  final String? archivedReason;

  ArchivedRecord({
    this.id,
    required this.originalId,
    required this.occurredAt,
    required this.durationSec,
    required this.note,
    required this.photoPaths,
    required this.audioPaths,
    required this.audioDurationsSec,
    this.thingNameId,
    this.annotations,
    required this.hasReminder,
    this.latitude,
    this.longitude,
    this.address,
    required this.videoPaths,
    required this.documentPaths,
    required this.isFavorite,
    required this.repeatType,
    required this.createdAt,
    required this.updatedAt,
    required this.tagIds,
    this.linkedRecordIds,
    this.rating,
    this.importance,
    required this.archivedAt,
    this.archivedReason,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'original_id': originalId,
      'occurred_at': occurredAt,
      'duration_sec': durationSec,
      'note': note,
      'photo_paths': photoPaths,
      'audio_paths': audioPaths,
      'audio_durations_sec': audioDurationsSec,
      'thing_name_id': thingNameId,
      'annotations': annotations,
      'has_reminder': hasReminder,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'video_paths': videoPaths,
      'document_paths': documentPaths,
      'is_favorite': isFavorite,
      'repeat_type': repeatType,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'tag_ids': tagIds,
      'linked_record_ids': linkedRecordIds,
      'rating': rating,
      'importance': importance,
      'archived_at': archivedAt,
      'archived_reason': archivedReason,
    };
  }

  factory ArchivedRecord.fromMap(Map<String, dynamic> map) {
    return ArchivedRecord(
      id: map['id'] as int?,
      originalId: map['original_id'] as int,
      occurredAt: map['occurred_at'] as String,
      durationSec: map['duration_sec'] as int,
      note: map['note'] as String,
      photoPaths: map['photo_paths'] as String,
      audioPaths: map['audio_paths'] as String,
      audioDurationsSec: map['audio_durations_sec'] as String,
      thingNameId: map['thing_name_id'] as int?,
      annotations: map['annotations'] as String?,
      hasReminder: map['has_reminder'] as int,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      videoPaths: map['video_paths'] as String,
      documentPaths: map['document_paths'] as String,
      isFavorite: map['is_favorite'] as int,
      repeatType: map['repeat_type'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      tagIds: map['tag_ids'] as String,
      linkedRecordIds: map['linked_record_ids'] as String?,
      rating: map['rating'] as int?,
      importance: map['importance'] as int?,
      archivedAt: map['archived_at'] as String,
      archivedReason: map['archived_reason'] as String?,
    );
  }

  ArchivedRecord copyWith({
    int? id,
    int? originalId,
    String? occurredAt,
    int? durationSec,
    String? note,
    String? photoPaths,
    String? audioPaths,
    String? audioDurationsSec,
    int? thingNameId,
    String? annotations,
    int? hasReminder,
    double? latitude,
    double? longitude,
    String? address,
    String? videoPaths,
    String? documentPaths,
    int? isFavorite,
    String? repeatType,
    String? createdAt,
    String? updatedAt,
    String? tagIds,
    String? linkedRecordIds,
    int? rating,
    int? importance,
    String? archivedAt,
    String? archivedReason,
  }) {
    return ArchivedRecord(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      occurredAt: occurredAt ?? this.occurredAt,
      durationSec: durationSec ?? this.durationSec,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      audioPaths: audioPaths ?? this.audioPaths,
      audioDurationsSec: audioDurationsSec ?? this.audioDurationsSec,
      thingNameId: thingNameId ?? this.thingNameId,
      annotations: annotations ?? this.annotations,
      hasReminder: hasReminder ?? this.hasReminder,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      videoPaths: videoPaths ?? this.videoPaths,
      documentPaths: documentPaths ?? this.documentPaths,
      isFavorite: isFavorite ?? this.isFavorite,
      repeatType: repeatType ?? this.repeatType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tagIds: tagIds ?? this.tagIds,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      rating: rating ?? this.rating,
      importance: importance ?? this.importance,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedReason: archivedReason ?? this.archivedReason,
    );
  }
}

/// 归档状态枚举
enum ArchiveStatus {
  active,    // 正常记录
  archived,  // 已归档
  trashed,   // 已删除（回收站）
}

/// 批量操作类型
enum BatchOperationType {
  archive,
  unarchive,
  trash,
  restore,
  permanentDelete,
}