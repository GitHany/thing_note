// Personal OKR Provider
// Version: 1.0

import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/personal_okr/domain/okr_models.dart';

// Current quarter OKR list provider
final okrListProvider = FutureProvider<List<OkrWithKeyResults>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final quarter = ((now.month - 1) ~/ 3) + 1;
  
  final objectives = await db.query(
    'okr_objectives',
    where: 'quarter = ? AND year = ? AND status != ?',
    whereArgs: [quarter, now.year, 'cancelled'],
    orderBy: 'created_at DESC',
  );
  
  final List<OkrWithKeyResults> result = [];
  for (final obj in objectives) {
    final objective = OkrObjective.fromMap(obj);
    final keyResults = await db.query(
      'okr_key_results',
      where: 'objective_id = ?',
      whereArgs: [objective.id],
      orderBy: 'sort_order ASC',
    );
    result.add(OkrWithKeyResults(
      objective: objective,
      keyResults: keyResults.map((kr) => OkrKeyResult.fromMap(kr)).toList(),
    ));
  }
  
  return result;
});

// All objectives provider (for history)
final allOkrProvider = FutureProvider<List<OkrObjective>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final List<Map<String, dynamic>> maps = await db.query(
    'okr_objectives',
    orderBy: 'year DESC, quarter DESC, created_at DESC',
  );
  return maps.map((map) => OkrObjective.fromMap(map)).toList();
});

// Quarterly summary provider
final okrQuarterSummaryProvider = FutureProvider.family<OkrQuarterSummary, (int, int)>((ref, params) async {
  final (quarter, year) = params;
  final db = await ref.watch(databaseProvider.future);
  
  final objectives = await db.query(
    'okr_objectives',
    where: 'quarter = ? AND year = ?',
    whereArgs: [quarter, year],
  );
  
  final int totalObjectives = objectives.length;
  final int completedObjectives = objectives.where((o) => o['status'] == 'completed').length;
  double avgProgress = 0;
  
  if (objectives.isNotEmpty) {
    double sum = 0;
    for (final o in objectives) {
      sum += (o['progress'] as num?)?.toDouble() ?? 0;
    }
    avgProgress = sum / objectives.length;
  }
  
  return OkrQuarterSummary(
    quarter: quarter,
    year: year,
    totalObjectives: totalObjectives,
    completedObjectives: completedObjectives,
    avgProgress: avgProgress,
  );
});

class OkrQuarterSummary {
  final int quarter;
  final int year;
  final int totalObjectives;
  final int completedObjectives;
  final double avgProgress;
  
  OkrQuarterSummary({
    required this.quarter,
    required this.year,
    required this.totalObjectives,
    required this.completedObjectives,
    required this.avgProgress,
  });
  
  double get completionRate => totalObjectives > 0 ? completedObjectives / totalObjectives * 100 : 0;
}

class OkrRepository {
  final Database db;
  
  OkrRepository(this.db);
  
  Future<int> createObjective(OkrObjective objective) async {
    return await db.insert('okr_objectives', objective.toMap());
  }
  
  Future<void> updateObjective(OkrObjective objective) async {
    await db.update(
      'okr_objectives',
      {
        ...objective.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [objective.id],
    );
  }
  
  Future<void> deleteObjective(int id) async {
    await db.delete('okr_objectives', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> addKeyResult(OkrKeyResult kr) async {
    return await db.insert('okr_key_results', kr.toMap());
  }
  
  Future<void> updateKeyResult(OkrKeyResult kr) async {
    await db.update('okr_key_results', kr.toMap(), where: 'id = ?', whereArgs: [kr.id]);
  }
  
  Future<void> deleteKeyResult(int id) async {
    await db.delete('okr_key_results', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> updateObjectiveProgress(int objectiveId) async {
    final keyResults = await db.query(
      'okr_key_results',
      where: 'objective_id = ?',
      whereArgs: [objectiveId],
    );
    
    if (keyResults.isEmpty) return;
    
    double totalProgress = 0;
    for (final kr in keyResults) {
      final target = (kr['target_value'] as num?)?.toDouble() ?? 100;
      final current = (kr['current_value'] as num?)?.toDouble() ?? 0;
      totalProgress += target > 0 ? (current / target * 100) : 0;
    }
    
    final avgProgress = totalProgress / keyResults.length;
    
    await db.update(
      'okr_objectives',
      {
        'progress': avgProgress,
        'status': avgProgress >= 100 ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [objectiveId],
    );
  }
}

// Repository provider
final okrRepositoryProvider = FutureProvider<OkrRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return OkrRepository(db);
});