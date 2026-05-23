import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_activity_matcher/domain/mood_activity_matcher.dart';

/// 活动映射列表
final moodActivityMappingsProvider = FutureProvider<List<MoodActivityMapping>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 推荐活动
final activityRecommendationsProvider = FutureProvider<List<ActivityRecommendation>>((ref) async {
  // TODO: 基于当前情绪推荐活动
  return [];
});

/// 添加映射
class MoodActivityService {
  Future<void> addMapping(String activity, int mood) async {
    // TODO: 保存到数据库
  }
}

final moodActivityServiceProvider = Provider((ref) => MoodActivityService());