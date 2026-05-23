import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/journal/domain/journal.dart';
import 'package:thing_note/features/journal/data/journal_repository.dart';

final journalListProvider = FutureProvider<List<Journal>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getAll();
});

final journalByDateProvider = FutureProvider.family<Journal?, String>((ref, date) async {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getByDate(date);
});

class JournalNotifier extends StateNotifier<AsyncValue<List<Journal>>> {
  final JournalRepository _repository;

  JournalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadJournals();
  }

  Future<void> loadJournals() async {
    state = const AsyncValue.loading();
    try {
      final journals = await _repository.getAll();
      state = AsyncValue.data(journals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addJournal(Journal journal) async {
    await _repository.insert(journal);
    await loadJournals();
  }

  Future<void> updateJournal(Journal journal) async {
    await _repository.update(journal);
    await loadJournals();
  }

  Future<void> deleteJournal(int id) async {
    await _repository.delete(id);
    await loadJournals();
  }
}

final journalNotifierProvider = StateNotifierProvider<JournalNotifier, AsyncValue<List<Journal>>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repo);
});