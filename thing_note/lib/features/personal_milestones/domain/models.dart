import 'package:flutter/material.dart';

class PersonalMilestone {
  final int? id;
  final String title;
  final String? description;
  final String category; // career, health, learning, personal, finance
  final int targetValue;
  final int currentValue;
  final String unit;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  PersonalMilestone({
    this.id,
    required this.title,
    this.description,
    required this.category,
    this.targetValue = 1,
    this.currentValue = 0,
    required this.unit,
    this.targetDate,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'target_date': targetDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory PersonalMilestone.fromMap(Map<String, dynamic> map) {
    return PersonalMilestone(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      targetValue: map['target_value'] as int,
      currentValue: map['current_value'] as int,
      unit: map['unit'] as String,
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date'] as String) : null,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
    );
  }

  PersonalMilestone copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    int? targetValue,
    int? currentValue,
    String? unit,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PersonalMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static const Map<String, IconData> categoryIcons = {
    'career': Icons.work,
    'health': Icons.favorite,
    'learning': Icons.school,
    'personal': Icons.person,
    'finance': Icons.attach_money,
  };
}