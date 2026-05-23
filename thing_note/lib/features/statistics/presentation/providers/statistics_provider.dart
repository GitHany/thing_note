import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';

final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(recordRepositoryProvider);

  // Get all records
  final allRecords = await repo.getAll();
  final totalCount = allRecords.length;

  // Monthly count
  final monthlyCount = <String, int>{};
  for (final record in allRecords) {
    final month = '${record.occurredAt.year}-${record.occurredAt.month.toString().padLeft(2, '0')}';
    monthlyCount[month] = (monthlyCount[month] ?? 0) + 1;
  }

  // Thing name count
  final thingNameCount = <int, int>{};
  for (final record in allRecords) {
    if (record.thingNameId != null) {
      thingNameCount[record.thingNameId!] = (thingNameCount[record.thingNameId!] ?? 0) + 1;
    }
  }

  // Media count
  final photoCount = allRecords.fold(0, (sum, r) => sum + r.photoPaths.length);
  final audioCount = allRecords.fold(0, (sum, r) => sum + r.audioPaths.length);
  final videoCount = allRecords.fold(0, (sum, r) => sum + r.videoPaths.length);

  // Favorite count
  final favoriteCount = allRecords.where((r) => r.isFavorite).length;

  // Record this week
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final weekCount = allRecords.where((r) => r.occurredAt.isAfter(weekAgo)).length;

  return {
    'totalCount': totalCount,
    'monthlyCount': monthlyCount,
    'thingNameCount': thingNameCount,
    'photoCount': photoCount,
    'audioCount': audioCount,
    'videoCount': videoCount,
    'favoriteCount': favoriteCount,
    'weekCount': weekCount,
    'totalDuration': allRecords.fold(0, (sum, r) => sum + r.durationSec),
  };
});