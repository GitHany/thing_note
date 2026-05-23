import 'dart:convert';

class EpisodeRecord {
  final int? id;
  final DateTime occurredAt;
  final int durationSec;
  final String note;
  final List<String> photoPaths;
  final List<String> audioPaths;
  final List<int> audioDurationsSec;
  final List<String> videoPaths;
  final List<String> documentPaths;
  final int? thingNameId;
  final String? annotationsJson;
  final bool hasReminder;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isFavorite;
  final String repeatType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EpisodeRecord({
    this.id,
    required this.occurredAt,
    required this.durationSec,
    this.note = '',
    this.photoPaths = const [],
    this.audioPaths = const [],
    this.audioDurationsSec = const [],
    this.videoPaths = const [],
    this.documentPaths = const [],
    this.thingNameId,
    this.annotationsJson,
    this.hasReminder = false,
    this.latitude,
    this.longitude,
    this.address,
    this.isFavorite = false,
    this.repeatType = 'none',
    required this.createdAt,
    required this.updatedAt,
  });

  EpisodeRecord copyWith({
    int? id,
    DateTime? occurredAt,
    int? durationSec,
    String? note,
    List<String>? photoPaths,
    List<String>? audioPaths,
    List<int>? audioDurationsSec,
    List<String>? videoPaths,
    List<String>? documentPaths,
    int? thingNameId,
    String? annotationsJson,
    bool? hasReminder,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    String? address,
    String? repeatType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EpisodeRecord(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      durationSec: durationSec ?? this.durationSec,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      audioPaths: audioPaths ?? this.audioPaths,
      audioDurationsSec: audioDurationsSec ?? this.audioDurationsSec,
      videoPaths: videoPaths ?? this.videoPaths,
      documentPaths: documentPaths ?? this.documentPaths,
      thingNameId: thingNameId ?? this.thingNameId,
      annotationsJson: annotationsJson ?? this.annotationsJson,
      hasReminder: hasReminder ?? this.hasReminder,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isFavorite: isFavorite ?? this.isFavorite,
      repeatType: repeatType ?? this.repeatType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Duration get duration => Duration(seconds: durationSec);
  bool get hasPhotos => photoPaths.isNotEmpty;
  bool get hasAudio => audioPaths.isNotEmpty;
  bool get hasVideos => videoPaths.isNotEmpty;
  bool get hasDocuments => documentPaths.isNotEmpty;
  bool get hasAnnotations =>
      annotationsJson != null &&
      annotationsJson!.isNotEmpty &&
      annotationsJson != '{"version":1,"elements":[]}';
  int get totalAudioDurationSec => audioDurationsSec.fold(0, (sum, d) => sum + d);
  bool get hasLocation => latitude != null && longitude != null;
  bool get isFavorited => isFavorite;
  bool get isRecurring => repeatType != 'none';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'occurred_at': occurredAt.toIso8601String(),
      'duration_sec': durationSec,
      'note': note,
      'photo_paths': jsonEncode(photoPaths),
      'audio_paths': jsonEncode(audioPaths),
      'audio_durations_sec': jsonEncode(audioDurationsSec),
      'video_paths': jsonEncode(videoPaths),
      'document_paths': jsonEncode(documentPaths),
      'thing_name_id': thingNameId,
      if (annotationsJson != null) 'annotations': annotationsJson,
      'has_reminder': hasReminder ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_favorite': isFavorite ? 1 : 0,
      'repeat_type': repeatType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
