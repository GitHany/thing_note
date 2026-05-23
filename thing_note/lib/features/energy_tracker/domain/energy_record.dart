import 'package:flutter/material.dart';

class EnergyRecord {
  final int? id;
  final String date;
  final int level;
  final String? note;
  final String? activities;
  final String createdAt;

  EnergyRecord({
    this.id,
    required this.date,
    required this.level,
    this.note,
    this.activities,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'level': level,
      'note': note,
      'activities': activities,
      'created_at': createdAt,
    };
  }

  factory EnergyRecord.fromMap(Map<String, dynamic> map) {
    return EnergyRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      level: map['level'] as int,
      note: map['note'] as String?,
      activities: map['activities'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  EnergyRecord copyWith({
    int? id, String? date, int? level, String? note, String? activities, String? createdAt,
  }) {
    return EnergyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      level: level ?? this.level,
      note: note ?? this.note,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String getLevelLabel(int level) {
    const labels = {1: '非常疲惫', 2: '疲惫', 3: '一般', 4: '良好', 5: '精力充沛'};
    return labels[level] ?? '未知';
  }

  static Color getLevelColor(int level) {
    const colors = {1: Colors.red, 2: Colors.orange, 3: Colors.yellow, 4: Colors.lightGreen, 5: Colors.green};
    return colors[level] ?? Colors.grey;
  }
}

class EnergyTip {
  final int? id;
  final String content;
  final int minLevel;
  final int maxLevel;
  final String createdAt;

  EnergyTip({
    this.id,
    required this.content,
    required this.minLevel,
    required this.maxLevel,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'min_level': minLevel,
      'max_level': maxLevel,
      'created_at': createdAt,
    };
  }

  factory EnergyTip.fromMap(Map<String, dynamic> map) {
    return EnergyTip(
      id: map['id'] as int?,
      content: map['content'] as String,
      minLevel: map['min_level'] as int,
      maxLevel: map['max_level'] as int,
      createdAt: map['created_at'] as String,
    );
  }

  static List<EnergyTip> get defaultTips {
    final now = DateTime.now().toIso8601String();
    return [
      EnergyTip(content: '短暂休息 10 分钟，伸展身体', minLevel: 1, maxLevel: 2, createdAt: now),
      EnergyTip(content: '喝一杯温水或茶', minLevel: 1, maxLevel: 3, createdAt: now),
      EnergyTip(content: '进行 5 分钟深呼吸练习', minLevel: 1, maxLevel: 2, createdAt: now),
      EnergyTip(content: '听一些轻松的音乐', minLevel: 1, maxLevel: 4, createdAt: now),
      EnergyTip(content: '短暂散步 15 分钟', minLevel: 2, maxLevel: 3, createdAt: now),
      EnergyTip(content: '与朋友聊天放松', minLevel: 1, maxLevel: 4, createdAt: now),
      EnergyTip(content: '做些轻度运动', minLevel: 3, maxLevel: 4, createdAt: now),
      EnergyTip(content: '计划明天的任务', minLevel: 4, maxLevel: 5, createdAt: now),
      EnergyTip(content: '挑战新项目', minLevel: 4, maxLevel: 5, createdAt: now),
      EnergyTip(content: '保持当前的高效状态', minLevel: 5, maxLevel: 5, createdAt: now),
    ];
  }
}