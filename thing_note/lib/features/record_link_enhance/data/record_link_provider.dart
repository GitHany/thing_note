import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_link_enhance/domain/record_link.dart';
import 'package:thing_note/features/record_link_enhance/data/record_link_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final recordLinkRepositoryProvider = FutureProvider<RecordLinkRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return RecordLinkRepository(db);
});

final recordLinksProvider = FutureProvider.family<List<EnhancedRecordLink>, int>((ref, recordId) async {
  final repo = await ref.watch(recordLinkRepositoryProvider.future);
  return repo.getLinksForRecord(recordId);
});

final linkSuggestionsProvider = FutureProvider.family<List<LinkSuggestion>, int>((ref, recordId) async {
  final repo = await ref.watch(recordLinkRepositoryProvider.future);
  return repo.suggestLinks(recordId);
});

final linkStatsProvider = FutureProvider<LinkStats>((ref) async {
  final repo = await ref.watch(recordLinkRepositoryProvider.future);
  return repo.getStats();
});

class RecordLinkNotifier extends StateNotifier<AsyncValue<List<EnhancedRecordLink>>> {
  RecordLinkNotifier() : super(const AsyncValue.data([]));

  Future<void> loadLinks() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createLink(int targetRecordId, {String linkType = 'related', String? note}) async {
    // Placeholder
  }

  Future<void> deleteLink(int id) async {
    // Placeholder
  }
}

final recordLinkNotifierProvider = StateNotifierProvider<RecordLinkNotifier, AsyncValue<List<EnhancedRecordLink>>>((ref) {
  return RecordLinkNotifier();
});