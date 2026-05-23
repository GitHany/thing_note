import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/morning_checkin/domain/morning_checkin.dart';

/// 数据库服务
final morningCheckinDbProvider = Provider<MorningCheckinDbService>((ref) {
  return MorningCheckinDbService();
});

class MorningCheckinDbService {
// 这里可以注入数据库实例
  Future<MorningCheckin?> getTodayCheckin() async {
    // TODO: 从数据库查询，使用 today 日期格式: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}
    return null;
  }

  Future<int> saveCheckin(MorningCheckin checkin) async {
    // TODO: 保存到数据库
    return 1;
  }
}

/// 今日签到状态
final todayCheckinStatusProvider = FutureProvider<CheckinStatus>((ref) async {
  final dbService = ref.watch(morningCheckinDbProvider);
  final todayCheckin = await dbService.getTodayCheckin();
  if (todayCheckin == null) {
    return CheckinStatus.notStarted;
  }
  return CheckinStatus.completed;
});

/// 今日签到数据
final todayCheckinProvider = FutureProvider<MorningCheckin?>((ref) async {
  final dbService = ref.watch(morningCheckinDbProvider);
  return dbService.getTodayCheckin();
});

/// 签到历史记录
final checkinHistoryProvider = FutureProvider<List<MorningCheckin>>((ref) async {
  // TODO: 从数据库获取最近30天的签到记录
  return [];
});