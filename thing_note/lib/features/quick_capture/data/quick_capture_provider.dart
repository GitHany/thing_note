// Quick Capture Modes feature
// Version: 1.0
// Description: 多种快速记录模式，支持语音、拍照、快捷文本等快速捕获方式

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Quick Capture Provider
final quickCaptureModeProvider = StateProvider<QuickCaptureMode>((ref) {
  return QuickCaptureMode.standard;
});

enum QuickCaptureMode {
  standard,
  voice,
  photo,
  rapid,
  minimalist,
}

final quickCaptureConfigProvider = FutureProvider<QuickCaptureConfig>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'quick_capture_config',
    limit: 1,
  );
  
  if (maps.isNotEmpty) {
    return QuickCaptureConfig.fromMap(maps.first);
  }
  
  return QuickCaptureConfig.defaultConfig();
});

class QuickCaptureConfig {
  final int? id;
  final String mode;
  final int defaultDuration;
  final List<String> quickTags;
  final bool autoLocation;
  final bool autoTime;
  final bool soundEnabled;
  final int rapidIntervalSeconds;

  QuickCaptureConfig({
    this.id,
    required this.mode,
    this.defaultDuration = 0,
    this.quickTags = const [],
    this.autoLocation = true,
    this.autoTime = true,
    this.soundEnabled = true,
    this.rapidIntervalSeconds = 30,
  });

  factory QuickCaptureConfig.fromMap(Map<String, dynamic> map) {
    return QuickCaptureConfig(
      id: map['id'] as int?,
      mode: map['mode'] as String? ?? 'standard',
      defaultDuration: map['default_duration'] as int? ?? 0,
      quickTags: (map['quick_tags'] as String?)?.split(',') ?? [],
      autoLocation: (map['auto_location'] as int?) == 1,
      autoTime: (map['auto_time'] as int?) == 1,
      soundEnabled: (map['sound_enabled'] as int?) == 1,
      rapidIntervalSeconds: map['rapid_interval'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode,
      'default_duration': defaultDuration,
      'quick_tags': quickTags.join(','),
      'auto_location': autoLocation ? 1 : 0,
      'auto_time': autoTime ? 1 : 0,
      'sound_enabled': soundEnabled ? 1 : 0,
      'rapid_interval': rapidIntervalSeconds,
    };
  }

  factory QuickCaptureConfig.defaultConfig() {
    return QuickCaptureConfig(
      mode: 'standard',
      defaultDuration: 0,
      quickTags: ['工作', '学习', '生活'],
      autoLocation: true,
      autoTime: true,
      soundEnabled: true,
      rapidIntervalSeconds: 30,
    );
  }
}

// Recent Captures Provider
final recentCapturesProvider = FutureProvider<List<QuickCapture>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'quick_captures',
    orderBy: 'captured_at DESC',
    limit: 20,
  );
  
  return maps.map((map) => QuickCapture.fromMap(map)).toList();
});

class QuickCapture {
  final int? id;
  final String type;
  final String content;
  final String? mediaPath;
  final String? thingName;
  final List<String> tags;
  final String capturedAt;
  final bool isConverted;
  final String? linkedRecordId;

  QuickCapture({
    this.id,
    required this.type,
    required this.content,
    this.mediaPath,
    this.thingName,
    this.tags = const [],
    required this.capturedAt,
    this.isConverted = false,
    this.linkedRecordId,
  });

  factory QuickCapture.fromMap(Map<String, dynamic> map) {
    return QuickCapture(
      id: map['id'] as int?,
      type: map['type'] as String,
      content: map['content'] as String,
      mediaPath: map['media_path'] as String?,
      thingName: map['thing_name'] as String?,
      tags: (map['tags'] as String?)?.split(',') ?? [],
      capturedAt: map['captured_at'] as String,
      isConverted: (map['is_converted'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'media_path': mediaPath,
      'thing_name': thingName,
      'tags': tags.join(','),
      'captured_at': capturedAt,
      'is_converted': isConverted ? 1 : 0,
      'linked_record_id': linkedRecordId,
    };
  }

  IconData get icon {
    switch (type) {
      case 'voice':
        return Icons.mic;
      case 'photo':
        return Icons.camera_alt;
      case 'text':
        return Icons.text_fields;
      case 'rapid':
        return Icons.flash_on;
      default:
        return Icons.note;
    }
  }
}