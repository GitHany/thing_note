import 'package:flutter/material.dart';

/// 仪表盘布局数据模型
class DashboardLayout {
  final int? id;
  final String name;
  final String layoutJson;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DashboardLayout({
    this.id,
    required this.name,
    required this.layoutJson,
    this.isActive = false,
    required this.createdAt,
    this.updatedAt,
  });

  DashboardLayout copyWith({
    int? id,
    String? name,
    String? layoutJson,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DashboardLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      layoutJson: layoutJson ?? this.layoutJson,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'layout_json': layoutJson,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DashboardLayout.fromMap(Map<String, dynamic> map) {
    return DashboardLayout(
      id: map['id'] as int?,
      name: map['name'] as String,
      layoutJson: map['layout_json'] as String,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

/// 仪表盘组件
class DashboardWidget {
  final int? id;
  final String type;
  final String? title;
  final String config;
  final int position;
  final String size;

  const DashboardWidget({
    this.id,
    required this.type,
    this.title,
    this.config = '{}',
    this.position = 0,
    this.size = 'medium',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'title': title,
      'config': config,
      'position': position,
      'size': size,
    };
  }

  factory DashboardWidget.fromMap(Map<String, dynamic> map) {
    return DashboardWidget(
      id: map['id'] as int?,
      type: map['type'] as String,
      title: map['title'] as String?,
      config: map['config'] as String? ?? '{}',
      position: map['position'] as int? ?? 0,
      size: map['size'] as String? ?? 'medium',
    );
  }
}

/// 组件类型
class WidgetType {
  static const stats = 'stats';
  static const quickAction = 'quick_action';
  static const habit = 'habit';
  static const weather = 'weather';
  static const todo = 'todo';
  static const chart = 'chart';

  static String getTitle(String type) {
    switch (type) {
      case stats: return '统计卡片';
      case quickAction: return '快捷操作';
      case habit: return '习惯打卡';
      case weather: return '天气';
      case todo: return '待办';
      case chart: return '图表';
      default: return '组件';
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case stats: return Icons.bar_chart;
      case quickAction: return Icons.flash_on;
      case habit: return Icons.check_circle;
      case weather: return Icons.wb_sunny;
      case todo: return Icons.list;
      case chart: return Icons.pie_chart;
      default: return Icons.widgets;
    }
  }
}