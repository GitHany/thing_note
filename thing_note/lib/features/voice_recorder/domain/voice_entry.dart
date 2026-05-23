/// Voice recorder entry representing a voice memo
class VoiceEntry {
  final int? id;
  final String title;
  final String filePath;
  final int durationSec;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? linkedRecordId;
  final bool isFavorite;

  VoiceEntry({
    this.id,
    required this.title,
    required this.filePath,
    required this.durationSec,
    required this.createdAt,
    this.updatedAt,
    this.linkedRecordId,
    this.isFavorite = false,
  });

  VoiceEntry copyWith({
    int? id,
    String? title,
    String? filePath,
    int? durationSec,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedRecordId,
    bool? isFavorite,
  }) {
    return VoiceEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'duration_sec': durationSec,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory VoiceEntry.fromMap(Map<String, dynamic> map) {
    return VoiceEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      durationSec: map['duration_sec'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      linkedRecordId: map['linked_record_id'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }
}

/// Recording state enum
enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}