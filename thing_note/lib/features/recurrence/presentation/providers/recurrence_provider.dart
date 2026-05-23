import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/recurrence/domain/recurrence_pattern.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 重复模式服务提供者
final recurrencePatternServiceProvider = Provider<RecurrencePatternRepository>((ref) {
  return RecurrencePatternRepository();
});

/// 已保存的重复模式列表
final savedRecurrencePatternsProvider = FutureProvider<List<RecordRecurrencePattern>>((ref) async {
  final service = ref.read(recurrencePatternServiceProvider);
  return service.getSavedPatterns();
});

/// 重复模式分析器提供者
final recurrenceAnalyzerProvider = Provider<RecurrenceAnalyzer>((ref) {
  return RecurrenceAnalyzer();
});

/// 自动检测并保存重复模式
class RecurrenceDetectorNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  RecurrenceDetectorNotifier(this.ref) : super(const AsyncValue.data(null));

  /// 分析并保存重复模式
  Future<void> detectAndSavePattern(int thingNameId) async {
    state = const AsyncValue.loading();
    try {
      final recordRepo = ref.read(recordRepositoryProvider);
      final thingNameRepo = ref.read(thingNameRepositoryProvider);
      final patternRepo = ref.read(recurrencePatternServiceProvider);

      // 获取该 thingName 的所有记录
      final records = await _getRecordsByThingName(recordRepo, thingNameId);
      if (records.length < 3) {
        state = const AsyncValue.data(null);
        return;
      }

      // 提取日期
      final occurrenceDates = records.map((r) => r.occurredAt).toList();

      // 获取 thingName 名称
      final thingName = await thingNameRepo.getById(thingNameId);

      // 分析模式
      final pattern = RecurrenceAnalyzer.analyzePatterns(
        occurrenceDates,
        thingNameId,
        thingName?.name,
      );

      if (pattern != null && pattern.confidence >= 0.6) {
        await patternRepo.savePattern(pattern);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<EpisodeRecord>> _getRecordsByThingName(
    dynamic recordRepo,
    int thingNameId,
  ) async {
    final db = await recordRepo._db;
    final maps = await db.query(
      'episode_records',
      where: 'thing_name_id = ?',
      whereArgs: [thingNameId],
      orderBy: 'occurred_at ASC',
    );
    return maps.map((map) => recordRepo._fromMap(map)).toList();
  }

  /// 分析所有 thingName 的重复模式
  Future<void> analyzeAllThingNames() async {
    state = const AsyncValue.loading();
    try {
      final thingNameRepo = ref.read(thingNameRepositoryProvider);
      final thingNames = await thingNameRepo.getAll();

      for (final thingName in thingNames) {
        if (thingName.id != null) {
          await detectAndSavePattern(thingName.id!);
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recurrenceDetectorProvider =
    StateNotifierProvider<RecurrenceDetectorNotifier, AsyncValue<void>>((ref) {
  return RecurrenceDetectorNotifier(ref);
});

/// 根据重复模式预测下次提醒时间
final predictedReminderTimeProvider = FutureProvider.family<DateTime?, RecordRecurrencePattern>((ref, pattern) {
  return Future.value(RecurrenceAnalyzer.predictNextOccurrence(pattern));
});

/// 获取某个 thingName 的推荐重复设置
final recommendedRepeatProvider = FutureProvider.family<RecordRecurrencePattern?, int>((ref, thingNameId) async {
  final patternRepo = ref.read(recurrencePatternServiceProvider);
  return patternRepo.getPatternForThingName(thingNameId);
});