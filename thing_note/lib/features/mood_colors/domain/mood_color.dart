import 'package:flutter/material.dart';

/// 情绪颜色数据模型
class MoodColor {
  final int? id;
  final String date;
  final String colorHex;
  final int moodLevel; // 1-5
  final String? primaryEmotion;
  final double intensity;
  final String? note;
  final String? linkedRecordIds;
  final DateTime createdAt;

  const MoodColor({
    this.id,
    required this.date,
    required this.colorHex,
    this.moodLevel = 3,
    this.primaryEmotion,
    this.intensity = 1.0,
    this.note,
    this.linkedRecordIds,
    required this.createdAt,
  });

  Color get color => Color(_parseHex(colorHex));

  MoodColor copyWith({
    int? id,
    String? date,
    String? colorHex,
    int? moodLevel,
    String? primaryEmotion,
    double? intensity,
    String? note,
    String? linkedRecordIds,
    DateTime? createdAt,
  }) {
    return MoodColor(
      id: id ?? this.id,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
      moodLevel: moodLevel ?? this.moodLevel,
      primaryEmotion: primaryEmotion ?? this.primaryEmotion,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'color_hex': colorHex,
      'mood_level': moodLevel,
      'primary_emotion': primaryEmotion,
      'intensity': intensity,
      'note': note,
      'linked_record_ids': linkedRecordIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodColor.fromMap(Map<String, dynamic> map) {
    return MoodColor(
      id: map['id'] as int?,
      date: map['date'] as String,
      colorHex: map['color_hex'] as String,
      moodLevel: map['mood_level'] as int? ?? 3,
      primaryEmotion: map['primary_emotion'] as String?,
      intensity: (map['intensity'] as num?)?.toDouble() ?? 1.0,
      note: map['note'] as String?,
      linkedRecordIds: map['linked_record_ids'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static int _parseHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}

/// 预设情绪颜色
class MoodColorPresets {
  static const List<Map<String, dynamic>> presets = [
    {'label': '平静', 'color': '#81D4FA', 'mood': 3},
    {'label': '开心', 'color': '#A5D6A7', 'mood': 4},
    {'label': '兴奋', 'color': '#FFF59D', 'mood': 5},
    {'label': '忧伤', 'color': '#B39DDB', 'mood': 2},
    {'label': '焦虑', 'color': '#FFAB91', 'mood': 2},
    {'label': '愤怒', 'color': '#EF9A9A', 'mood': 1},
    {'label': '疲惫', 'color': '#CFD8DC', 'mood': 2},
    {'label': '专注', 'color': '#80CBC4', 'mood': 4},
    {'label': '感激', 'color': '#F48FB1', 'mood': 5},
    {'label': '无聊', 'color': '#EEEEEE', 'mood': 2},
    {'label': '充满希望', 'color': '#DCEDC8', 'mood': 4},
    {'label': '压力大', 'color': '#FFE0B2', 'mood': 1},
  ];
}
