import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/smart_reminder/domain/reminder_analyzer.dart';
import 'package:thing_note/features/smart_reminder/data/reminder_pattern_repository.dart';

final reminderPatternRepositoryProvider = Provider((ref) {
  return ReminderPatternRepository();
});

final smartReminderPatternsProvider = FutureProvider<List<ReminderPattern>>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  final thingNames = await ref.watch(thingNameListProvider.future);

  final analyzer = ReminderAnalyzer();
  final patterns = analyzer.analyzePatterns(records);

  // 填充事情名称
  final thingNameMap = { for (final tn in thingNames) if (tn.id != null) tn.id!: tn.name };

  return patterns.map((p) {
    final thingName = p.thingNameId != null ? thingNameMap[p.thingNameId] : null;
    return ReminderPattern(
      thingNameId: p.thingNameId,
      thingName: thingName,
      dayOfWeek: p.dayOfWeek,
      suggestedHour: p.suggestedHour,
      suggestedMinute: p.suggestedMinute,
      confidence: p.confidence,
    );
  }).toList();
});

final savedReminderPatternsProvider = FutureProvider<List<ReminderPattern>>((ref) async {
  final repo = ref.read(reminderPatternRepositoryProvider);
  return repo.getSavedPatterns();
});