import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_search_enhance/domain/search_config.dart';
import 'package:thing_note/features/quick_search_enhance/data/search_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final quickSearchRepositoryProvider = FutureProvider<QuickSearchRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return QuickSearchRepository(db);
});

final searchHistoryProvider = FutureProvider<List<SearchHistoryEntry>>((ref) async {
  final repo = await ref.watch(quickSearchRepositoryProvider.future);
  return repo.getSearchHistory();
});

final savedSearchesProvider = FutureProvider<List<SavedSearch>>((ref) async {
  final repo = await ref.watch(quickSearchRepositoryProvider.future);
  return repo.getSavedSearches();
});

final searchResultsProvider = FutureProvider.family<List<EnhancedSearchResult>, (String, SearchFilter?)>((ref, params) async {
  final repo = await ref.watch(quickSearchRepositoryProvider.future);
  return repo.search(params.$1, filter: params.$2);
});

class QuickSearchNotifier extends StateNotifier<AsyncValue<List<EnhancedSearchResult>>> {
  QuickSearchNotifier() : super(const AsyncValue.data([]));

  Future<void> search(String query, {SearchFilter? filter}) async {
    if (query.isEmpty && (filter == null || !filter.hasActiveFilters)) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = const AsyncValue.data([]);
  }

  Future<void> saveCurrentSearch(String name) async {
    // Placeholder
  }

  Future<void> loadSavedSearch(int searchId) async {
    // Placeholder
  }

  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

final quickSearchNotifierProvider = StateNotifierProvider<QuickSearchNotifier, AsyncValue<List<EnhancedSearchResult>>>((ref) {
  return QuickSearchNotifier();
});