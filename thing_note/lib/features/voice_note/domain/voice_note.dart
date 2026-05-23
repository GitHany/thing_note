import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class VoiceNote {
  final int? id;
  final String title;
  final String filePath;
  final int durationSec;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? linkedRecordId;
  final bool isFavorite;
  final String? transcribedText;
  final List<String>? keywords;

  VoiceNote({
    this.id,
    required this.title,
    required this.filePath,
    this.durationSec = 0,
    required this.createdAt,
    this.updatedAt,
    this.linkedRecordId,
    this.isFavorite = false,
    this.transcribedText,
    this.keywords,
  });

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
      'transcribed_text': transcribedText,
    };
  }

  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    return VoiceNote(
      id: map['id'] as int?,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      durationSec: map['duration_sec'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      linkedRecordId: map['linked_record_id'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      transcribedText: map['transcribed_text'] as String?,
    );
  }

  VoiceNote copyWith({
    int? id,
    String? title,
    String? filePath,
    int? durationSec,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedRecordId,
    bool? isFavorite,
    String? transcribedText,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSec: durationSec ?? this.durationSec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isFavorite: isFavorite ?? this.isFavorite,
      transcribedText: transcribedText ?? this.transcribedText,
    );
  }
}

class VoiceNoteService {
  Future<String> getRecordingDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${appDir.path}/voice_notes');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    return voiceDir.path;
  }

  Future<String> generateFilePath() async {
    final dir = await getRecordingDirectory();
    final uuid = const Uuid().v4();
    return '$dir/$uuid.m4a';
  }

  Future<List<String>> extractKeywords(String text) async {
    // Simple keyword extraction - in production would use NLP
    if (text.isEmpty) return [];
    
    final words = text.split(RegExp(r'\s+'));
    final freq = <String, int>{};
    
    for (final word in words) {
      if (word.length > 2) {
        freq[word] = (freq[word] ?? 0) + 1;
      }
    }
    
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(5).map((e) => e.key).toList();
  }
}

final voiceNoteServiceProvider = Provider<VoiceNoteService>((ref) {
  return VoiceNoteService();
});