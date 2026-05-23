class SearchEnhancement {
  final int? id;
  final String query;
  final String? semanticExpansion;
  final int resultCount;
  final int? clickedRecordId;
  final String searchTime;

  SearchEnhancement({
    this.id,
    required this.query,
    this.semanticExpansion,
    this.resultCount = 0,
    this.clickedRecordId,
    required this.searchTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'semantic_expansion': semanticExpansion,
      'result_count': resultCount,
      'clicked_record_id': clickedRecordId,
      'search_time': searchTime,
    };
  }

  factory SearchEnhancement.fromMap(Map<String, dynamic> map) {
    return SearchEnhancement(
      id: map['id'],
      query: map['query'],
      semanticExpansion: map['semantic_expansion'],
      resultCount: map['result_count'] ?? 0,
      clickedRecordId: map['clicked_record_id'],
      searchTime: map['search_time'],
    );
  }

  SearchEnhancement copyWith({
    int? id,
    String? query,
    String? semanticExpansion,
    int? resultCount,
    int? clickedRecordId,
    String? searchTime,
  }) {
    return SearchEnhancement(
      id: id ?? this.id,
      query: query ?? this.query,
      semanticExpansion: semanticExpansion ?? this.semanticExpansion,
      resultCount: resultCount ?? this.resultCount,
      clickedRecordId: clickedRecordId ?? this.clickedRecordId,
      searchTime: searchTime ?? this.searchTime,
    );
  }
}