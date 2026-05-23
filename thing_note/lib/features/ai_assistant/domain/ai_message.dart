/// AI Assistant message model
class AiMessage {
  final int? id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final String? context;

  AiMessage({
    this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'context': context,
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      id: map['id'] as int?,
      content: map['content'] as String,
      isUser: (map['is_user'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      context: map['context'] as String?,
    );
  }
}

/// AI Assistant suggestion types
enum AiSuggestionType {
  summarize,
  categorize,
  tag,
  remind,
  analyze,
  custom,
}

/// AI Assistant suggestion
class AiSuggestion {
  final String title;
  final String description;
  final AiSuggestionType type;
  final Map<String, dynamic>? data;

  AiSuggestion({
    required this.title,
    required this.description,
    required this.type,
    this.data,
  });
}