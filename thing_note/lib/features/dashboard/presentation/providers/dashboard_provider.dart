import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// Dashboard statistics data class
class DashboardStats {
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final int reminderCount;
  final int favoriteCount;
  final int recurringCount;
  final List<EpisodeRecord> recentRecords;

  const DashboardStats({
    this.todayCount = 0,
    this.weekCount = 0,
    this.monthCount = 0,
    this.reminderCount = 0,
    this.favoriteCount = 0,
    this.recurringCount = 0,
    this.recentRecords = const [],
  });

  int get totalCount => todayCount + weekCount + monthCount;
}

/// Dashboard statistics provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);
  final allRecords = await repo.getAll();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final todayCount = allRecords.where((r) => r.occurredAt.isAfter(today)).length;
  final weekCount = allRecords.where((r) => r.occurredAt.isAfter(weekStart)).length;
  final monthCount = allRecords.where((r) => r.occurredAt.isAfter(monthStart)).length;
  final reminderCount = allRecords.where((r) => r.hasReminder).length;
  final favoriteCount = allRecords.where((r) => r.isFavorite).length;
  final recurringCount = allRecords.where((r) => r.isRecurring).length;
  final recentRecords = allRecords.take(5).toList();

  return DashboardStats(
    todayCount: todayCount,
    weekCount: weekCount,
    monthCount: monthCount,
    reminderCount: reminderCount,
    favoriteCount: favoriteCount,
    recurringCount: recurringCount,
    recentRecords: recentRecords,
  );
});