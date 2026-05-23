import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_smart/domain/smart_location.dart';
import 'package:thing_note/features/location_smart/data/smart_location_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartLocationRepositoryProvider = FutureProvider<SmartLocationRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return SmartLocationRepository(db);
});

final allSmartLocationsProvider = FutureProvider<List<SmartLocation>>((ref) async {
  final repo = await ref.watch(smartLocationRepositoryProvider.future);
  return repo.getAllLocations();
});

final favoriteSmartLocationsProvider = FutureProvider<List<SmartLocation>>((ref) async {
  final repo = await ref.watch(smartLocationRepositoryProvider.future);
  return repo.getFavoriteLocations();
});

final topSmartLocationsProvider = FutureProvider<List<SmartLocation>>((ref) async {
  final repo = await ref.watch(smartLocationRepositoryProvider.future);
  return repo.getTopLocations(limit: 10);
});

class SmartLocationNotifier extends StateNotifier<AsyncValue<List<SmartLocation>>> {
  SmartLocationNotifier() : super(const AsyncValue.data([]));

  Future<void> loadLocations() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createLocation(SmartLocation location) async {
    // Placeholder
  }

  Future<void> updateLocation(SmartLocation location) async {
    // Placeholder
  }

  Future<void> deleteLocation(int id) async {
    // Placeholder
  }

  Future<void> toggleFavorite(int id) async {
    // Placeholder
  }

  Future<void> recordVisit(int locationId, int durationSec) async {
    // Placeholder
  }
}

final smartLocationNotifierProvider = StateNotifierProvider<SmartLocationNotifier, AsyncValue<List<SmartLocation>>>((ref) {
  return SmartLocationNotifier();
});

/// Location search provider
final nearbyLocationProvider = FutureProvider.family<SmartLocation?, (double, double)>((ref, coords) async {
  final repo = await ref.watch(smartLocationRepositoryProvider.future);
  return repo.findNearbyLocation(coords.$1, coords.$2, 100);
});