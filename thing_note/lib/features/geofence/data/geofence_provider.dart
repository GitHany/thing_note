import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/geofence/domain/geofence.dart';
import 'package:thing_note/features/geofence/data/geofence_repository.dart';

final geofenceListProvider = FutureProvider<List<Geofence>>((ref) async {
  final repo = ref.watch(geofenceRepositoryProvider);
  return repo.getAll();
});

class GeofenceNotifier extends StateNotifier<AsyncValue<List<Geofence>>> {
  final GeofenceRepository _repository;

  GeofenceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGeofences();
  }

  Future<void> loadGeofences() async {
    state = const AsyncValue.loading();
    try {
      final geofences = await _repository.getAll();
      state = AsyncValue.data(geofences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGeofence(Geofence geofence) async {
    await _repository.insert(geofence);
    await loadGeofences();
  }

  Future<void> updateGeofence(Geofence geofence) async {
    await _repository.update(geofence);
    await loadGeofences();
  }

  Future<void> toggleGeofence(int id, bool enabled) async {
    final geofence = await _repository.getById(id);
    if (geofence != null) {
      await _repository.update(geofence.copyWith(isEnabled: enabled));
      await loadGeofences();
    }
  }

  Future<void> deleteGeofence(int id) async {
    await _repository.delete(id);
    await loadGeofences();
  }
}

final geofenceNotifierProvider = StateNotifierProvider<GeofenceNotifier, AsyncValue<List<Geofence>>>((ref) {
  final repo = ref.watch(geofenceRepositoryProvider);
  return GeofenceNotifier(repo);
});

final enabledGeofencesProvider = FutureProvider<List<Geofence>>((ref) async {
  final repo = ref.watch(geofenceRepositoryProvider);
  return repo.getEnabled();
});