import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_sort/domain/sort_config.dart';

class SmartSortService {
  /// Apply smart sorting based on user behavior
  List<Map<String, dynamic>> sortRecords(
    List<Map<String, dynamic>> records,
    SortConfig config,
  ) {
    final sorted = List<Map<String, dynamic>>.from(records);

    sorted.sort((a, b) {
      int comparison;

      switch (config.field) {
        case SortField.occurredAt:
          final aTime = DateTime.parse(a['occurred_at'] as String);
          final bTime = DateTime.parse(b['occurred_at'] as String);
          comparison = aTime.compareTo(bTime);
          break;

        case SortField.createdAt:
          final aTime = DateTime.parse(a['created_at'] as String);
          final bTime = DateTime.parse(b['created_at'] as String);
          comparison = aTime.compareTo(bTime);
          break;

        case SortField.duration:
          final aDuration = (a['duration_sec'] as int?) ?? 0;
          final bDuration = (b['duration_sec'] as int?) ?? 0;
          comparison = aDuration.compareTo(bDuration);
          break;

        case SortField.thingName:
          final aName = a['thing_name_id'] ?? 0;
          final bName = b['thing_name_id'] ?? 0;
          comparison = (aName as int).compareTo(bName as int);
          break;

        case SortField.tagCount:
          // Simplified - would need to count tags
          comparison = 0;
          break;
      }

      return config.order == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Group records by a field
  Map<String, List<Map<String, dynamic>>> groupRecords(
    List<Map<String, dynamic>> records,
    GroupConfig config,
  ) {
    if (!config.enabled || config.field == GroupField.none) {
      return {'': records};
    }

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      String key;
      switch (config.field) {
        case GroupField.date:
          final occurredAt = DateTime.parse(record['occurred_at'] as String);
          key = '${occurredAt.year}-${occurredAt.month}-${occurredAt.day}';
          break;
        case GroupField.thingName:
          key = (record['thing_name_id'] ?? 'Unknown').toString();
          break;
        case GroupField.tag:
          key = 'Tagged'; // Simplified
          break;
        case GroupField.location:
          final addr = record['address'] as String?;
          key = addr ?? 'Unknown';
          break;
        case GroupField.none:
          key = '';
          break;
      }

      groups.putIfAbsent(key, () => []).add(record);
    }

    return groups;
  }

  /// Get sort suggestions based on usage patterns
  List<SortSuggestion> getSortSuggestions() {
    return [
      SortSuggestion(
        title: 'Most Recent First',
        description: 'Sort by occurrence time, newest first',
        config: SortConfig(
          field: SortField.occurredAt,
          order: SortOrder.descending,
        ),
      ),
      SortSuggestion(
        title: 'Longest Duration',
        description: 'Sort by record duration, longest first',
        config: SortConfig(
          field: SortField.duration,
          order: SortOrder.descending,
        ),
      ),
      SortSuggestion(
        title: 'By Category',
        description: 'Group by thing name category',
        config: SortConfig(field: SortField.thingName),
      ),
    ];
  }

  /// Detect user's natural sorting preference
  SortConfig detectPreference(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return SortConfig();

    // Check if most records are newest first
    int ascendingCount = 0;
    int descendingCount = 0;

    for (int i = 0; i < records.length - 1; i++) {
      final current = DateTime.parse(records[i]['occurred_at'] as String);
      final next = DateTime.parse(records[i + 1]['occurred_at'] as String);

      if (current.isAfter(next)) {
        descendingCount++;
      } else {
        ascendingCount++;
      }
    }

    return SortConfig(
      field: SortField.occurredAt,
      order: descendingCount > ascendingCount
          ? SortOrder.descending
          : SortOrder.ascending,
    );
  }
}

final smartSortServiceProvider = Provider<SmartSortService>((ref) {
  return SmartSortService();
});