import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/batch_tag/domain/batch_tag.dart';
import 'package:thing_note/features/batch_tag/data/batch_tag_repository.dart';

class BatchTagState {
  final List<int> selectedRecordIds;
  final List<String> currentTags;
  final List<String> suggestedTags;
  final bool isLoading;
  final String? error;

  BatchTagState({
    this.selectedRecordIds = const [],
    this.currentTags = const [],
    this.suggestedTags = const [],
    this.isLoading = false,
    this.error,
  });

  BatchTagState copyWith({
    List<int>? selectedRecordIds,
    List<String>? currentTags,
    List<String>? suggestedTags,
    bool? isLoading,
    String? error,
  }) {
    return BatchTagState(
      selectedRecordIds: selectedRecordIds ?? this.selectedRecordIds,
      currentTags: currentTags ?? this.currentTags,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BatchTagNotifier extends StateNotifier<BatchTagState> {
  final BatchTagRepository _repository;

  BatchTagNotifier(this._repository) : super(BatchTagState());

  Future<void> loadTagsForRecords(List<int> recordIds) async {
    state = state.copyWith(isLoading: true, selectedRecordIds: recordIds);
    try {
      final tagsMap = await _repository.getRecordTags(recordIds);
      final allTags = <String>{};
      for (final tags in tagsMap.values) {
        allTags.addAll(tags);
      }
      state = state.copyWith(
        currentTags: allTags.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addTags(List<String> tags) async {
    if (state.selectedRecordIds.isEmpty) return;
    try {
      await _repository.addTagsToRecords(state.selectedRecordIds, tags);
      state = state.copyWith(
        currentTags: {...state.currentTags, ...tags}.toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTags(List<String> tags) async {
    if (state.selectedRecordIds.isEmpty) return;
    try {
      await _repository.removeTagsFromRecords(state.selectedRecordIds, tags);
      state = state.copyWith(
        currentTags: state.currentTags.where((t) => !tags.contains(t)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> replaceTags(List<String> newTags) async {
    if (state.selectedRecordIds.isEmpty) return;
    try {
      await _repository.replaceTagsForRecords(state.selectedRecordIds, newTags);
      state = state.copyWith(currentTags: newTags);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchSuggestions(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestedTags: []);
      return;
    }
    try {
      final suggestions = await _repository.getSuggestedTags(query);
      state = state.copyWith(suggestedTags: suggestions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final batchTagNotifierProvider = StateNotifierProvider<BatchTagNotifier, BatchTagState>((ref) {
  final repository = ref.watch(batchTagRepositoryProvider);
  return BatchTagNotifier(repository);
});

final tagStatisticsProvider = FutureProvider<List<TagStatistics>>((ref) async {
  final repo = ref.watch(batchTagRepositoryProvider);
  return repo.getTagStatistics();
});
