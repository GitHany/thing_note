import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/models.dart';

final focusJournalProvider = StateNotifierProvider<FocusJournalNotifier, List<FocusJournalEntry>>((ref) {
  return FocusJournalNotifier(ref);
});

final todayFocusJournalProvider = Provider<FocusJournalEntry?>((ref) {
  final entries = ref.watch(focusJournalProvider);
  final today = DateTime.now();
  try {
    return entries.firstWhere(
      (e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day,
    );
  } catch (_) {
    return null;
  }
});

final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final entries = ref.watch(focusJournalProvider);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  
  final weekEntries = entries.where((e) => e.date.isAfter(weekAgo)).toList();
  
  if (weekEntries.isEmpty) {
    return {'avgProductivity': 0.0, 'totalSessions': 0, 'totalHours': 0.0};
  }

  final avgProductivity = weekEntries.fold(0.0, (sum, e) => sum + e.productivityRating) / weekEntries.length;
  
  double totalHours = 0;
  for (final entry in weekEntries) {
    switch (entry.focusDuration) {
      case '15min': totalHours += 0.25; break;
      case '30min': totalHours += 0.5; break;
      case '1h': totalHours += 1; break;
      case '2h': totalHours += 2; break;
      case '2h+': totalHours += 2.5; break;
    }
  }

  return {
    'avgProductivity': avgProductivity,
    'totalSessions': weekEntries.length,
    'totalHours': totalHours,
  };
});

class FocusJournalNotifier extends StateNotifier<List<FocusJournalEntry>> {
  final Ref ref;

  FocusJournalNotifier(this.ref) : super([]) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('focus_journal_entries', orderBy: 'date DESC');
    state = maps.map((m) => FocusJournalEntry.fromMap(m)).toList();
  }

  Future<int> addEntry(FocusJournalEntry entry) async {
    final db = await ref.read(databaseProvider.future);
    final id = await db.insert('focus_journal_entries', entry.toMap()..remove('id'));
    await loadEntries();
    return id;
  }

  Future<void> updateEntry(FocusJournalEntry entry) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('focus_journal_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('focus_journal_entries', where: 'id = ?', whereArgs: [id]);
    await loadEntries();
  }
}