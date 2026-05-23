import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_note_linking/data/note_link_repository.dart';
import 'package:thing_note/features/smart_note_linking/domain/note_link.dart';

final noteLinksProvider = FutureProvider.family<List<NoteLink>, int>((ref, recordId) async {
  final repository = ref.watch(noteLinkRepositoryProvider);
  return repository.getLinksForRecord(recordId);
});

final allLinksProvider = FutureProvider<List<NoteLink>>((ref) async {
  final repository = ref.watch(noteLinkRepositoryProvider);
  return repository.getAllLinks();
});

final suggestedLinksProvider = FutureProvider.family<List<NoteLink>, int>((ref, recordId) async {
  final repository = ref.watch(noteLinkRepositoryProvider);
  return repository.findSuggestedLinks(recordId, {});
});

class NoteLinkNotifier extends StateNotifier<AsyncValue<List<NoteLink>>> {
  final NoteLinkRepository _repository;
  final int? _recordId;

  NoteLinkNotifier(this._repository, this._recordId) : super(const AsyncValue.loading()) {
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final recordId = _recordId;
      final links = recordId != null
          ? await _repository.getLinksForRecord(recordId)
          : await _repository.getAllLinks();
      state = AsyncValue.data(links);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLink(NoteLink link) async {
    try {
      await _repository.insertLink(link);
      await _loadLinks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeLink(int id) async {
    try {
      await _repository.deleteLink(id);
      await _loadLinks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadLinks();
  }
}

final noteLinkNotifierProvider = StateNotifierProvider.family<NoteLinkNotifier, AsyncValue<List<NoteLink>>, int?>(
  (ref, recordId) => NoteLinkNotifier(ref.watch(noteLinkRepositoryProvider), recordId),
);