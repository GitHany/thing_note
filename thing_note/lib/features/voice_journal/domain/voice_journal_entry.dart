/// 语音日记数据模型
class VoiceJournalEntry {
  final int? id;
  final String date;
  final String filePath;
  final int durationSeconds;
  final String? transcript;
  final String? mood;
  final String? tags;
  final bool isTranscribed;
  final bool isFavorite;
  final DateTime createdAt;

  const VoiceJournalEntry({
    this.id,
    required this.date,
    required this.filePath,
    this.durationSeconds = 0,
    this.transcript,
    this.mood,
    this.tags,
    this.isTranscribed = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  VoiceJournalEntry copyWith({
    int? id,
    String? date,
    String? filePath,
    int? durationSeconds,
    String? transcript,
    String? mood,
    String? tags,
    bool? isTranscribed,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return VoiceJournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transcript: transcript ?? this.transcript,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isTranscribed: isTranscribed ?? this.isTranscribed,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'file_path': filePath,
      'duration_seconds': durationSeconds,
      'transcript': transcript,
      'mood': mood,
      'tags': tags,
      'is_transcribed': isTranscribed ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VoiceJournalEntry.fromMap(Map<String, dynamic> map) {
    return VoiceJournalEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      filePath: map['file_path'] as String,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      transcript: map['transcript'] as String?,
      mood: map['mood'] as String?,
      tags: map['tags'] as String?,
      isTranscribed: (map['is_transcribed'] as int? ?? 0) == 1,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
