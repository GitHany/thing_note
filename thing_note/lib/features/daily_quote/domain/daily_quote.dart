class DailyQuote {
  final int? id;
  final String quoteText;
  final String? author;
  final String category;
  final String? actionSuggestion;
  final bool isFavorite;
  final DateTime createdAt;

  DailyQuote({
    this.id,
    required this.quoteText,
    this.author,
    this.category = 'inspiration',
    this.actionSuggestion,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_text': quoteText,
      'author': author,
      'category': category,
      'action_suggestion': actionSuggestion,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyQuote.fromMap(Map<String, dynamic> map) {
    return DailyQuote(
      id: map['id'] as int?,
      quoteText: map['quote_text'] as String,
      author: map['author'] as String?,
      category: map['category'] as String? ?? 'inspiration',
      actionSuggestion: map['action_suggestion'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyQuote copyWith({
    int? id,
    String? quoteText,
    String? author,
    String? category,
    String? actionSuggestion,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return DailyQuote(
      id: id ?? this.id,
      quoteText: quoteText ?? this.quoteText,
      author: author ?? this.author,
      category: category ?? this.category,
      actionSuggestion: actionSuggestion ?? this.actionSuggestion,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}