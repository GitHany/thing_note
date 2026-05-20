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
    double? latitude,
    double? longitude,
    String? address,
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
}
