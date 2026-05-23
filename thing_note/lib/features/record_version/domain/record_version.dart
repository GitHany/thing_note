/// Record version model for tracking record changes
class RecordVersion {
  final int? id;
  final int recordId;
  final String note;
  final String? photoPaths;
  final String? audioPaths;
  final String? videoPaths;
  final int? thingNameId;
  final int durationSec;
  final String? annotationsJson;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String changeType; // created, updated, restored
  final String? changeDetail; // what was changed
  final DateTime versionAt;
  final DateTime createdAt;

  RecordVersion({
    this.id,
    required this.recordId,
    required this.note,
    this.photoPaths,
    this.audioPaths,
    this.videoPaths,
    this.thingNameId,
    this.durationSec = 0,
    this.annotationsJson,
    this.latitude,
    this.longitude,
    this.address,
    required this.changeType,
    this.changeDetail,
    required this.versionAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'note': note,
      'photo_paths': photoPaths,
      'audio_paths': audioPaths,
      'video_paths': videoPaths,
      'thing_name_id': thingNameId,
      'duration_sec': durationSec,
      'annotations_json': annotationsJson,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'change_type': changeType,
      'change_detail': changeDetail,
      'version_at': versionAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecordVersion.fromMap(Map<String, dynamic> map) {
    return RecordVersion(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      note: map['note'] as String? ?? '',
      photoPaths: map['photo_paths'] as String?,
      audioPaths: map['audio_paths'] as String?,
      videoPaths: map['video_paths'] as String?,
      thingNameId: map['thing_name_id'] as int?,
      durationSec: map['duration_sec'] as int? ?? 0,
      annotationsJson: map['annotations_json'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      changeType: map['change_type'] as String? ?? 'updated',
      changeDetail: map['change_detail'] as String?,
      versionAt: DateTime.parse(map['version_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  RecordVersion copyWith({
    int? id,
    int? recordId,
    String? note,
    String? photoPaths,
    String? audioPaths,
    String? videoPaths,
    int? thingNameId,
    int? durationSec,
    String? annotationsJson,
    double? latitude,
    double? longitude,
    String? address,
    String? changeType,
    String? changeDetail,
    DateTime? versionAt,
    DateTime? createdAt,
  }) {
    return RecordVersion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      audioPaths: audioPaths ?? this.audioPaths,
      videoPaths: videoPaths ?? this.videoPaths,
      thingNameId: thingNameId ?? this.thingNameId,
      durationSec: durationSec ?? this.durationSec,
      annotationsJson: annotationsJson ?? this.annotationsJson,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      changeType: changeType ?? this.changeType,
      changeDetail: changeDetail ?? this.changeDetail,
      versionAt: versionAt ?? this.versionAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Version comparison result
class VersionComparison {
  final RecordVersion? oldVersion;
  final RecordVersion newVersion;
  final List<String> changes;

  VersionComparison({
    this.oldVersion,
    required this.newVersion,
    this.changes = const [],
  });
}