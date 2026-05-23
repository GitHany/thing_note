import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_access/domain/quick_access_repository.dart';

// Quick access repository provider
final quickAccessRepositoryProvider = Provider<QuickAccessRepository>((ref) {
  return QuickAccessRepository();
});

// Quick access data provider
final quickAccessDataProvider = FutureProvider<QuickAccessData>((ref) async {
  final repo = ref.read(quickAccessRepositoryProvider);
  return repo.load();
});

// Streak providers
final currentStreakProvider = FutureProvider<int>((ref) async {
  final data = await ref.watch(quickAccessDataProvider.future);
  return data.currentStreak;
});

final longestStreakProvider = FutureProvider<int>((ref) async {
  final data = await ref.watch(quickAccessDataProvider.future);
  return data.longestStreak;
});

// Frequently used thing names provider
final frequentlyUsedThingNamesProvider = FutureProvider<List<int>>((ref) async {
  final data = await ref.watch(quickAccessDataProvider.future);
  return data.frequentlyUsedThingNameIds;
});

// Recent records provider
final recentRecordIdsProvider = FutureProvider<List<int>>((ref) async {
  final data = await ref.watch(quickAccessDataProvider.future);
  return data.recentRecordIds;
});