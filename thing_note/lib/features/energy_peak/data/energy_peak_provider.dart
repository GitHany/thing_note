import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/energy_peak/domain/energy_peak.dart';

/// 能量峰值列表
final energyPeaksProvider = FutureProvider<List<EnergyPeak>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 能量统计
final energyStatsProvider = FutureProvider<EnergyStats>((ref) async {
  // TODO: 计算统计
  return const EnergyStats();
});

/// 记录能量
final recordEnergyProvider = Provider((ref) {
  return RecordEnergyNotifier(ref);
});

class RecordEnergyNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  RecordEnergyNotifier(this.ref) : super(false);
  
  Future<void> record(EnergyPeak peak) async {
    state = true;
    // TODO: 保存到数据库
    ref.invalidate(energyPeaksProvider);
    state = false;
  }
}