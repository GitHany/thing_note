import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/flashcard/domain/flashcard.dart';
import 'package:thing_note/features/flashcard/data/flashcard_repository.dart';

final flashcardListProvider = FutureProvider<List<Flashcard>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getAll();
});

final dueFlashcardsProvider = FutureProvider<List<Flashcard>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getDueForReview();
});

final flashcardCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(flashcardRepositoryProvider);
  return repo.getCategories();
});

class FlashcardNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
  final FlashcardRepository _repository;

  FlashcardNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFlashcards();
  }

  Future<void> loadFlashcards() async {
    state = const AsyncValue.loading();
    try {
      final flashcards = await _repository.getAll();
      state = AsyncValue.data(flashcards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFlashcard(Flashcard flashcard) async {
    await _repository.insert(flashcard);
    await loadFlashcards();
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _repository.update(flashcard);
    await loadFlashcards();
  }

  Future<void> deleteFlashcard(int id) async {
    await _repository.delete(id);
    await loadFlashcards();
  }

  Future<void> reviewFlashcard(Flashcard flashcard, int quality) async {
    final updated = flashcard.applyReview(quality);
    await _repository.update(updated);
    
    // Save review record
    await _repository.insertReview(FlashcardReview(
      flashcardId: flashcard.id!,
      reviewedAt: DateTime.now(),
      quality: quality,
      easeFactor: updated.easeFactor,
      intervalDays: updated.intervalDays,
    ));
    
    await loadFlashcards();
  }
}

final flashcardNotifierProvider = StateNotifierProvider<FlashcardNotifier, AsyncValue<List<Flashcard>>>((ref) {
  final repo = ref.watch(flashcardRepositoryProvider);
  return FlashcardNotifier(repo);
});