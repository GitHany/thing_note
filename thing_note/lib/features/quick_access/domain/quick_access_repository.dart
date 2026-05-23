import 'package:shared_preferences/shared_preferences.dart';

class QuickAccessData {
  final List<int> recentRecordIds;
  final List<int> favoriteRecordIds;
  final List<int> frequentlyUsedThingNameIds;
  final Map<int, int> thingNameUsageCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastRecordDate;

  const QuickAccessData({
    this.recentRecordIds = const [],
    this.favoriteRecordIds = const [],
    this.frequentlyUsedThingNameIds = const [],
    this.thingNameUsageCount = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastRecordDate,
  });

  QuickAccessData copyWith({
    List<int>? recentRecordIds,
    List<int>? favoriteRecordIds,
    List<int>? frequentlyUsedThingNameIds,
    Map<int, int>? thingNameUsageCount,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastRecordDate,
  }) {
    return QuickAccessData(
      recentRecordIds: recentRecordIds ?? this.recentRecordIds,
      favoriteRecordIds: favoriteRecordIds ?? this.favoriteRecordIds,
      frequentlyUsedThingNameIds: frequentlyUsedThingNameIds ?? this.frequentlyUsedThingNameIds,
      thingNameUsageCount: thingNameUsageCount ?? this.thingNameUsageCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastRecordDate: lastRecordDate ?? this.lastRecordDate,
    );
  }
}

class QuickAccessRepository {
  static const _keyRecentRecords = 'quick_access_recent_records';
  static const _keyFavoriteRecords = 'quick_access_favorite_records';
  static const _keyThingNameUsage = 'quick_access_thing_name_usage';
  static const _keyCurrentStreak = 'quick_access_current_streak';
  static const _keyLongestStreak = 'quick_access_longest_streak';
  static const _keyLastRecordDate = 'quick_access_last_record_date';
  static const _maxRecentRecords = 20;
  static const _maxFrequentlyUsed = 10;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<QuickAccessData> load() async {
    final p = await prefs;

    final recentStr = p.getStringList(_keyRecentRecords) ?? [];
    final recentIds = recentStr.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();

    final favoriteStr = p.getStringList(_keyFavoriteRecords) ?? [];
    final favoriteIds = favoriteStr.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();

    final thingNameUsageStr = p.getString(_keyThingNameUsage) ?? '';
    final thingNameUsage = <int, int>{};
    if (thingNameUsageStr.isNotEmpty) {
      for (final entry in thingNameUsageStr.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = int.tryParse(parts[0]);
          final value = int.tryParse(parts[1]);
          if (key != null && value != null) {
            thingNameUsage[key] = value;
          }
        }
      }
    }

    final sortedEntries = thingNameUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequentlyUsed = sortedEntries
      .take(_maxFrequentlyUsed)
      .map((e) => e.key)
      .toList();

    final currentStreak = p.getInt(_keyCurrentStreak) ?? 0;
    final longestStreak = p.getInt(_keyLongestStreak) ?? 0;
    final lastRecordDateStr = p.getString(_keyLastRecordDate);
    final lastRecordDate = lastRecordDateStr != null ? DateTime.tryParse(lastRecordDateStr) : null;

    return QuickAccessData(
      recentRecordIds: recentIds,
      favoriteRecordIds: favoriteIds,
      frequentlyUsedThingNameIds: frequentlyUsed,
      thingNameUsageCount: thingNameUsage,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastRecordDate: lastRecordDate,
    );
  }

  Future<void> addRecentRecord(int recordId) async {
    final p = await prefs;
    final recentStr = p.getStringList(_keyRecentRecords) ?? [];
    final recentIds = recentStr.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();

    // Remove if already exists, then add to front
    recentIds.remove(recordId);
    recentIds.insert(0, recordId);

    // Keep only max items
    final trimmed = recentIds.take(_maxRecentRecords).toList();
    await p.setStringList(_keyRecentRecords, trimmed.map((id) => id.toString()).toList());
  }

  Future<void> recordThingNameUsed(int thingNameId) async {
    final p = await prefs;
    final thingNameUsageStr = p.getString(_keyThingNameUsage) ?? '';
    final thingNameUsage = <int, int>{};

    if (thingNameUsageStr.isNotEmpty) {
      for (final entry in thingNameUsageStr.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = int.tryParse(parts[0]);
          final value = int.tryParse(parts[1]);
          if (key != null && value != null) {
            thingNameUsage[key] = value;
          }
        }
      }
    }

    thingNameUsage[thingNameId] = (thingNameUsage[thingNameId] ?? 0) + 1;
    final newStr = thingNameUsage.entries.map((e) => '${e.key}:${e.value}').join(',');
    await p.setString(_keyThingNameUsage, newStr);
  }

  Future<void> updateStreak(DateTime recordDate) async {
    final p = await prefs;
    var currentStreak = p.getInt(_keyCurrentStreak) ?? 0;
    var longestStreak = p.getInt(_keyLongestStreak) ?? 0;
    final lastRecordDateStr = p.getString(_keyLastRecordDate);
    final lastRecordDate = lastRecordDateStr != null ? DateTime.tryParse(lastRecordDateStr) : null;

    final today = DateTime(recordDate.year, recordDate.month, recordDate.day);

    if (lastRecordDate == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime(lastRecordDate.year, lastRecordDate.month, lastRecordDate.day);
      final diff = today.difference(lastDate).inDays;

      if (diff == 0) {
        // Same day, no change
      } else if (diff == 1) {
        // Consecutive day
        currentStreak++;
      } else {
        // Streak broken
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    await p.setInt(_keyCurrentStreak, currentStreak);
    await p.setInt(_keyLongestStreak, longestStreak);
    await p.setString(_keyLastRecordDate, recordDate.toIso8601String());
  }

  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_keyRecentRecords);
    await p.remove(_keyFavoriteRecords);
    await p.remove(_keyThingNameUsage);
    await p.remove(_keyCurrentStreak);
    await p.remove(_keyLongestStreak);
    await p.remove(_keyLastRecordDate);
  }
}