// Periodic Review System feature
// Version: 1.0
// Description: 周期性回顾系统，帮助用户定期审视和调整自己的目标、习惯和计划

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Periodic Review Provider
final reviewScheduleProvider = FutureProvider<List<ReviewSchedule>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'review_schedules',
    orderBy: 'next_review ASC',
  );
  
  return maps.map((map) => ReviewSchedule.fromMap(map)).toList();
});

final pendingReviewsProvider = FutureProvider<List<PendingReview>>((ref) async {
  // ignore: unused_local_variable
  final db = await ref.watch(databaseProvider.future);
  // ignore: unused_local_variable
  final now = DateTime.now();
  
  final schedules = await ref.watch(reviewScheduleProvider.future);
  final pending = <PendingReview>[];
  
  for (final schedule in schedules) {
    if (schedule.nextReview.isBefore(now)) {
      pending.add(PendingReview(
        schedule: schedule,
        overdueDays: now.difference(schedule.nextReview).inDays,
      ));
    }
  }
  
  return pending;
});

final reviewHistoryProvider = FutureProvider<List<ReviewResult>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'review_history',
    orderBy: 'reviewed_at DESC',
    limit: 20,
  );
  
  return maps.map((map) => ReviewResult.fromMap(map)).toList();
});

class ReviewSchedule {
  final int? id;
  final String name;
  final String type;
  final String frequency;
  final DateTime nextReview;
  final DateTime? lastReview;
  final String? config;

  ReviewSchedule({
    this.id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.nextReview,
    this.lastReview,
    this.config,
  });

  factory ReviewSchedule.fromMap(Map<String, dynamic> map) {
    return ReviewSchedule(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      frequency: map['frequency'] as String,
      nextReview: DateTime.parse(map['next_review'] as String),
      lastReview: map['last_review'] != null
          ? DateTime.parse(map['last_review'] as String)
          : null,
      config: map['config'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'frequency': frequency,
      'next_review': nextReview.toIso8601String(),
      'last_review': lastReview?.toIso8601String(),
      'config': config,
    };
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'biweekly':
        return '双周';
      case 'monthly':
        return '每月';
      case 'quarterly':
        return '每季度';
      default:
        return frequency;
    }
  }

  IconData get icon {
    switch (type) {
      case 'goal':
        return Icons.flag;
      case 'habit':
        return Icons.check_circle;
      case 'project':
        return Icons.work;
      case 'mood':
        return Icons.mood;
      case 'general':
        return Icons.rate_review;
      default:
        return Icons.assignment;
    }
  }
}

class PendingReview {
  final ReviewSchedule schedule;
  final int overdueDays;

  PendingReview({
    required this.schedule,
    required this.overdueDays,
  });
}

class ReviewResult {
  final int? id;
  final String scheduleType;
  final String summary;
  final int completedItems;
  final int pendingItems;
  final String? notes;
  final DateTime reviewedAt;

  ReviewResult({
    this.id,
    required this.scheduleType,
    required this.summary,
    required this.completedItems,
    required this.pendingItems,
    this.notes,
    required this.reviewedAt,
  });

  factory ReviewResult.fromMap(Map<String, dynamic> map) {
    return ReviewResult(
      id: map['id'] as int?,
      scheduleType: map['schedule_type'] as String,
      summary: map['summary'] as String? ?? '',
      completedItems: map['completed_items'] as int? ?? 0,
      pendingItems: map['pending_items'] as int? ?? 0,
      notes: map['notes'] as String?,
      reviewedAt: DateTime.parse(map['reviewed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schedule_type': scheduleType,
      'summary': summary,
      'completed_items': completedItems,
      'pending_items': pendingItems,
      'notes': notes,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }
}

// Predefined review templates
class ReviewTemplates {
  static final dailyReview = ReviewTemplate(
    name: '每日回顾',
    type: 'general',
    frequency: 'daily',
    questions: [
      '今天完成了哪些重要事项？',
      '有什么遗憾或可以改进的地方？',
      '明天最重要的一件事是什么？',
    ],
  );

  static final weeklyReview = ReviewTemplate(
    name: '周回顾',
    type: 'general',
    frequency: 'weekly',
    questions: [
      '本周的主要成就有哪些？',
      '哪些目标取得了进展？',
      '遇到了哪些挑战？如何克服的？',
      '下周的重点是什么？',
    ],
  );

  static final monthlyReview = ReviewTemplate(
    name: '月回顾',
    type: 'general',
    frequency: 'monthly',
    questions: [
      '本月最有成就感的一件事？',
      '目标完成进度如何？',
      '学到了什么新东西？',
      '下个月的三个最重要目标？',
    ],
  );

  static final goalReview = ReviewTemplate(
    name: '目标检视',
    type: 'goal',
    frequency: 'weekly',
    questions: [
      '目标进展如何？',
      '是否需要调整计划？',
      '障碍是什么？如何克服？',
    ],
  );

  static final habitReview = ReviewTemplate(
    name: '习惯评估',
    type: 'habit',
    frequency: 'weekly',
    questions: [
      '哪些习惯执行得好？',
      '哪些习惯没有坚持？为什么？',
      '需要添加或移除哪些习惯？',
    ],
  );
}

class ReviewTemplate {
  final String name;
  final String type;
  final String frequency;
  final List<String> questions;

  ReviewTemplate({
    required this.name,
    required this.type,
    required this.frequency,
    required this.questions,
  });
}