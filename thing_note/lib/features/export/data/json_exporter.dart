import 'dart:convert';
import 'package:thing_note/features/record/domain/episode_record.dart';

class JsonExporter {
  /// 导出记录到 JSON 格式
  String exportToJson(List<EpisodeRecord> records, {Map<String, dynamic>? metadata}) {
    final data = records.map((r) => _recordToJson(r)).toList();

    final exportData = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': records.length,
      if (metadata != null) ...metadata,
      'records': data,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从 JSON 导入记录
  List<EpisodeRecord> importFromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final recordsList = data['records'] as List;

      return recordsList.map((map) => _recordFromJson(map as Map<String, dynamic>)).toList();
    } catch (e) {
      throw FormatException('Invalid JSON format: $e');
    }
  }

  Map<String, dynamic> _recordToJson(EpisodeRecord record) {
    return {
      'id': record.id,
      'occurred_at': record.occurredAt.toIso8601String(),
      'duration_sec': record.durationSec,
      'note': record.note,
      'photo_paths': record.photoPaths,
      'audio_paths': record.audioPaths,
      'audio_durations_sec': record.audioDurationsSec,
      'video_paths': record.videoPaths,
      'document_paths': record.documentPaths,
      'thing_name_id': record.thingNameId,
      'annotations': record.annotationsJson,
      'has_reminder': record.hasReminder,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'address': record.address,
      'is_favorite': record.isFavorite,
      'repeat_type': record.repeatType,
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
    };
  }

  EpisodeRecord _recordFromJson(Map<String, dynamic> map) {
    return EpisodeRecord(
      id: map['id'] as int?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      durationSec: map['duration_sec'] as int? ?? 0,
      note: map['note'] as String? ?? '',
      photoPaths: _parseStringList(map['photo_paths']),
      audioPaths: _parseStringList(map['audio_paths']),
      audioDurationsSec: _parseIntList(map['audio_durations_sec']),
      videoPaths: _parseStringList(map['video_paths']),
      documentPaths: _parseStringList(map['document_paths']),
      thingNameId: map['thing_name_id'] as int?,
      annotationsJson: map['annotations'] as String?,
      hasReminder: map['has_reminder'] as bool? ?? false,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      isFavorite: map['is_favorite'] as bool? ?? false,
      repeatType: map['repeat_type'] as String? ?? 'none',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }
}