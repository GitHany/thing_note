import 'dart:convert';

/// Voice memo entry with transcription support
class VoiceMemo {
  final int? id;
  final int? recordId;
  final String title;
  final String filePath;
  final int durationSec;
  final String? transcription;
  final List<String> keywords;
  final String? transcriptLanguage;
  final bool isFavorite;
  final DateTime createdAt;

  VoiceMemo({
    this.id,
    this.recordId,
    required this.title,
    required this.filePath,
    this.durationSec = 0,
    this.transcription,
    this.keywords = const [],
    this.transcriptLanguage,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'title': title,
      'file_path': filePath,
      'duration_sec': durationSec,
      'transcription': transcription,
      'keywords': jsonEncode(keywords),
      'transcript_language': transcriptLanguage,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VoiceMemo.fromMap(Map<String, dynamic> map) {
    return VoiceMemo(
      id: map['id'] as int?,
      recordId: map['record_id'] as int?,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      durationSec: map['duration_sec'] as int? ?? 0,
      transcription: map['transcription'] as String?,
      keywords: List<String>.from(jsonDecode(map['keywords'] as String? ?? '[]')),
      transcriptLanguage: map['transcript_language'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  VoiceMemo copyWith({
    int? id,
    int? recordId,
    String? title,
    String? filePath,
    int? durationSec,
    String? transcription,
    List<String>? keywords,
    String? transcriptLanguage,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return VoiceMemo(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSec: durationSec ?? this.durationSec,
      transcription: transcription ?? this.transcription,
      keywords: keywords ?? this.keywords,
      transcriptLanguage: transcriptLanguage ?? this.transcriptLanguage,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasTranscription => transcription != null && transcription!.isNotEmpty;
  String get formattedDuration {
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Voice memo category
enum VoiceMemoCategory {
  meeting,
  idea,
  reminder,
  personal,
  work,
  other,
}

/// Voice search result
class VoiceSearchResult {
  final VoiceMemo memo;
  final double relevanceScore;
  final List<String> matchedTerms;

  VoiceSearchResult({
    required this.memo,
    required this.relevanceScore,
    this.matchedTerms = const [],
  });
}

/// Transcription config
class TranscriptionConfig {
  final String language;
  final bool autoDetectLanguage;
  final bool enablePunctuation;
  final bool filterProfanity;

  TranscriptionConfig({
    this.language = 'zh-CN',
    this.autoDetectLanguage = true,
    this.enablePunctuation = true,
    this.filterProfanity = false,
  });
}