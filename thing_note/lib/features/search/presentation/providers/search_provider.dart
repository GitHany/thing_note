import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search filters state
class SearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool hasPhotos;
  final bool hasAudio;
  final bool hasVideos;
  final bool hasDocuments;
  final bool? isFavorite;
  final int? tagId;
  final int? thingNameId;

  const SearchFilters({
    this.startDate,
    this.endDate,
    this.hasPhotos = false,
    this.hasAudio = false,
    this.hasVideos = false,
    this.hasDocuments = false,
    this.isFavorite,
    this.tagId,
    this.thingNameId,
  });

  SearchFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? hasPhotos,
    bool? hasAudio,
    bool? hasVideos,
    bool? hasDocuments,
    bool? isFavorite,
    int? tagId,
    int? thingNameId,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearTagId = false,
    bool clearThingNameId = false,
  }) {
    return SearchFilters(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      hasPhotos: hasPhotos ?? this.hasPhotos,
      hasAudio: hasAudio ?? this.hasAudio,
      hasVideos: hasVideos ?? this.hasVideos,
      hasDocuments: hasDocuments ?? this.hasDocuments,
      isFavorite: isFavorite ?? this.isFavorite,
      tagId: clearTagId ? null : (tagId ?? this.tagId),
      thingNameId: clearThingNameId ? null : (thingNameId ?? this.thingNameId),
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      hasPhotos ||
      hasAudio ||
      hasVideos ||
      hasDocuments ||
      isFavorite != null ||
      tagId != null ||
      thingNameId != null;
}

final searchFiltersProvider = StateProvider<SearchFilters>((ref) => const SearchFilters());

// Search results provider with filters
final searchResultsProvider = FutureProvider<List<EpisodeRecord>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final repo = ref.watch(recordRepositoryProvider);

  List<EpisodeRecord> records;

  if (query.isEmpty && !filters.hasActiveFilters) {
    return [];
  }

  if (query.isNotEmpty) {
    records = await repo.search(query);
  } else {
    records = await repo.getAll();
  }

  // Apply filters
  return records.where((record) {
    // Date range filter
    if (filters.startDate != null && record.occurredAt.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null && record.occurredAt.isAfter(filters.endDate!)) {
      return false;
    }

    // Media type filters
    if (filters.hasPhotos && record.photoPaths.isEmpty) return false;
    if (filters.hasAudio && record.audioPaths.isEmpty) return false;
    if (filters.hasVideos && record.videoPaths.isEmpty) return false;
    if (filters.hasDocuments && record.documentPaths.isEmpty) return false;

    // Favorite filter
    if (filters.isFavorite == true && !record.isFavorite) return false;
    if (filters.isFavorite == false && record.isFavorite) return false;

    // Thing name filter
    if (filters.thingNameId != null && record.thingNameId != filters.thingNameId) {
      return false;
    }

    return true;
  }).toList();
});

// Search history
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]);

  void addSearch(String query) {
    if (query.isEmpty) return;
    final updated = [query, ...state.where((q) => q != query)].take(10).toList();
    state = updated;
  }

  void removeSearch(String query) {
    state = state.where((q) => q != query).toList();
  }

  void clearHistory() {
    state = [];
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

// Recent searches (quick access)
final recentSearchesProvider = Provider<List<String>>((ref) {
  return ref.watch(searchHistoryProvider);
});