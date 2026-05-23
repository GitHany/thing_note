import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

class LocationRoutine {
  final int id;
  final String locationName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String triggerType;
  final String routineAction;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final int triggerCount;
  final DateTime createdAt;

  LocationRoutine({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    required this.triggerType,
    required this.routineAction,
    this.isEnabled = true,
    this.lastTriggered,
    this.triggerCount = 0,
    required this.createdAt,
  });

  factory LocationRoutine.fromMap(Map<String, dynamic> map) {
    return LocationRoutine(
      id: map['id'] as int,
      locationName: map['location_name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 100,
      triggerType: map['trigger_type'] as String,
      routineAction: map['routine_action'] as String,
      isEnabled: (map['is_enabled'] as int?) == 1,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      triggerCount: map['trigger_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'trigger_type': triggerType,
      'routine_action': routineAction,
      'is_enabled': isEnabled ? 1 : 0,
      'last_triggered': lastTriggered?.toIso8601String(),
      'trigger_count': triggerCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

final locationRoutinesProvider = FutureProvider<List<LocationRoutine>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('location_routines', orderBy: 'trigger_count DESC');
  return results.map((m) => LocationRoutine.fromMap(m)).toList();
});

class LocationRoutineNotifier extends StateNotifier<AsyncValue<List<LocationRoutine>>> {
  final Ref ref;
  
  LocationRoutineNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadRoutines();
  }
  
  Future<void> _loadRoutines() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('location_routines', orderBy: 'trigger_count DESC');
      state = AsyncValue.data(results.map((m) => LocationRoutine.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addRoutine(String name, double lat, double lng, String trigger, String action) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('location_routines', {
      'location_name': name,
      'latitude': lat,
      'longitude': lng,
      'trigger_type': trigger,
      'routine_action': action,
      'is_enabled': 1,
      'trigger_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadRoutines();
  }
  
  Future<void> deleteRoutine(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('location_routines', where: 'id = ?', whereArgs: [id]);
    await _loadRoutines();
  }
}

final locationRoutineNotifierProvider =
    StateNotifierProvider<LocationRoutineNotifier, AsyncValue<List<LocationRoutine>>>((ref) {
  return LocationRoutineNotifier(ref);
});