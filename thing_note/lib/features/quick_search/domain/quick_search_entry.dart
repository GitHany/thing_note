class QuickSearchEntry {
  final int? id;
  final String query;
  final int resultCount;
  final DateTime searchedAt;

  QuickSearchEntry({
    this.id,
    required this.query,
    this.resultCount = 0,
    required this.searchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'query': query,
      'result_count': resultCount,
      'searched_at': searchedAt.toIso8601String(),
    };
  }

  factory QuickSearchEntry.fromMap(Map<String, dynamic> map) {
    return QuickSearchEntry(
      id: map['id'] as int?,
      query: map['query'] as String,
      resultCount: map['result_count'] as int? ?? 0,
      searchedAt: DateTime.parse(map['searched_at'] as String),
    );
  }
}