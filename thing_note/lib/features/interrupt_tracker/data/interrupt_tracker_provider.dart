import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/interrupt_tracker/domain/interrupt_tracker.dart';

/// 当前进行中的中断
final activeInterruptProvider = StateProvider<Interrupt?>((ref) => null);

/// 今日中断列表
final todayInterruptsProvider = FutureProvider<List<Interrupt>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 中断统计
final interruptStatsProvider = FutureProvider<InterruptStats>((ref) async {
  // TODO: 计算统计
  return const InterruptStats();
});

/// 中断追踪服务
class InterruptService {
  Future<void> startInterrupt(Interrupt interrupt) async {
    // TODO: 保存到数据库
  }

  Future<void> endInterrupt(int id, {bool? isProductive, String? note}) async {
    // TODO: 更新数据库
  }
}

final interruptServiceProvider = Provider((ref) => InterruptService());