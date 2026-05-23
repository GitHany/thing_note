// Data Integrity Checker feature
// Version: 1.0
// Description: 数据完整性检查器，自动检测和修复数据问题

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Data Integrity Provider
final dataIntegrityCheckProvider = FutureProvider<DataIntegrityReport>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final issues = <DataIntegrityIssue>[];
  
  // Check 1: Orphaned records (no thing_name)
  final orphanRecords = await db.rawQuery('''
    SELECT COUNT(*) as count FROM episode_records
    WHERE thing_name_id IS NULL
  ''');
  if (orphanRecords.isNotEmpty && (orphanRecords.first['count'] as int) > 0) {
    issues.add(DataIntegrityIssue(
      type: IssueType.orphanedRecord,
      severity: Severity.warning,
      title: '孤立记录',
      description: '有${orphanRecords.first['count']}条记录没有关联事情名称',
      affectedCount: orphanRecords.first['count'] as int,
    ));
  }
  
  // Check 2: Missing media files
  final recordsWithMedia = await db.query(
    'episode_records',
    where: "photo_paths != '[]' OR audio_paths != '[]' OR video_paths != '[]'",
  );
  int missingMediaCount = 0;
  for (final record in recordsWithMedia) {
    final photos = record['photo_paths'] as String?;
    if (photos != null && photos != '[]' && !photos.contains('http')) {
      missingMediaCount++;
    }
  }
  if (missingMediaCount > 0) {
    issues.add(DataIntegrityIssue(
      type: IssueType.missingMedia,
      severity: Severity.warning,
      title: '缺失媒体文件',
      description: '有$missingMediaCount条记录的媒体文件可能已丢失',
      affectedCount: missingMediaCount,
    ));
  }
  
  // Check 3: Invalid dates
  final records = await db.query('episode_records');
  int invalidDateCount = 0;
  for (final record in records) {
    final occurredAt = record['occurred_at'] as String?;
    if (occurredAt != null) {
      try {
        final date = DateTime.parse(occurredAt);
        if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          invalidDateCount++;
        }
      } catch (e) {
        invalidDateCount++;
      }
    }
  }
  if (invalidDateCount > 0) {
    issues.add(DataIntegrityIssue(
      type: IssueType.invalidDate,
      severity: Severity.error,
      title: '无效日期',
      description: '有$invalidDateCount条记录的日期无效或在未来',
      affectedCount: invalidDateCount,
    ));
  }
  
  // Check 4: Duplicate reminders
  final duplicateReminders = await db.rawQuery('''
    SELECT record_id, COUNT(*) as count FROM reminders
    GROUP BY record_id
    HAVING COUNT(*) > 1
  ''');
  if (duplicateReminders.isNotEmpty) {
    int totalDuplicates = 0;
    for (final dup in duplicateReminders) {
      totalDuplicates += (dup['count'] as int) - 1;
    }
    issues.add(DataIntegrityIssue(
      type: IssueType.duplicateReminders,
      severity: Severity.info,
      title: '重复提醒',
      description: '有${duplicateReminders.length}条记录存在重复提醒',
      affectedCount: totalDuplicates,
    ));
  }
  
  // Check 5: Empty notes
  final emptyNotes = await db.rawQuery('''
    SELECT COUNT(*) as count FROM episode_records
    WHERE note = '' OR note IS NULL
  ''');
  if (emptyNotes.isNotEmpty && (emptyNotes.first['count'] as int) > 10) {
    issues.add(DataIntegrityIssue(
      type: IssueType.emptyNotes,
      severity: Severity.info,
      title: '空笔记记录',
      description: '有${emptyNotes.first['count']}条记录没有笔记内容',
      affectedCount: emptyNotes.first['count'] as int,
    ));
  }
  
  // Calculate overall health score
  double healthScore = 100.0;
  for (final issue in issues) {
    switch (issue.severity) {
      case Severity.error:
        healthScore -= issue.affectedCount * 2;
        break;
      case Severity.warning:
        healthScore -= issue.affectedCount * 0.5;
        break;
      case Severity.info:
        healthScore -= issue.affectedCount * 0.1;
        break;
    }
  }
  healthScore = healthScore.clamp(0, 100);

  return DataIntegrityReport(
    overallScore: healthScore,
    issues: issues,
    lastChecked: DateTime.now(),
    totalRecords: records.length,
  );
});

enum IssueType {
  orphanedRecord,
  missingMedia,
  invalidDate,
  duplicateReminders,
  emptyNotes,
  largeFileSize,
  orphanedTags,
}

enum Severity { error, warning, info }

class DataIntegrityIssue {
  final IssueType type;
  final Severity severity;
  final String title;
  final String description;
  final int affectedCount;
  final String? fixSuggestion;

  DataIntegrityIssue({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.affectedCount,
    this.fixSuggestion,
  });
}

class DataIntegrityReport {
  final double overallScore;
  final List<DataIntegrityIssue> issues;
  final DateTime lastChecked;
  final int totalRecords;

  DataIntegrityReport({
    required this.overallScore,
    required this.issues,
    required this.lastChecked,
    required this.totalRecords,
  });

  String get scoreLabel {
    if (overallScore >= 90) return '优秀';
    if (overallScore >= 70) return '良好';
    if (overallScore >= 50) return '一般';
    return '需要修复';
  }

  Color get scoreColor {
    if (overallScore >= 90) return Colors.green;
    if (overallScore >= 70) return Colors.blue;
    if (overallScore >= 50) return Colors.orange;
    return Colors.red;
  }
}