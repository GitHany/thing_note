import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/custom_gesture/data/custom_gesture_repository.dart';
import 'package:thing_note/features/custom_gesture/domain/custom_gesture.dart';

final customGestureRepositoryProvider = Provider((ref) => CustomGestureRepository(ref));

final allGesturesProvider = FutureProvider<List<CustomGesture>>((ref) async {
  final repo = ref.read(customGestureRepositoryProvider);
  return repo.getAllGestures();
});

final enabledGesturesProvider = FutureProvider<List<CustomGesture>>((ref) async {
  final repo = ref.read(customGestureRepositoryProvider);
  return repo.getEnabledGestures();
});