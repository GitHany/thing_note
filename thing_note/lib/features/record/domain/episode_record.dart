class EpisodeRecord {
  final int? id;
  final DateTime occurredAt;
  final int durationSec;
  final String note;
  final List<String> photoPaths;
  final List<String> audioPaths;
  final List<int> audioDurationsSec;
  final int? thingNameId;
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
    this.thingNameId,
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
    int? thingNameId,
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
      thingNameId: thingNameId ?? this.thingNameId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Duration get duration => Duration(seconds: durationSec);
  bool get hasPhotos => photoPaths.isNotEmpty;
  bool get hasAudio => audioPaths.isNotEmpty;
  int get totalAudioDurationSec => audioDurationsSec.fold(0, (sum, d) => sum + d);
}
