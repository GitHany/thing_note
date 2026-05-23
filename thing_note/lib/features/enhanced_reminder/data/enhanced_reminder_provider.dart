import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_reminder/domain/enhanced_reminder.dart';
import 'package:thing_note/features/enhanced_reminder/data/enhanced_reminder_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final enhancedReminderRepositoryProvider = FutureProvider<EnhancedReminderRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return EnhancedReminderRepository(db);
});

final allRemindersProvider = FutureProvider<List<EnhancedReminder>>((ref) async {
  final repo = await ref.watch(enhancedReminderRepositoryProvider.future);
  return repo.getAllReminders();
});

final upcomingRemindersProvider = FutureProvider<List<EnhancedReminder>>((ref) async {
  final repo = await ref.watch(enhancedReminderRepositoryProvider.future);
  return repo.getUpcomingReminders(limit: 10);
});

final remindersForRecordProvider = FutureProvider.family<List<EnhancedReminder>, int>((ref, recordId) async {
  final repo = await ref.watch(enhancedReminderRepositoryProvider.future);
  return repo.getRemindersForRecord(recordId);
});

final reminderStatsProvider = FutureProvider<ReminderStats>((ref) async {
  final repo = await ref.watch(enhancedReminderRepositoryProvider.future);
  return repo.getStats();
});

class EnhancedReminderNotifier extends StateNotifier<AsyncValue<List<EnhancedReminder>>> {
  EnhancedReminderNotifier() : super(const AsyncValue.data([]));

  Future<void> loadReminders() async {
    state = const AsyncValue.data([]);
  }

  Future<void> createReminder(EnhancedReminder reminder) async {
    // Placeholder
  }

  Future<void> updateReminder(EnhancedReminder reminder) async {
    // Placeholder
  }

  Future<void> deleteReminder(int id) async {
    // Placeholder
  }

  Future<void> snooze(int id, int minutes) async {
    // Placeholder
  }

  Future<void> toggleEnabled(int id, bool enabled) async {
    // Placeholder
  }
}

final enhancedReminderNotifierProvider = StateNotifierProvider<EnhancedReminderNotifier, AsyncValue<List<EnhancedReminder>>>((ref) {
  return EnhancedReminderNotifier();
});