/// Sort configuration for records
class SortConfig {
  final SortField field;
  final SortOrder order;

  SortConfig({
    this.field = SortField.occurredAt,
    this.order = SortOrder.descending,
  });

  SortConfig copyWith({
    SortField? field,
    SortOrder? order,
  }) {
    return SortConfig(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }
}

enum SortField {
  occurredAt,
  createdAt,
  duration,
  thingName,
  tagCount,
}

enum SortOrder {
  ascending,
  descending,
}

/// Smart sort rule
class SmartSortRule {
  final int? id;
  final String name;
  final SortConfig config;
  final bool isEnabled;
  final DateTime createdAt;

  SmartSortRule({
    this.id,
    required this.name,
    required this.config,
    this.isEnabled = true,
    required this.createdAt,
  });
}

/// Grouping configuration
class GroupConfig {
  final GroupField field;
  final bool enabled;

  GroupConfig({
    this.field = GroupField.date,
    this.enabled = true,
  });
}

enum GroupField {
  date,
  thingName,
  tag,
  location,
  none,
}

/// Sort suggestion
class SortSuggestion {
  final String title;
  final String description;
  final SortConfig config;

  SortSuggestion({
    required this.title,
    required this.description,
    required this.config,
  });
}