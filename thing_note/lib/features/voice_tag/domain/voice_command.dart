/// 语音命令数据模型
class VoiceCommand {
  final int? id;
  final String command;
  final String intent;
  final double confidence;
  final DateTime executedAt;

  const VoiceCommand({
    this.id,
    required this.command,
    required this.intent,
    this.confidence = 1.0,
    required this.executedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'command': command,
      'intent': intent,
      'confidence': confidence,
      'executed_at': executedAt.toIso8601String(),
    };
  }

  factory VoiceCommand.fromMap(Map<String, dynamic> map) {
    return VoiceCommand(
      id: map['id'] as int?,
      command: map['command'] as String,
      intent: map['intent'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      executedAt: DateTime.parse(map['executed_at'] as String),
    );
  }
}

/// 语音识别结果
class VoiceRecognitionResult {
  final String text;
  final double confidence;
  final List<String> keywords;
  final String? suggestedTag;

  const VoiceRecognitionResult({
    required this.text,
    this.confidence = 1.0,
    this.keywords = const [],
    this.suggestedTag,
  });
}

/// 预设语音命令
class CommandIntent {
  static const createRecord = 'create_record';
  static const addTag = 'add_tag';
  static const search = 'search';
  static const timer = 'timer';
  static const mood = 'mood';
  static const unknown = 'unknown';

  static String parseIntent(String command) {
    final lower = command.toLowerCase();
    if (lower.contains('记录') || lower.contains('创建') || lower.contains('新建')) {
      return createRecord;
    }
    if (lower.contains('标签') || lower.contains('标记')) {
      return addTag;
    }
    if (lower.contains('搜索') || lower.contains('查找')) {
      return search;
    }
    if (lower.contains('计时') || lower.contains('定时')) {
      return timer;
    }
    if (lower.contains('心情') || lower.contains('情绪')) {
      return mood;
    }
    return unknown;
  }

  static String getIntentDescription(String intent) {
    switch (intent) {
      case createRecord:
        return '创建新记录';
      case addTag:
        return '添加标签';
      case search:
        return '搜索记录';
      case timer:
        return '启动计时器';
      case mood:
        return '记录心情';
      default:
        return '未知命令';
    }
  }
}