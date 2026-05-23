import 'package:flutter/material.dart';

/// 情绪行动数据模型
class MoodAction {
  final int? id;
  final int moodLevel;
  final String actionName;
  final String actionType;
  final bool isCustom;
  final DateTime createdAt;

  const MoodAction({
    this.id,
    required this.moodLevel,
    required this.actionName,
    required this.actionType,
    this.isCustom = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mood_level': moodLevel,
      'action_name': actionName,
      'action_type': actionType,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodAction.fromMap(Map<String, dynamic> map) {
    return MoodAction(
      id: map['id'] as int?,
      moodLevel: map['mood_level'] as int,
      actionName: map['action_name'] as String,
      actionType: map['action_type'] as String,
      isCustom: (map['is_custom'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 预设情绪行动
class PresetMoodAction {
  final int moodLevel;
  final String actionName;
  final IconData icon;
  final String actionType;

  const PresetMoodAction({
    required this.moodLevel,
    required this.actionName,
    required this.icon,
    required this.actionType,
  });

  static const List<PresetMoodAction> presets = [
    PresetMoodAction(moodLevel: 1, actionName: '听舒缓音乐', icon: Icons.music_note, actionType: 'music'),
    PresetMoodAction(moodLevel: 1, actionName: '散步', icon: Icons.directions_walk, actionType: 'exercise'),
    PresetMoodAction(moodLevel: 1, actionName: '深呼吸', icon: Icons.air, actionType: 'meditation'),
    PresetMoodAction(moodLevel: 2, actionName: '喝茶', icon: Icons.local_cafe, actionType: 'comfort'),
    PresetMoodAction(moodLevel: 2, actionName: '看书', icon: Icons.menu_book, actionType: 'relax'),
    PresetMoodAction(moodLevel: 2, actionName: '聊天', icon: Icons.chat, actionType: 'social'),
    PresetMoodAction(moodLevel: 3, actionName: '看视频', icon: Icons.video_library, actionType: 'entertainment'),
    PresetMoodAction(moodLevel: 3, actionName: '做家务', icon: Icons.cleaning_services, actionType: 'productivity'),
    PresetMoodAction(moodLevel: 4, actionName: '运动', icon: Icons.fitness_center, actionType: 'exercise'),
    PresetMoodAction(moodLevel: 4, actionName: '学习新技能', icon: Icons.school, actionType: 'learning'),
    PresetMoodAction(moodLevel: 5, actionName: '分享快乐', icon: Icons.share, actionType: 'social'),
    PresetMoodAction(moodLevel: 5, actionName: '庆祝', icon: Icons.celebration, actionType: 'celebration'),
  ];
}