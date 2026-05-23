import 'package:flutter/material.dart';

/// Trigger types for stress sources
class StressTriggerType {
  static const String work = 'work';
  static const String personal = 'personal';
  static const String health = 'health';
  static const String relationships = 'relationships';
  static const String financial = 'financial';
  static const String other = 'other';

  static const List<String> all = [work, personal, health, relationships, financial, other];

  static String getLabel(String type) {
    switch (type) {
      case work: return '工作';
      case personal: return '个人';
      case health: return '健康';
      case relationships: return '人际关系';
      case financial: return '财务';
      default: return '其他';
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case work: return Icons.work;
      case personal: return Icons.person;
      case health: return Icons.favorite;
      case relationships: return Icons.people;
      case financial: return Icons.attach_money;
      default: return Icons.more_horiz;
    }
  }
}

/// Common physical symptoms
class StressSymptom {
  static const String headache = '头痛';
  static const String muscleTension = '肌肉紧张';
  static const String fatigue = '疲劳';
  static const String insomnia = '失眠';
  static const String rapidHeartbeat = '心跳加速';
  static const String shortnessOfBreath = '呼吸急促';
  static const String stomachAche = '胃部不适';
  static const String appetiteChange = '食欲变化';
  static const String irritability = '易怒';
  static const String anxiety = '焦虑';
  static const String difficultyFocusing = '注意力难以集中';
  static const String restlessness = '坐立不安';

  static const List<String> all = [
    headache, muscleTension, fatigue, insomnia, rapidHeartbeat,
    shortnessOfBreath, stomachAche, appetiteChange, irritability,
    anxiety, difficultyFocusing, restlessness
  ];

  static IconData getIcon(String symptom) {
    switch (symptom) {
      case headache: return Icons.face;
      case muscleTension: return Icons.accessibility;
      case fatigue: return Icons.battery_alert;
      case insomnia: return Icons.nights_stay;
      case rapidHeartbeat: return Icons.favorite;
      case shortnessOfBreath: return Icons.air;
      case stomachAche: return Icons.sick;
      case appetiteChange: return Icons.restaurant;
      case irritability: return Icons.mood_bad;
      case anxiety: return Icons.psychology;
      case difficultyFocusing: return Icons.visibility_off;
      case restlessness: return Icons.directions_run;
      default: return Icons.help_outline;
    }
  }
}

/// Common coping strategies
class CopingStrategy {
  static const String deepBreathing = '深呼吸';
  static const String exercise = '运动';
  static const String meditation = '冥想';
  static const String talkingToSomeone = '倾诉';
  static const String takingBreak = '休息';
  static const String listeningToMusic = '听音乐';
  static const String journaling = '写日记';
  static const String timeManagement = '时间管理';
  static const String settingBoundaries = '设定界限';
  static const String professionalHelp = '寻求专业帮助';
  static const String hobby = '培养爱好';
  static const String sleep = '充足睡眠';

  static const List<String> all = [
    deepBreathing, exercise, meditation, talkingToSomeone, takingBreak,
    listeningToMusic, journaling, timeManagement, settingBoundaries,
    professionalHelp, hobby, sleep
  ];

  static IconData getIcon(String strategy) {
    switch (strategy) {
      case deepBreathing: return Icons.air;
      case exercise: return Icons.fitness_center;
      case meditation: return Icons.self_improvement;
      case talkingToSomeone: return Icons.chat;
      case takingBreak: return Icons.pause_circle;
      case listeningToMusic: return Icons.music_note;
      case journaling: return Icons.edit_note;
      case timeManagement: return Icons.schedule;
      case settingBoundaries: return Icons.block;
      case professionalHelp: return Icons.medical_services;
      case hobby: return Icons.palette;
      case sleep: return Icons.bedtime;
      default: return Icons.help_outline;
    }
  }

  static String getEffectivenessTip(String strategy) {
    switch (strategy) {
      case deepBreathing: return '每次深呼吸持续4秒吸气，7秒屏气，8秒呼气';
      case exercise: return '每天30分钟中等强度运动可降低皮质醇水平';
      case meditation: return '每天10-15分钟正念冥想有助于减轻焦虑';
      case talkingToSomeone: return '与信任的人分享可以减轻情绪负担';
      case takingBreak: return '工作间隙短暂休息可提高效率和专注力';
      case listeningToMusic: return '舒缓的音乐可以降低心率和血压';
      case journaling: return '写作可以帮助整理思绪和情绪';
      case timeManagement: return '合理安排时间可以减少紧迫感';
      case settingBoundaries: return '学会说"不"保护自己的时间和精力';
      case professionalHelp: return '心理咨询师可以提供专业的情绪管理技巧';
      case hobby: return '培养兴趣爱好可以转移注意力并带来愉悦感';
      case sleep: return '7-9小时的睡眠对压力恢复至关重要';
      default: return '选择适合自己的方式来缓解压力';
    }
  }
}

class StressIndicator {
  final int? id;
  final DateTime recordedAt;
  final int stressLevel;
  final String? triggerType;
  final List<String> triggers;
  final List<String> physicalSymptoms;
  final List<String> copingStrategies;
  final int? effectivenessRating;
  final int moodScore;
  final int energyLevel;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  StressIndicator({
    this.id,
    required this.recordedAt,
    required this.stressLevel,
    this.triggerType,
    this.triggers = const [],
    this.physicalSymptoms = const [],
    this.copingStrategies = const [],
    this.effectivenessRating,
    this.moodScore = 0,
    this.energyLevel = 0,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recorded_at': recordedAt.toIso8601String(),
      'stress_level': stressLevel,
      'trigger_type': triggerType,
      'triggers': triggers.join(','),
      'physical_symptoms': physicalSymptoms.join(','),
      'coping_strategies': copingStrategies.join(','),
      'effectiveness_rating': effectivenessRating,
      'mood_score': moodScore,
      'energy_level': energyLevel,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StressIndicator.fromMap(Map<String, dynamic> map) {
    return StressIndicator(
      id: map['id'] as int?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      stressLevel: map['stress_level'] as int,
      triggerType: map['trigger_type'] as String?,
      triggers: _parseList(map['triggers'] as String?),
      physicalSymptoms: _parseList(map['physical_symptoms'] as String?),
      copingStrategies: _parseList(map['coping_strategies'] as String?),
      effectivenessRating: map['effectiveness_rating'] as int?,
      moodScore: map['mood_score'] as int? ?? 0,
      energyLevel: map['energy_level'] as int? ?? 0,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static List<String> _parseList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((t) => t.isNotEmpty).toList();
  }

  StressIndicator copyWith({
    int? id,
    DateTime? recordedAt,
    int? stressLevel,
    String? triggerType,
    List<String>? triggers,
    List<String>? physicalSymptoms,
    List<String>? copingStrategies,
    int? effectivenessRating,
    int? moodScore,
    int? energyLevel,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return StressIndicator(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      stressLevel: stressLevel ?? this.stressLevel,
      triggerType: triggerType ?? this.triggerType,
      triggers: triggers ?? this.triggers,
      physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      effectivenessRating: effectivenessRating ?? this.effectivenessRating,
      moodScore: moodScore ?? this.moodScore,
      energyLevel: energyLevel ?? this.energyLevel,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Stress level classification
  String get stressLabel {
    if (stressLevel >= 8) return '严重压力';
    if (stressLevel >= 6) return '较高压力';
    if (stressLevel >= 4) return '中等压力';
    if (stressLevel >= 2) return '轻度压力';
    return '无明显压力';
  }

  Color get stressColor {
    if (stressLevel >= 8) return Colors.red.shade700;
    if (stressLevel >= 6) return Colors.red.shade400;
    if (stressLevel >= 4) return Colors.orange;
    if (stressLevel >= 2) return Colors.yellow.shade700;
    return Colors.green;
  }

  String get triggerTypeLabel {
    return triggerType != null 
        ? StressTriggerType.getLabel(triggerType!) 
        : '未分类';
  }

  IconData get triggerTypeIcon {
    return triggerType != null 
        ? StressTriggerType.getIcon(triggerType!) 
        : Icons.help_outline;
  }

  // Effectiveness label
  String get effectivenessLabel {
    if (effectivenessRating == null) return '未评估';
    if (effectivenessRating! >= 4) return '非常有效';
    if (effectivenessRating! >= 3) return '有效';
    if (effectivenessRating! >= 2) return '一般';
    return '效果不佳';
  }
}

class StressPattern {
  final String triggerType;
  final double avgStressLevel;
  final int frequency;
  final double successRate;
  final String recommendation;
  final List<String> commonSymptoms;
  final List<String> effectiveStrategies;

  StressPattern({
    required this.triggerType,
    required this.avgStressLevel,
    required this.frequency,
    this.successRate = 0,
    required this.recommendation,
    this.commonSymptoms = const [],
    this.effectiveStrategies = const [],
  });

  String get triggerLabel => StressTriggerType.getLabel(triggerType);
  IconData get triggerIcon => StressTriggerType.getIcon(triggerType);

  Color get severityColor {
    if (avgStressLevel >= 7) return Colors.red;
    if (avgStressLevel >= 5) return Colors.orange;
    if (avgStressLevel >= 3) return Colors.yellow.shade700;
    return Colors.green;
  }
}

class StressSuggestion {
  final String title;
  final String description;
  final String icon;
  final String priority;
  final List<String> steps;

  StressSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    this.priority = 'normal',
    this.steps = const [],
  });

  static List<StressSuggestion> generateForLevel(int level) {
    if (level >= 8) {
      return [
        StressSuggestion(
          title: '立即减压',
          description: '您的压力水平很高，建议立即采取行动',
          icon: '🚨',
          priority: 'high',
          steps: [
            '找一个安静的地方深呼吸',
            '尝试5-5-5呼吸法（吸气5秒，屏气5秒，呼气5秒）',
            '考虑联系专业人士',
          ],
        ),
        StressSuggestion(
          title: '暂停所有非必要活动',
          description: '给自己一些空间来恢复',
          icon: '⏸️',
          priority: 'high',
          steps: [
            '推迟非紧急任务',
            '取消不必要的社交活动',
            '专注于休息和恢复',
          ],
        ),
      ];
    } else if (level >= 6) {
      return [
        StressSuggestion(
          title: '压力管理练习',
          description: '中高度压力，建议进行压力管理',
          icon: '🧘',
          priority: 'medium',
          steps: [
            '进行10分钟冥想或深呼吸',
            '站起来伸展身体',
            '短暂散步5-10分钟',
          ],
        ),
        StressSuggestion(
          title: '社交支持',
          description: '与信任的人分享您的感受',
          icon: '👥',
          priority: 'medium',
          steps: [
            '联系朋友或家人',
            '分享您的压力源',
            '寻求情感支持',
          ],
        ),
      ];
    } else if (level >= 4) {
      return [
        StressSuggestion(
          title: '日常压力预防',
          description: '中等压力，可以做一些预防措施',
          icon: '🌱',
          priority: 'normal',
          steps: [
            '保持规律作息',
            '适度运动',
            '记录压力日志',
          ],
        ),
      ];
    }
    return [
      StressSuggestion(
        title: '保持良好状态',
        description: '您的压力水平健康，继续保持',
        icon: '✨',
        priority: 'low',
        steps: [
          '维持当前的健康习惯',
          '定期记录压力水平',
          '培养兴趣爱好',
        ],
      ),
    ];
  }

  static List<StressSuggestion> generateForTriggerType(String triggerType, int avgStressLevel) {
    final List<StressSuggestion> suggestions = [];

    switch (triggerType) {
      case StressTriggerType.work:
        suggestions.add(StressSuggestion(
          title: '工作压力管理',
          description: '针对工作压力的建议',
          icon: '💼',
          priority: 'high',
          steps: [
            '列出任务优先级',
            '学会委托和拒绝',
            '设置明确的工作边界',
            '定期休息避免 burnout',
          ],
        ));
        break;
      case StressTriggerType.personal:
        suggestions.add(StressSuggestion(
          title: '个人生活平衡',
          description: '改善个人生活质量的建议',
          icon: '🏠',
          priority: 'medium',
          steps: [
            '保证充足睡眠',
            '培养兴趣爱好',
            '保持社交活动',
            '定期自我反思',
          ],
        ));
        break;
      case StressTriggerType.health:
        suggestions.add(StressSuggestion(
          title: '健康问题关注',
          description: '建议咨询医疗专业人士',
          icon: '🏥',
          priority: 'high',
          steps: [
            '预约体检',
            '记录症状变化',
            '保持健康饮食',
            '适度运动',
          ],
        ));
        break;
      case StressTriggerType.relationships:
        suggestions.add(StressSuggestion(
          title: '人际关系处理',
          description: '改善人际关系的策略',
          icon: '💬',
          priority: 'medium',
          steps: [
            '坦诚沟通感受',
            '设置健康边界',
            '寻求第三方帮助',
            '学习冲突解决技巧',
          ],
        ));
        break;
      case StressTriggerType.financial:
        suggestions.add(StressSuggestion(
          title: '财务压力缓解',
          description: '管理财务压力的方法',
          icon: '💰',
          priority: 'medium',
          steps: [
            '制定预算计划',
            '区分需要和想要',
            '寻求财务咨询',
            '建立应急基金',
          ],
        ));
        break;
    }

    return suggestions;
  }
}
