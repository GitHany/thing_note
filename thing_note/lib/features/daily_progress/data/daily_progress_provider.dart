import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_progress/domain/daily_progress.dart';

/// 今日进度
final dailyProgressProvider = FutureProvider<DailyProgress>((ref) async {
  // TODO: 从数据库获取
  return DailyProgress(
    date: DateTime.now(),
    items: [],
    completedCount: 0,
    totalCount: 0,
  );
});

/// 更新进度
final updateProgressProvider = Provider((ref) {
  return UpdateProgressNotifier(ref);
});

class UpdateProgressNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  UpdateProgressNotifier(this.ref) : super(false);
  
  Future<void> update(String itemId, {bool? isCompleted, int? currentValue}) async {
    state = true;
    // TODO: 更新数据库
    ref.invalidate(dailyProgressProvider);
    state = false;
  }
}