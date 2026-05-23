/// Quick Capture model
class QuickCaptureModel {
  final int? id;
  final String type; // standard, voice, photo, quick, minimal
  final String content;
  final String? mediaPath;
  final String? thingName;
  final List<String> tags;
  final DateTime capturedAt;
  final bool isConverted;
  final int? linkedRecordId;

  QuickCaptureModel({
    this.id,
    required this.type,
    required this.content,
    this.mediaPath,
    this.thingName,
    this.tags = const [],
    DateTime? capturedAt,
    this.isConverted = false,
    this.linkedRecordId,
  }) : capturedAt = capturedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'media_path': mediaPath,
      'thing_name': thingName,
      'tags': tags.join(','),
      'captured_at': capturedAt.toIso8601String(),
      'is_converted': isConverted ? 1 : 0,
      'linked_record_id': linkedRecordId?.toString(),
    };
  }

  factory QuickCaptureModel.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return QuickCaptureModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      content: map['content'] as String,
      mediaPath: map['media_path'] as String?,
      thingName: map['thing_name'] as String?,
      tags: tagsStr != null && tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      capturedAt: DateTime.parse(map['captured_at'] as String),
      isConverted: (map['is_converted'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] != null 
          ? int.tryParse(map['linked_record_id'] as String) 
          : null,
    );
  }
}

/// Quick Capture Configuration
class QuickCaptureConfig {
  final int? id;
  final String mode;
  final int defaultDuration;
  final List<String> quickTags;
  final bool autoLocation;
  final bool autoTime;
  final bool soundEnabled;
  final int rapidInterval; // seconds between rapid captures

  QuickCaptureConfig({
    this.id,
    this.mode = 'standard',
    this.defaultDuration = 0,
    this.quickTags = const [],
    this.autoLocation = true,
    this.autoTime = true,
    this.soundEnabled = true,
    this.rapidInterval = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode,
      'default_duration': defaultDuration,
      'quick_tags': quickTags.join(','),
      'auto_location': autoLocation ? 1 : 0,
      'auto_time': autoTime ? 1 : 0,
      'sound_enabled': soundEnabled ? 1 : 0,
      'rapid_interval': rapidInterval,
    };
  }

  factory QuickCaptureConfig.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['quick_tags'] as String?;
    return QuickCaptureConfig(
      id: map['id'] as int?,
      mode: map['mode'] as String? ?? 'standard',
      defaultDuration: map['default_duration'] as int? ?? 0,
      quickTags: tagsStr != null && tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      autoLocation: (map['auto_location'] as int?) == 1,
      autoTime: (map['auto_time'] as int?) == 1,
      soundEnabled: (map['sound_enabled'] as int?) == 1,
      rapidInterval: map['rapid_interval'] as int? ?? 30,
    );
  }

  QuickCaptureConfig copyWith({
    int? id,
    String? mode,
    int? defaultDuration,
    List<String>? quickTags,
    bool? autoLocation,
    bool? autoTime,
    bool? soundEnabled,
    int? rapidInterval,
  }) {
    return QuickCaptureConfig(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      quickTags: quickTags ?? this.quickTags,
      autoLocation: autoLocation ?? this.autoLocation,
      autoTime: autoTime ?? this.autoTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      rapidInterval: rapidInterval ?? this.rapidInterval,
    );
  }
}