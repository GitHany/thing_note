import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/intelligent_reminder/data/intelligent_reminder_repository.dart';
import 'package:thing_note/features/intelligent_reminder/domain/intelligent_reminder.dart';

final intelligentReminderRepositoryProvider = Provider((ref) => IntelligentReminderRepository(ref));

final allRemindersProvider = FutureProvider<List<IntelligentReminder>>((ref) async {
  final repo = ref.read(intelligentReminderRepositoryProvider);
  return repo.getAllReminders();
});

final enabledRemindersProvider = FutureProvider<List<IntelligentReminder>>((ref) async {
  final repo = ref.read(intelligentReminderRepositoryProvider);
  return repo.getEnabledReminders();
});