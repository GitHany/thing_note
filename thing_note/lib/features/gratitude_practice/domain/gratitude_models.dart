// Gratitude Practice feature
// Version: 1.0
// Description: 每日感恩练习，记录感恩事项，提升幸福感

class GratitudeEntry {
  final int? id;
  final String date; // YYYY-MM-DD
  final String content;
  final String? mood; // before, after
  final int? moodLevel; // 1-5
  final List<String> gratitudeItems;
  final String? note;
  final String? createdAt;

  GratitudeEntry({
    this.id,
    required this.date,
    required this.content,
    this.mood,
    this.moodLevel,
    this.gratitudeItems = const [],
    this.note,
    this.createdAt,
  });

  factory GratitudeEntry.fromMap(Map<String, dynamic> map) {
    List<String> items = [];
    if (map['gratitude_items'] != null) {
      try {
        items = List<String>.from(map['gratitude_items'] as List);
      } catch (_) {
        // Handle JSON parse error
      }
    }
    
    return GratitudeEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String,
      mood: map['mood'] as String?,
      moodLevel: map['mood_level'] as int?,
      gratitudeItems: items,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'content': content,
      'mood': mood,
      'mood_level': moodLevel,
      'gratitude_items': gratitudeItems.join(','),
      'note': note,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  GratitudeEntry copyWith({
    int? id,
    String? date,
    String? content,
    String? mood,
    int? moodLevel,
    List<String>? gratitudeItems,
    String? note,
    String? createdAt,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      moodLevel: moodLevel ?? this.moodLevel,
      gratitudeItems: gratitudeItems ?? this.gratitudeItems,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GratitudePrompt {
  final String id;
  final String prompt;
  final String category; // person, health, work, life, other

  const GratitudePrompt({
    required this.id,
    required this.prompt,
    required this.category,
  });
  
  static const List<GratitudePrompt> defaultPrompts = [
    GratitudePrompt(id: '1', prompt: '今天最值得感恩的一件事是什么？', category: 'life'),
    GratitudePrompt(id: '2', prompt: '你想要感谢的人是谁？为什么？', category: 'person'),
    GratitudePrompt(id: '3', prompt: '今天有什么让你感到幸福的瞬间？', category: 'life'),
    GratitudePrompt(id: '4', prompt: '你最感激自己的哪一点？', category: 'self'),
    GratitudePrompt(id: '5', prompt: '过去一周有没有人帮助过你？', category: 'person'),
    GratitudePrompt(id: '6', prompt: '今天有什么健康方面的进展？', category: 'health'),
    GratitudePrompt(id: '7', prompt: '工作中有什么值得感恩的？', category: 'work'),
    GratitudePrompt(id: '8', prompt: '你拥有什么别人可能没有的？', category: 'self'),
    GratitudePrompt(id: '9', prompt: '今天天气怎么样？有什么值得感恩的？', category: 'life'),
    GratitudePrompt(id: '10', prompt: '你最亲近的家人是谁？感恩他们什么？', category: 'person'),
  ];
}