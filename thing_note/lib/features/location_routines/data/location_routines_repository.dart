import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/location_routines/domain/location_routine.dart';

final locationRoutinesRepositoryProvider = Provider<LocationRoutinesRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return LocationRoutinesRepository(dbAsync);
});

final locationRoutinesProvider = StateNotifierProvider<LocationRoutinesNotifier, AsyncValue<List<LocationRoutine>>>((ref) {
  final repository = ref.watch(locationRoutinesRepositoryProvider);
  return LocationRoutinesNotifier(repository);
});

final currentLocationRoutineProvider = StateProvider<LocationRoutine?>((ref) => null);

class LocationRoutinesRepository {
  final AsyncValue<Database> _dbAsync;

  LocationRoutinesRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRoutine(LocationRoutine routine) async {
    final db = await _db;
    return db.insert('location_routines', routine.toMap());
  }

  Future<int> updateRoutine(LocationRoutine routine) async {
    final db = await _db;
    return db.update('location_routines', routine.toMap(), where: 'id = ?', whereArgs: [routine.id]);
  }

  Future<int> deleteRoutine(int id) async {
    final db = await _db;
    return db.delete('location_routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LocationRoutine>> getAllRoutines() async {
    final db = await _db;
    final maps = await db.query('location_routines', orderBy: 'created_at DESC');
    return maps.map((m) => LocationRoutine.fromMap(m)).toList();
  }

  Future<List<LocationRoutine>> getAutoDetectRoutines() async {
    final db = await _db;
    final maps = await db.query(
      'location_routines',
      where: 'is_auto_detect = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => LocationRoutine.fromMap(m)).toList();
  }

  Future<LocationRoutine?> getRoutineByType(String type) async {
    final db = await _db;
    final maps = await db.query(
      'location_routines',
      where: 'location_type = ?',
      whereArgs: [type],
    );
    if (maps.isEmpty) return null;
    return LocationRoutine.fromMap(maps.first);
  }

  Future<LocationRoutine?> getNearbyRoutine(double lat, double lng) async {
    await _db;
    final routines = await getAutoDetectRoutines();
    
    for (final routine in routines) {
      if (routine.latitude != null && routine.longitude != null) {
        final distance = _calculateDistance(lat, lng, routine.latitude!, routine.longitude!);
        if (distance <= routine.radiusMeters) {
          return routine;
        }
      }
    }
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _simpleAtan2(y, x);

  double _taylorSin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x, term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1, term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _simpleAtan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.141592653589793 / 2 - _atan(1 / x);
    }
    double result = x, term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalRoutines = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM location_routines'),
    ) ?? 0;
    
    final autoDetectCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM location_routines WHERE is_auto_detect = 1'),
    ) ?? 0;
    
    final typeDistribution = <String, int>{};
    for (final type in LocationRoutine.locationTypes) {
      typeDistribution[type] = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM location_routines WHERE location_type = ?',
          [type],
        ),
      ) ?? 0;
    }
    
    return {
      'total_routines': totalRoutines,
      'auto_detect_count': autoDetectCount,
      'type_distribution': typeDistribution,
    };
  }
}

class LocationRoutinesNotifier extends StateNotifier<AsyncValue<List<LocationRoutine>>> {
  final LocationRoutinesRepository _repository;

  LocationRoutinesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    state = const AsyncValue.loading();
    try {
      final routines = await _repository.getAllRoutines();
      state = AsyncValue.data(routines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRoutine(LocationRoutine routine) async {
    try {
      await _repository.insertRoutine(routine);
      await loadRoutines();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRoutine(LocationRoutine routine) async {
    try {
      await _repository.updateRoutine(routine);
      await loadRoutines();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRoutine(int id) async {
    try {
      await _repository.deleteRoutine(id);
      await loadRoutines();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}