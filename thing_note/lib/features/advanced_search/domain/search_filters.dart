/// Advanced search filter options
class SearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> thingNameIds;
  final List<int> tagIds;
  final int? minDuration;
  final int? maxDuration;
  final bool? hasPhoto;
  final bool? hasAudio;
  final bool? hasVideo;
  final bool? hasDocument;
  final bool? hasLocation;
  final bool? isFavorite;
  final List<String> keywords;

  SearchFilters({
    this.startDate,
    this.endDate,
    this.thingNameIds = const [],
    this.tagIds = const [],
    this.minDuration,
    this.maxDuration,
    this.hasPhoto,
    this.hasAudio,
    this.hasVideo,
    this.hasDocument,
    this.hasLocation,
    this.isFavorite,
    this.keywords = const [],
  });

  bool get hasFilters =>
      startDate != null ||
      endDate != null ||
      thingNameIds.isNotEmpty ||
      tagIds.isNotEmpty ||
      minDuration != null ||
      maxDuration != null ||
      hasPhoto != null ||
      hasAudio != null ||
      hasVideo != null ||
      hasDocument != null ||
      hasLocation != null ||
      isFavorite != null ||
      keywords.isNotEmpty;

  SearchFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<int>? thingNameIds,
    List<int>? tagIds,
    int? minDuration,
    int? maxDuration,
    bool? hasPhoto,
    bool? hasAudio,
    bool? hasVideo,
    bool? hasDocument,
    bool? hasLocation,
    bool? isFavorite,
    List<String>? keywords,
  }) {
    return SearchFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      thingNameIds: thingNameIds ?? this.thingNameIds,
      tagIds: tagIds ?? this.tagIds,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      hasAudio: hasAudio ?? this.hasAudio,
      hasVideo: hasVideo ?? this.hasVideo,
      hasDocument: hasDocument ?? this.hasDocument,
      hasLocation: hasLocation ?? this.hasLocation,
      isFavorite: isFavorite ?? this.isFavorite,
      keywords: keywords ?? this.keywords,
    );
  }

  SearchFilters clear() {
    return SearchFilters();
  }

  Map<String, dynamic> toQueryString() {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (thingNameIds.isNotEmpty) {
      params['thing_names'] = thingNameIds.join(',');
    }
    if (tagIds.isNotEmpty) {
      params['tags'] = tagIds.join(',');
    }
    if (minDuration != null) {
      params['min_duration'] = minDuration.toString();
    }
    if (maxDuration != null) {
      params['max_duration'] = maxDuration.toString();
    }
    if (hasPhoto != null) params['has_photo'] = hasPhoto.toString();
    if (hasAudio != null) params['has_audio'] = hasAudio.toString();
    if (hasVideo != null) params['has_video'] = hasVideo.toString();
    if (hasDocument != null) params['has_document'] = hasDocument.toString();
    if (hasLocation != null) params['has_location'] = hasLocation.toString();
    if (isFavorite != null) params['is_favorite'] = isFavorite.toString();
    if (keywords.isNotEmpty) {
      params['keywords'] = keywords.join(' ');
    }
    return params;
  }
}

/// Search result with highlighted text
class SearchResult {
  final int recordId;
  final String note;
  final Map<String, List<(int, int)>> highlights;
  final double relevance;

  SearchResult({
    required this.recordId,
    required this.note,
    this.highlights = const {},
    this.relevance = 0.0,
  });
}

/// Search history entry
class SearchHistoryEntry {
  final int? id;
  final String query;
  final int resultCount;
  final DateTime searchedAt;

  SearchHistoryEntry({
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

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      id: map['id'] as int?,
      query: map['query'] as String,
      resultCount: map['result_count'] as int? ?? 0,
      searchedAt: DateTime.parse(map['searched_at'] as String),
    );
  }
}

/// Saved search filter
class SavedFilter {
  final int? id;
  final String name;
  final SearchFilters filters;
  final DateTime createdAt;

  SavedFilter({
    this.id,
    required this.name,
    required this.filters,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'filters_json': _encodeFilters(filters),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedFilter.fromMap(Map<String, dynamic> map) {
    return SavedFilter(
      id: map['id'] as int?,
      name: map['name'] as String,
      filters: _decodeFilters(map['filters_json'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String _encodeFilters(SearchFilters filters) {
    // Simplified JSON encoding
    final parts = <String>[];
    if (filters.startDate != null) {
      parts.add('startDate:${filters.startDate!.toIso8601String()}');
    }
    if (filters.endDate != null) {
      parts.add('endDate:${filters.endDate!.toIso8601String()}');
    }
    if (filters.thingNameIds.isNotEmpty) {
      parts.add('thingNames:${filters.thingNameIds.join(',')}');
    }
    if (filters.tagIds.isNotEmpty) {
      parts.add('tags:${filters.tagIds.join(',')}');
    }
    if (filters.minDuration != null) {
      parts.add('minDuration:${filters.minDuration}');
    }
    if (filters.maxDuration != null) {
      parts.add('maxDuration:${filters.maxDuration}');
    }
    if (filters.hasPhoto != null) parts.add('hasPhoto:${filters.hasPhoto}');
    if (filters.hasAudio != null) parts.add('hasAudio:${filters.hasAudio}');
    if (filters.hasVideo != null) parts.add('hasVideo:${filters.hasVideo}');
    if (filters.hasDocument != null) parts.add('hasDoc:${filters.hasDocument}');
    if (filters.hasLocation != null) parts.add('hasLoc:${filters.hasLocation}');
    if (filters.isFavorite != null) parts.add('fav:${filters.isFavorite}');
    return parts.join(';');
  }

  static SearchFilters _decodeFilters(String encoded) {
    final filters = SearchFilters();
    final parts = encoded.split(';');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length != 2) continue;
      switch (kv[0]) {
        case 'startDate':
          // Parse date
          break;
        case 'endDate':
          // Parse date
          break;
        case 'thingNames':
          // Parse IDs
          break;
        // ... other cases
      }
    }
    return filters;
  }
}