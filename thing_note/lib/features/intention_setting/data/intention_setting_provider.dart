import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/intention_setting/domain/intention_setting.dart';

/// 今日意图
final todayIntentionProvider = FutureProvider<Intention?>((ref) async {
  // TODO: 从数据库获取
  return null;
});

/// 意图历史
final intentionHistoryProvider = FutureProvider<List<Intention>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 添加/更新意图
final saveIntentionProvider = Provider((ref) {
  return SaveIntentionNotifier(ref);
});

class SaveIntentionNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  SaveIntentionNotifier(this.ref) : super(false);
  
  Future<void> save(Intention intention) async {
    state = true;
    // TODO: 保存到数据库
    ref.invalidate(todayIntentionProvider);
    state = false;
  }
}