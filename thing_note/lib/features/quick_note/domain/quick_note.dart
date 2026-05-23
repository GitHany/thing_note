/// 快捷便签数据模型
class QuickNote {
  final int? id;
  final String content;
  final int color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickNote({
    this.id,
    required this.content,
    this.color = 0xFFFFFFFF,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  QuickNote copyWith({
    int? id,
    String? content,
    int? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickNote(
      id: id ?? this.id,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory QuickNote.fromMap(Map<String, dynamic> map) {
    return QuickNote(
      id: map['id'] as int?,
      content: map['content'] as String,
      color: map['color'] as int? ?? 0xFFFFFFFF,
      isPinned: (map['is_pinned'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 预设便签颜色
class QuickNoteColors {
  static const List<int> presets = [
    0xFFFFF9C4, // 黄色
    0xFFFFCCBC, // 桃色
    0xFFB2DFDB, // 青色
    0xFFBBDEFB, // 蓝色
    0xFFE1BEE7, // 紫色
    0xFFC8E6C9, // 绿色
  ];
}