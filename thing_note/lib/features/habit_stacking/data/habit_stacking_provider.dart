import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_stacking/domain/habit_stacking.dart';

/// 习惯链列表
final habitChainsProvider = FutureProvider<List<HabitChain>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 添加习惯链
class HabitStackingService {
  Future<void> addChain(HabitChain chain) async {
    // TODO: 保存到数据库
  }
}

final habitStackingServiceProvider = Provider((ref) => HabitStackingService());