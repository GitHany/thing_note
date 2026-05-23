// Energy Curve Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/energy_curve/domain/energy_curve_models.dart';

// Today's energy curve provider
final todayEnergyProvider = FutureProvider<EnergyCurve>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'energy_curves',
    where: 'date = ?',
    whereArgs: [today],
  );
  
  if (results.isEmpty) {
    return EnergyCurve(date: today);
  }
  
  return EnergyCurve.fromMap(results.first);
});

// Weekly energy curves provider
final weeklyEnergyProvider = FutureProvider<List<EnergyCurve>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final startDate = weekStart.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'energy_curves',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date ASC',
  );
  
  return results.map((r) => EnergyCurve.fromMap(r)).toList();
});

// Monthly energy curves provider
final monthlyEnergyProvider = FutureProvider<List<EnergyCurve>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final startDate = monthStart.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'energy_curves',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date ASC',
  );
  
  return results.map((r) => EnergyCurve.fromMap(r)).toList();
});

// Energy insights provider
final energyInsightsProvider = FutureProvider<List<EnergyInsight>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Get last 30 days of data
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final startDate = thirtyDaysAgo.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'energy_curves',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date DESC',
  );
  
  if (results.length < 7) {
    return [
      EnergyInsight(
        type: 'info',
        title: '数据不足',
        description: '需要至少7天的数据才能生成洞察',
        recommendation: '坚持记录每日能量曲线，我会帮你发现你的精力模式',
      ),
    ];
  }
  
  final curves = results.map((r) => EnergyCurve.fromMap(r)).toList();
  
  // Calculate average by hour
  final hourStats = <int, List<int>>{};
  for (final curve in curves) {
    if (curve.hour6To8 > 0) hourStats.putIfAbsent(7, () => []).add(curve.hour6To8);
    if (curve.hour8To10 > 0) hourStats.putIfAbsent(9, () => []).add(curve.hour8To10);
    if (curve.hour10To12 > 0) hourStats.putIfAbsent(11, () => []).add(curve.hour10To12);
    if (curve.hour12To14 > 0) hourStats.putIfAbsent(13, () => []).add(curve.hour12To14);
    if (curve.hour14To16 > 0) hourStats.putIfAbsent(15, () => []).add(curve.hour14To16);
    if (curve.hour16To18 > 0) hourStats.putIfAbsent(17, () => []).add(curve.hour16To18);
    if (curve.hour18To20 > 0) hourStats.putIfAbsent(19, () => []).add(curve.hour18To20);
    if (curve.hour20To22 > 0) hourStats.putIfAbsent(21, () => []).add(curve.hour20To22);
  }
  
  // Find peak hour
  int peakHour = 9;
  double peakAvg = 0;
  for (final entry in hourStats.entries) {
    if (entry.value.isNotEmpty) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > peakAvg) {
        peakAvg = avg;
        peakHour = entry.key;
      }
    }
  }
  
  // Find low hour
  int lowHour = 13;
  double lowAvg = 6;
  for (final entry in hourStats.entries) {
    if (entry.value.isNotEmpty) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg < lowAvg) {
        lowAvg = avg;
        lowHour = entry.key;
      }
    }
  }
  
  final insights = <EnergyInsight>[];
  
  // Peak hour insight
  if (peakHour > 0) {
    final timeRange = '$peakHour-${peakHour + 2}点';
    insights.add(EnergyInsight(
      type: 'peak',
      title: '高效时段',
      description: '你的高效时段集中在 $timeRange，平均精力水平最高',
      recommendation: '建议将重要任务安排在这个时间段',
      confidence: (curves.length / 30 * 100).clamp(50, 95).toInt(),
    ));
  }
  
  // Low hour insight
  if (lowHour > 0) {
    final timeRange = '$lowHour-${lowHour + 2}点';
    insights.add(EnergyInsight(
      type: 'low',
      title: '低谷时段',
      description: '你的精力低谷在 $timeRange，这时段需要适当休息',
      recommendation: '建议避免在这段时间处理复杂任务，可考虑午休或轻度活动',
      confidence: (curves.length / 30 * 100).clamp(50, 95).toInt(),
    ));
  }
  
  return insights;
});

class EnergyCurveRepository {
  final dynamic db;
  
  EnergyCurveRepository(this.db);
  
  Future<int> saveEnergyCurve(EnergyCurve curve) async {
    final existing = await db.query(
      'energy_curves',
      where: 'date = ?',
      whereArgs: [curve.date],
    );
    
    if (existing.isNotEmpty) {
      await db.update(
        'energy_curves',
        curve.toMap(),
        where: 'date = ?',
        whereArgs: [curve.date],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('energy_curves', curve.toMap());
    }
  }
  
  Future<EnergyCurve?> getEnergyCurve(String date) async {
    final results = await db.query(
      'energy_curves',
      where: 'date = ?',
      whereArgs: [date],
    );
    return results.isNotEmpty ? EnergyCurve.fromMap(results.first) : null;
  }
}