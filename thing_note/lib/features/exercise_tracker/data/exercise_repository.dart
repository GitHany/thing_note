import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Exercise record model
class ExerciseRecord {
  final int? id;
  final String exerciseType;
  final int durationMinutes;
  final int caloriesBurned;
  final double distanceKm;
  final double? avgPace;
  final int? avgHeartRate;
  final String? gpsTrack;
  final DateTime occurredAt;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  const ExerciseRecord({
    this.id,
    required this.exerciseType,
    required this.durationMinutes,
    this.caloriesBurned = 0,
    this.distanceKm = 0,
    this.avgPace,
    this.avgHeartRate,
    this.gpsTrack,
    required this.occurredAt,
    this.linkedRecordId,
    this.note,
    required this.createdAt,
  });

  ExerciseRecord copyWith({
    int? id,
    String? exerciseType,
    int? durationMinutes,
    int? caloriesBurned,
    double? distanceKm,
    double? avgPace,
    int? avgHeartRate,
    String? gpsTrack,
    DateTime? occurredAt,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return ExerciseRecord(
      id: id ?? this.id,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceKm: distanceKm ?? this.distanceKm,
      avgPace: avgPace ?? this.avgPace,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      gpsTrack: gpsTrack ?? this.gpsTrack,
      occurredAt: occurredAt ?? this.occurredAt,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_type': exerciseType,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'distance_km': distanceKm,
      'avg_pace': avgPace,
      'avg_heart_rate': avgHeartRate,
      'gps_track': gpsTrack,
      'occurred_at': occurredAt.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      id: map['id'] as int?,
      exerciseType: map['exercise_type'] as String,
      durationMinutes: map['duration_minutes'] as int,
      caloriesBurned: map['calories_burned'] as int? ?? 0,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
      avgPace: map['avg_pace'] as double?,
      avgHeartRate: map['avg_heart_rate'] as int?,
      gpsTrack: map['gps_track'] as String?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// Exercise type model
class ExerciseType {
  final int? id;
  final String name;
  final String? icon;
  final String? color;
  final double caloriesPerMinute;
  final DateTime createdAt;

  const ExerciseType({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.caloriesPerMinute = 5.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'calories_per_minute': caloriesPerMinute,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExerciseType.fromMap(Map<String, dynamic> map) {
    return ExerciseType(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      caloriesPerMinute: (map['calories_per_minute'] as num?)?.toDouble() ?? 5.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// Repository provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ExerciseRepository(dbAsync);
});

final exerciseRecordsProvider = StateNotifierProvider<ExerciseRecordsNotifier, AsyncValue<List<ExerciseRecord>>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExerciseRecordsNotifier(repository);
});

final exerciseTypesProvider = Provider<AsyncValue<List<ExerciseType>>>((ref) {
  final records = ref.watch(exerciseRecordsProvider);
  return records.whenData((_) => _defaultExerciseTypes);
});

final _defaultExerciseTypes = [
  ExerciseType(name: '跑步', icon: '🏃', color: '#4CAF50', caloriesPerMinute: 10.0, createdAt: DateTime.now()),
  ExerciseType(name: '骑行', icon: '🚴', color: '#2196F3', caloriesPerMinute: 8.0, createdAt: DateTime.now()),
  ExerciseType(name: '游泳', icon: '🏊', color: '#00BCD4', caloriesPerMinute: 9.0, createdAt: DateTime.now()),
  ExerciseType(name: '健身', icon: '💪', color: '#FF9800', caloriesPerMinute: 7.0, createdAt: DateTime.now()),
  ExerciseType(name: '瑜伽', icon: '🧘', color: '#9C27B0', caloriesPerMinute: 4.0, createdAt: DateTime.now()),
  ExerciseType(name: '走路', icon: '🚶', color: '#795548', caloriesPerMinute: 5.0, createdAt: DateTime.now()),
  ExerciseType(name: '球类', icon: '⚽', color: '#F44336', caloriesPerMinute: 8.0, createdAt: DateTime.now()),
  ExerciseType(name: '跳舞', icon: '💃', color: '#E91E63', caloriesPerMinute: 7.0, createdAt: DateTime.now()),
];

class ExerciseRepository {
  final AsyncValue<Database> _dbAsync;

  ExerciseRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertExercise(ExerciseRecord record) async {
    final db = await _db;
    return db.insert('exercise_records', record.toMap());
  }

  Future<int> updateExercise(ExerciseRecord record) async {
    final db = await _db;
    return db.update(
      'exercise_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await _db;
    return db.delete('exercise_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExerciseRecord>> getAllExercises() async {
    final db = await _db;
    final maps = await db.query('exercise_records', orderBy: 'occurred_at DESC');
    return maps.map((m) => ExerciseRecord.fromMap(m)).toList();
  }

  Future<List<ExerciseRecord>> getExercisesByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'exercise_records',
      where: 'occurred_at >= ? AND occurred_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'occurred_at DESC',
    );
    return maps.map((m) => ExerciseRecord.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final exercises = await getExercisesByDateRange(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
      now,
    );

    int totalMinutes = 0;
    int totalCalories = 0;
    double totalDistance = 0;

    for (final e in exercises) {
      totalMinutes += e.durationMinutes;
      totalCalories += e.caloriesBurned;
      totalDistance += e.distanceKm;
    }

    return {
      'total_exercises': exercises.length,
      'total_minutes': totalMinutes,
      'total_calories': totalCalories,
      'total_distance': totalDistance,
    };
  }
}

class ExerciseRecordsNotifier extends StateNotifier<AsyncValue<List<ExerciseRecord>>> {
  final ExerciseRepository _repository;

  ExerciseRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExercises();
  }

  Future<void> loadExercises() async {
    state = const AsyncValue.loading();
    try {
      final exercises = await _repository.getAllExercises();
      state = AsyncValue.data(exercises);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExercise(ExerciseRecord record) async {
    try {
      await _repository.insertExercise(record);
      await loadExercises();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExercise(int id) async {
    try {
      await _repository.deleteExercise(id);
      await loadExercises();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}