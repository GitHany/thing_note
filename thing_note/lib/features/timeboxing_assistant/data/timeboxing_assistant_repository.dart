import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/timeboxing_assistant/domain/time_block_plan.dart';

final timeboxingAssistantRepositoryProvider = Provider<TimeboxingAssistantRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TimeboxingAssistantRepository(dbAsync);
});

final timeBlockPlansProvider = StateNotifierProvider<TimeBlockPlansNotifier, AsyncValue<List<TimeBlockPlan>>>((ref) {
  final repository = ref.watch(timeboxingAssistantRepositoryProvider);
  return TimeBlockPlansNotifier(repository);
});

final todayPlanProvider = FutureProvider<TimeBlockPlan?>((ref) async {
  final repository = ref.watch(timeboxingAssistantRepositoryProvider);
  return repository.getPlanForDate(DateTime.now());
});

class TimeboxingAssistantRepository {
  final AsyncValue<Database> _dbAsync;

  TimeboxingAssistantRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertPlan(TimeBlockPlan plan) async {
    final db = await _db;
    return db.insert('time_blocks_ai', plan.toMap());
  }

  Future<int> updatePlan(TimeBlockPlan plan) async {
    final db = await _db;
    return db.update('time_blocks_ai', plan.toMap(), where: 'id = ?', whereArgs: [plan.id]);
  }

  Future<int> deletePlan(int id) async {
    final db = await _db;
    return db.delete('time_blocks_ai', where: 'id = ?', whereArgs: [id]);
  }

  Future<TimeBlockPlan?> getPlanForDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'time_blocks_ai',
      where: 'plan_date LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    if (maps.isEmpty) return null;
    return TimeBlockPlan.fromMap(maps.first);
  }

  Future<List<TimeBlockPlan>> getRecentPlans(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'time_blocks_ai',
      where: 'plan_date >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'plan_date DESC',
    );
    return maps.map((m) => TimeBlockPlan.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    final weeklyPlans = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM time_blocks_ai WHERE plan_date >= ?',
        [weekStart.toIso8601String()],
      ),
    ) ?? 0;
    
    final monthlyPlans = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM time_blocks_ai WHERE plan_date >= ?',
        [monthStart.toIso8601String()],
      ),
    ) ?? 0;
    
    final acceptedPlans = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM time_blocks_ai WHERE is_accepted = 1'),
    ) ?? 0;
    
    final avgEfficiency = await db.rawQuery(
      'SELECT AVG(efficiency_score) as avg FROM time_blocks_ai WHERE efficiency_score > 0',
    );
    
    return {
      'weekly_plans': weeklyPlans,
      'monthly_plans': monthlyPlans,
      'accepted_plans': acceptedPlans,
      'average_efficiency': avgEfficiency.first['avg'] ?? 0,
    };
  }

  List<TimeBlock> generateSmartBlocks(List<String> activities, List<int> durations) {
    final blocks = <TimeBlock>[];
    int currentHour = 9;
    
    for (int i = 0; i < activities.length && i < durations.length; i++) {
      final duration = durations[i].clamp(1, 4);
      final endHour = (currentHour + duration).clamp(0, 24);
      
      blocks.add(TimeBlock(
        startHour: currentHour,
        endHour: endHour,
        activity: activities[i],
        type: _suggestType(activities[i]),
      ));
      
      currentHour = endHour + 1;
      if (currentHour >= 18) break;
    }
    
    return blocks;
  }

  String _suggestType(String activity) {
    final lower = activity.toLowerCase();
    if (lower.contains('工作') || lower.contains('项目')) return 'work';
    if (lower.contains('运动') || lower.contains('健身')) return 'exercise';
    if (lower.contains('学习') || lower.contains('读书')) return 'learning';
    if (lower.contains('会议') || lower.contains('会面')) return 'social';
    return 'personal';
  }

  double calculateEfficiency(TimeBlockPlan plan) {
    if (plan.suggestedBlockList.isEmpty) return 0;
    
    final suggested = plan.suggestedBlockList;
    final actual = plan.actualBlockList;
    
    if (actual.isEmpty) return 0.5;
    
    int matchCount = 0;
    for (final a in actual) {
      if (suggested.any((s) => s.activity == a.activity)) {
        matchCount++;
      }
    }
    
    return matchCount / suggested.length;
  }
}

class TimeBlockPlansNotifier extends StateNotifier<AsyncValue<List<TimeBlockPlan>>> {
  final TimeboxingAssistantRepository _repository;

  TimeBlockPlansNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repository.getRecentPlans(7);
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generatePlan(DateTime date, List<String> activities, List<int> durations) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final blocks = _repository.generateSmartBlocks(activities, durations);
      final blocksStr = TimeBlock.blocksToString(blocks);
      
      final plan = TimeBlockPlan(
        planDate: dateStr,
        suggestedBlocks: blocksStr,
      );
      
      await _repository.insertPlan(plan);
      await loadPlans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptPlan(int planId) async {
    try {
      final plans = state.value ?? [];
      final plan = plans.firstWhere((p) => p.id == planId);
      final updated = plan.copyWith(isAccepted: 1);
      await _repository.updatePlan(updated);
      await loadPlans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateActualBlocks(int planId, List<TimeBlock> actualBlocks) async {
    try {
      final plans = state.value ?? [];
      final plan = plans.firstWhere((p) => p.id == planId);
      final blocksStr = TimeBlock.blocksToString(actualBlocks);
      final efficiency = _repository.calculateEfficiency(plan.copyWith(actualBlocks: blocksStr));
      
      final updated = plan.copyWith(actualBlocks: blocksStr, efficiencyScore: efficiency);
      await _repository.updatePlan(updated);
      await loadPlans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}