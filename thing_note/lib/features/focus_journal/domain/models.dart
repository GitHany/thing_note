import 'package:flutter/material.dart';

class FocusJournalEntry {
  final int? id;
  final DateTime date;
  final String focusDuration; // 15min, 30min, 1h, 2h+
  final String taskType; // deep_work, creative, administrative, meeting
  final int productivityRating; // 1-5
  final String? notes;
  final List<String> interruptions;
  final String? energyLevel; // high, medium, low
  final DateTime createdAt;

  FocusJournalEntry({
    this.id,
    required this.date,
    required this.focusDuration,
    required this.taskType,
    required this.productivityRating,
    this.notes,
    this.interruptions = const [],
    this.energyLevel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'focus_duration': focusDuration,
      'task_type': taskType,
      'productivity_rating': productivityRating,
      'notes': notes,
      'interruptions': interruptions.join(','),
      'energy_level': energyLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusJournalEntry.fromMap(Map<String, dynamic> map) {
    return FocusJournalEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      focusDuration: map['focus_duration'] as String,
      taskType: map['task_type'] as String,
      productivityRating: map['productivity_rating'] as int,
      notes: map['notes'] as String?,
      interruptions: (map['interruptions'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      energyLevel: map['energy_level'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FocusJournalEntry copyWith({
    int? id,
    DateTime? date,
    String? focusDuration,
    String? taskType,
    int? productivityRating,
    String? notes,
    List<String>? interruptions,
    String? energyLevel,
    DateTime? createdAt,
  }) {
    return FocusJournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      focusDuration: focusDuration ?? this.focusDuration,
      taskType: taskType ?? this.taskType,
      productivityRating: productivityRating ?? this.productivityRating,
      notes: notes ?? this.notes,
      interruptions: interruptions ?? this.interruptions,
      energyLevel: energyLevel ?? this.energyLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const Map<String, String> taskTypeLabels = {
    'deep_work': 'Deep Work',
    'creative': 'Creative',
    'administrative': 'Administrative',
    'meeting': 'Meeting',
  };

  static const Map<String, IconData> taskTypeIcons = {
    'deep_work': Icons.psychology,
    'creative': Icons.brush,
    'administrative': Icons.folder,
    'meeting': Icons.groups,
  };
}