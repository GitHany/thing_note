import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_challenge/data/habit_challenge_repository.dart';
import 'package:thing_note/features/habit_challenge/domain/habit_challenge.dart';

final habitChallengeRepositoryProvider = Provider((ref) => HabitChallengeRepository(ref));

final allChallengesProvider = FutureProvider<List<HabitChallenge>>((ref) async {
  final repo = ref.read(habitChallengeRepositoryProvider);
  return repo.getAllChallenges();
});

final activeChallengesProvider = FutureProvider<List<HabitChallenge>>((ref) async {
  final repo = ref.read(habitChallengeRepositoryProvider);
  return repo.getActiveChallenges();
});