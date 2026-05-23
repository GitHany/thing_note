/// 语音结构化笔记模型
class VoiceStructuredNote {
  final int? id;
  final String title;
  final String rawText;
  final String? structuredContent; // JSON
  final List<String> keywords;
  final String? templateType;
  final int? linkedRecordId;
  final DateTime createdAt;

  VoiceStructuredNote({
    this.id,
    required this.title,
    required this.rawText,
    this.structuredContent,
    this.keywords = const [],
    this.templateType,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'raw_text': rawText,
      'structured_content': structuredContent,
      'keywords': keywords.join(','),
      'template_type': templateType,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VoiceStructuredNote.fromMap(Map<String, dynamic> map) {
    final keywordsStr = map['keywords'] as String? ?? '';
    return VoiceStructuredNote(
      id: map['id'] as int?,
      title: map['title'] as String,
      rawText: map['raw_text'] as String,
      structuredContent: map['structured_content'] as String?,
      keywords: keywordsStr.isEmpty ? [] : keywordsStr.split(','),
      templateType: map['template_type'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<StructuredSection> get sections {
    if (structuredContent == null) return [];
    try {
      final List<dynamic> list = structuredContent!.split('|||');
      return list.map((s) => StructuredSection.fromString(s)).toList();
    } catch (_) {
      return [];
    }
  }
}

/// 结构化分段
class VoiceSegment {
  final int? id;
  final int noteId;
  final double startTime;
  final double? endTime;
  final String text;
  final String? segmentType; // heading, content, list_item, question

  VoiceSegment({
    this.id,
    required this.noteId,
    required this.startTime,
    this.endTime,
    required this.text,
    this.segmentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'start_time': startTime,
      'end_time': endTime,
      'text': text,
      'segment_type': segmentType,
    };
  }

  factory VoiceSegment.fromMap(Map<String, dynamic> map) {
    return VoiceSegment(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      startTime: (map['start_time'] as num).toDouble(),
      endTime: (map['end_time'] as num?)?.toDouble(),
      text: map['text'] as String,
      segmentType: map['segment_type'] as String?,
    );
  }

  String get formattedDuration {
    if (endTime == null) return '';
    final duration = endTime! - startTime;
    final seconds = duration.toInt();
    return '${seconds}s';
  }
}

/// 结构化段落
class StructuredSection {
  final String type; // heading, content, list, todo
  final String content;
  final Map<String, dynamic>? metadata;

  StructuredSection({
    required this.type,
    required this.content,
    this.metadata,
  });

  factory StructuredSection.fromString(String str) {
    final parts = str.split(':::');
    final type = parts.isNotEmpty ? parts[0] : 'content';
    final content = parts.length > 1 ? parts[1] : str;
    return StructuredSection(
      type: type,
      content: content,
    );
  }

  @override
  String toString() => '$type:::$content';
}

/// 模板类型枚举
enum TemplateType {
  meeting('meeting', '会议纪要'),
  daily('daily', '每日总结'),
  idea('idea', '灵感记录'),
  todo('todo', '待办事项'),
  note('note', '普通笔记');

  final String value;
  final String label;

  const TemplateType(this.value, this.label);

  static TemplateType fromValue(String? value) {
    if (value == null) return TemplateType.note;
    return TemplateType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TemplateType.note,
    );
  }
}