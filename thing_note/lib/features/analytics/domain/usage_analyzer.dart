import 'package:thing_note/features/record/domain/episode_record.dart';

class UsageInsight {
  final String title;
  final String description;
  final InsightType type;
  final double score;
  final String? actionText;
  final String? actionRoute;

  const UsageInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.score,
    this.actionText,
    this.actionRoute,
  });
}

enum InsightType {
  frequency,    // 使用频率
  duration,     // 时长分析
  pattern,      // 时间模式
  streak,       // 连续记录
  suggestion,   // 建议
  achievement,  // 成就
}

class UsageAnalyzer {
  List<UsageInsight> analyzeUsage(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return [
        const UsageInsight(
          title: '开始记录',
          description: '记录你的第一个事件开始追踪你的日常',
          type: InsightType.suggestion,
          score: 1.0,
          actionText: '添加第一条记录',
          actionRoute: '/record/new',
        ),
      ];
    }

    final insights = <UsageInsight>[];

    // 分析使用频率
    insights.add(_analyzeFrequency(records));

    // 分析持续时间
    insights.add(_analyzeDuration(records));

    // 分析时间模式
    insights.add(_analyzeTimePattern(records));

    // 分析连续记录
    insights.add(_analyzeStreak(records));

    // 分析成就
    insights.addAll(_analyzeAchievements(records));

    return insights;
  }

  UsageInsight _analyzeFrequency(List<EpisodeRecord> records) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = records.where((r) =>
        r.occurredAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).length;

    String description;
    String actionText;
    String actionRoute;

    if (thisWeek >= 7) {
      description = '太棒了！本周已记录 $thisWeek 条事件';
      actionText = '继续保持';
      actionRoute = '/';
    } else if (thisWeek >= 4) {
      description = '不错！本周已记录 $thisWeek 条事件，保持好习惯';
      actionText = '查看更多';
      actionRoute = '/';
    } else if (thisWeek >= 1) {
      description = '本周已记录 $thisWeek 条事件，每天记录会让数据更有价值';
      actionText = '开始今日记录';
      actionRoute = '/record/new';
    } else {
      description = '本周还没有记录，今天开始记录吧';
      actionText = '立即记录';
      actionRoute = '/record/new';
    }

    return UsageInsight(
      title: '本周记录',
      description: description,
      type: InsightType.frequency,
      score: (thisWeek / 7).clamp(0, 1).toDouble(),
      actionText: actionText,
      actionRoute: actionRoute,
    );
  }

  UsageInsight _analyzeDuration(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return const UsageInsight(
        title: '平均时长',
        description: '记录更多事件来分析你的时间使用模式',
        type: InsightType.duration,
        score: 0,
      );
    }

    final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationSec);
    final avgDuration = totalDuration / records.length;

    final hours = avgDuration ~/ 3600;
    final minutes = ((avgDuration % 3600) ~/ 60).round();

    String durationStr;
    if (hours > 0) {
      durationStr = '${hours}h ${minutes}m';
    } else {
      durationStr = '${minutes}m';
    }

    String description;
    if (avgDuration > 3600) {
      description = '你每次事件的平均时长为 $durationStr，持续时间较长';
    } else if (avgDuration > 600) {
      description = '你每次事件的平均时长为 $durationStr，时间管理得很好';
    } else {
      description = '你每次事件的平均时长为 $durationStr，记录的都是简短事件';
    }

    return UsageInsight(
      title: '平均时长',
      description: description,
      type: InsightType.duration,
      score: (avgDuration / 7200).clamp(0, 1).toDouble(),
    );
  }

  UsageInsight _analyzeTimePattern(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return const UsageInsight(
        title: '时间模式',
        description: '记录更多以发现你的时间模式',
        type: InsightType.pattern,
        score: 0,
      );
    }

    final morningRecords = records.where((r) => r.occurredAt.hour < 12).length;
    final afternoonRecords = records.where((r) => r.occurredAt.hour >= 12 && r.occurredAt.hour < 18).length;
    final eveningRecords = records.where((r) => r.occurredAt.hour >= 18).length;

    String pattern;

    final maxCount = [morningRecords, afternoonRecords, eveningRecords].reduce((a, b) => a > b ? a : b);

    if (maxCount == morningRecords && morningRecords > records.length * 0.4) {
      pattern = '你是早起型用户，最活跃的时间段是上午';
    } else if (maxCount == afternoonRecords && afternoonRecords > records.length * 0.4) {
      pattern = '你是下午活跃型用户，最活跃的时间段是下午';
    } else if (maxCount == eveningRecords && eveningRecords > records.length * 0.4) {
      pattern = '你是夜猫子型用户，最活跃的时间段是晚上';
    } else {
      pattern = '你的记录分布比较均匀，全天都有活动';
    }

    return UsageInsight(
      title: '时间模式',
      description: pattern,
      type: InsightType.pattern,
      score: 0.8,
    );
  }

  UsageInsight _analyzeStreak(List<EpisodeRecord> records) {
    if (records.isEmpty) {
      return const UsageInsight(
        title: '连续记录',
        description: '连续记录会帮助你形成好习惯',
        type: InsightType.streak,
        score: 0,
      );
    }

    final streak = _calculateStreak(records);

    String description;

    if (streak >= 30) {
      description = '太厉害了！你已经连续记录 $streak 天，成为习惯大师！';
    } else if (streak >= 14) {
      description = '很棒！你已经连续记录 $streak 天，继续保持！';
    } else if (streak >= 7) {
      description = '不错！你已经连续记录 $streak 天，一周养成好习惯！';
    } else if (streak >= 3) {
      description = '开始形成习惯了！你已经连续记录 $streak 天';
    } else {
      description = '目前连续记录 $streak 天，加油让连续天数更长！';
    }

    return UsageInsight(
      title: '连续记录',
      description: description,
      type: InsightType.streak,
      score: (streak / 30).clamp(0, 1).toDouble(),
    );
  }

  List<UsageInsight> _analyzeAchievements(List<EpisodeRecord> records) {
    final achievements = <UsageInsight>[];

    // 首次记录成就
    if (records.isNotEmpty && records.length < 5) {
      achievements.add(const UsageInsight(
        title: '初次记录',
        description: '恭喜你开始了记录之旅！',
        type: InsightType.achievement,
        score: 1.0,
      ));
    }

    // 记录数量里程碑
    if (records.length >= 10) {
      achievements.add(const UsageInsight(
        title: '10 条记录',
        description: '你已经记录了 10 条事件，继续加油！',
        type: InsightType.achievement,
        score: 1.0,
      ));
    }

    if (records.length >= 50) {
      achievements.add(const UsageInsight(
        title: '50 条记录',
        description: '厉害！你已经记录了 50 条事件，数据量可观！',
        type: InsightType.achievement,
        score: 1.0,
      ));
    }

    // 收藏记录
    final favoriteCount = records.where((r) => r.isFavorite).length;
    if (favoriteCount >= 5) {
      achievements.add(UsageInsight(
        title: '收藏达人',
        description: '你有 $favoriteCount 条收藏记录，重要的事情都记得',
        type: InsightType.achievement,
        score: 1.0,
      ));
    }

    // 包含多媒体的记录
    final mediaCount = records.where((r) =>
        r.photoPaths.isNotEmpty ||
        r.audioPaths.isNotEmpty ||
        r.videoPaths.isNotEmpty).length;
    if (mediaCount >= 3) {
      achievements.add(UsageInsight(
        title: '多媒体记录',
        description: '你有 $mediaCount 条包含照片、音频或视频的记录',
        type: InsightType.achievement,
        score: 1.0,
      ));
    }

    return achievements;
  }

  int _calculateStreak(List<EpisodeRecord> records) {
    if (records.isEmpty) return 0;

    final dates = records.map((r) =>
        DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day)).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final latestDate = dates.first;
    if (!latestDate.isAtSameMomentAs(today) && !latestDate.isAtSameMomentAs(yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}