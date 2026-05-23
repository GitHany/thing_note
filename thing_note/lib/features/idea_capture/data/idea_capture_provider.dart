import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/idea_capture/data/idea_capture_repository.dart';
import 'package:thing_note/features/idea_capture/domain/idea_capture.dart';

final ideaCaptureRepositoryProvider = Provider((ref) => IdeaCaptureRepository(ref));

final ideaCaptureProvider = FutureProvider<List<IdeaCapture>>((ref) async {
  final repo = ref.read(ideaCaptureRepositoryProvider);
  return repo.getAllIdeas();
});

final unconvertedIdeasProvider = FutureProvider<List<IdeaCapture>>((ref) async {
  final repo = ref.read(ideaCaptureRepositoryProvider);
  return repo.getUnconvertedIdeas();
});

final ideaCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(ideaCaptureRepositoryProvider);
  return repo.getCategories();
});