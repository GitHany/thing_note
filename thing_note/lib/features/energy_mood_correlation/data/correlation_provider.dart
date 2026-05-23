import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/energy_mood_correlation/domain/correlation_model.dart';

final energyMoodStatsProvider = FutureProvider<EnergyMoodStats>((ref) async {
  // 模拟统计数据
  return EnergyMoodStats(
    averageEnergy: 7.2,
    averageMood: 6.8,
    correlation: 0.75,
    peakEnergyTime: '上午 9-11点',
    bestMoodTime: '下午 3-5点',
    insights: [
      CorrelationInsight(
        factor: '运动',
        insight: '运动后能量提升约 20%',
        confidence: 0.85,
        recommendations: ['每天运动30分钟', '选择早晨运动'],
      ),
      CorrelationInsight(
        factor: '睡眠',
        insight: '睡眠7-8小时时情绪最佳',
        confidence: 0.90,
        recommendations: ['保持规律作息', '避免熬夜'],
      ),
    ],
  );
});

class EnergyMoodNotifier extends StateNotifier<AsyncValue<List<EnergyMoodCorrelation>>> {
  final Ref ref;
  
  EnergyMoodNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadData();
  }
  
  Future<void> _loadData() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query(
        'energy_mood_correlations',
        orderBy: 'date DESC',
        limit: 30,
      );
      state = AsyncValue.data(results.map((m) => EnergyMoodCorrelation.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> recordCorrelation(int energyLevel, int moodLevel, String? activity) async {
    final db = await ref.read(databaseProvider.future);
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await db.insert('energy_mood_correlations', {
      'date': dateStr,
      'energy_level': energyLevel,
      'mood_level': moodLevel,
      'activity_type': activity,
      'correlation_score': (energyLevel + moodLevel) / 2,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadData();
  }
}

final energyMoodNotifierProvider =
    StateNotifierProvider<EnergyMoodNotifier, AsyncValue<List<EnergyMoodCorrelation>>>((ref) {
  return EnergyMoodNotifier(ref);
});