import 'dart:convert';

class SmartDashboardConfig {
  final int? id;
  final String name;
  final List<String> widgetOrder;
  final int refreshInterval; // seconds
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SmartDashboardConfig({
    this.id,
    required this.name,
    this.widgetOrder = const [],
    this.refreshInterval = 60,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'widget_order': jsonEncode(widgetOrder),
      'refresh_interval': refreshInterval,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SmartDashboardConfig.fromMap(Map<String, dynamic> map) {
    final widgetOrderStr = map['widget_order'] as String?;
    List<String> widgets = [];
    if (widgetOrderStr != null && widgetOrderStr.isNotEmpty) {
      final decoded = jsonDecode(widgetOrderStr);
      if (decoded is List) {
        widgets = decoded.map((e) => e.toString()).toList();
      }
    }

    return SmartDashboardConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      widgetOrder: widgets,
      refreshInterval: map['refresh_interval'] as int? ?? 60,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  SmartDashboardConfig copyWith({
    int? id,
    String? name,
    List<String>? widgetOrder,
    int? refreshInterval,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartDashboardConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      widgetOrder: widgetOrder ?? this.widgetOrder,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum DashboardWidget {
  todayOverview,
  recordCount,
  habitProgress,
  moodTrend,
  goalProgress,
  quickActions,
  recentRecords,
  weather,
  calendar,
  focusTimer,
}