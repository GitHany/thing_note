import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_checkin/data/location_checkin_repository.dart';
import 'package:thing_note/features/location_checkin/domain/location_checkin.dart';

final locationCheckinRepositoryProvider = Provider((ref) => LocationCheckinRepository(ref));

final allCheckinsProvider = FutureProvider<List<LocationCheckin>>((ref) async {
  final repo = ref.read(locationCheckinRepositoryProvider);
  return repo.getAllCheckins();
});

final recentCheckinsProvider = FutureProvider<List<LocationCheckin>>((ref) async {
  final repo = ref.read(locationCheckinRepositoryProvider);
  return repo.getRecentCheckins();
});

final placeStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(locationCheckinRepositoryProvider);
  return repo.getPlaceStats();
});