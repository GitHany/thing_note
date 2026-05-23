import 'dart:convert' as convert;

/// Search filter options
class SearchFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> thingNameIds;
  final List<String> tags;
  final bool? hasPhotos;
  final bool? hasAudio;
  final bool? hasVideo;
  final bool? hasLocation;
  final bool? isFavorite;
  final double? minDuration;
  final double? maxDuration;

  SearchFilter({
    this.startDate,
    this.endDate,
    this.thingNameIds = const [],
    this.tags = const [],
    this.hasPhotos,
    this.hasAudio,
    this.hasVideo,
    this.hasLocation,
    this.isFavorite,
    this.minDuration,
    this.maxDuration,
  });

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      thingNameIds.isNotEmpty ||
      tags.isNotEmpty ||
      hasPhotos != null ||
      hasAudio != null ||
      hasVideo != null ||
      hasLocation != null ||
      isFavorite != null ||
      minDuration != null ||
      maxDuration != null;

  Map<String, dynamic> toMap() {
    return {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'thing_name_ids': thingNameIds.join(','),
      'tags': tags.join(','),
      'has_photos': hasPhotos,
      'has_audio': hasAudio,
      'has_video': hasVideo,
      'has_location': hasLocation,
      'is_favorite': isFavorite,
      'min_duration': minDuration,
      'max_duration': maxDuration,
    };
  }
}

/// Search result with highlighting
class EnhancedSearchResult {
  final int recordId;
  final String note;
  final String? highlightedNote;
  final DateTime occurredAt;
  final int? thingNameId;
  final String? thingName;
  final List<String> tags;
  final bool hasPhotos;
  final bool hasAudio;
  final bool hasVideo;
  final bool hasLocation;
  final bool isFavorite;
  final double relevanceScore;

  EnhancedSearchResult({
    required this.recordId,
    required this.note,
    this.highlightedNote,
    required this.occurredAt,
    this.thingNameId,
    this.thingName,
    this.tags = const [],
    this.hasPhotos = false,
    this.hasAudio = false,
    this.hasVideo = false,
    this.hasLocation = false,
    this.isFavorite = false,
    this.relevanceScore = 0,
  });
}

/// Saved search query
class SavedSearch {
  final int? id;
  final String name;
  final String query;
  final SearchFilter? filter;
  final int useCount;
  final DateTime createdAt;

  SavedSearch({
    this.id,
    required this.name,
    required this.query,
    this.filter,
    this.useCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'query': query,
      'filter': filter != null ? convert.jsonEncode(filter!.toMap()) : null,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    SearchFilter? filter;
    final filterJson = map['filter'] as String?;
    if (filterJson != null) {
      try {
        final filterMap = convert.jsonDecode(filterJson) as Map<String, dynamic>;
        filter = SearchFilter(
          startDate: filterMap['start_date'] != null ? DateTime.parse(filterMap['start_date']) : null,
          endDate: filterMap['end_date'] != null ? DateTime.parse(filterMap['end_date']) : null,
          thingNameIds: (filterMap['thing_name_ids'] as String?)?.split(',').where((s) => s.isNotEmpty).map(int.parse).toList() ?? [],
          tags: (filterMap['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        );
      } catch (_) {}
    }

    return SavedSearch(
      id: map['id'] as int?,
      name: map['name'] as String,
      query: map['query'] as String,
      filter: filter,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Search history entry
class SearchHistoryEntry {
  final String query;
  final DateTime searchedAt;
  final int resultCount;

  SearchHistoryEntry({
    required this.query,
    required this.searchedAt,
    this.resultCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'searched_at': searchedAt.toIso8601String(),
      'result_count': resultCount,
    };
  }

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      query: map['query'] as String,
      searchedAt: DateTime.parse(map['searched_at'] as String),
      resultCount: map['result_count'] as int? ?? 0,
    );
  }
}