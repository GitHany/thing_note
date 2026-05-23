import 'package:flutter/material.dart';

/// Data Integrity Issue model

class DataIntegrityIssue {
  final int? id;
  final String issueType; // orphaned_record, missing_media, invalid_date, large_file
  final String severity; // low, medium, high, critical
  final String description;
  final String? recordId;
  final String? filePath;
  final DateTime detectedAt;
  final bool isResolved;

  DataIntegrityIssue({
    this.id,
    required this.issueType,
    required this.severity,
    required this.description,
    this.recordId,
    this.filePath,
    DateTime? detectedAt,
    this.isResolved = false,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'issue_type': issueType,
      'severity': severity,
      'description': description,
      'record_id': recordId,
      'file_path': filePath,
      'detected_at': detectedAt.toIso8601String(),
      'is_resolved': isResolved ? 1 : 0,
    };
  }

  factory DataIntegrityIssue.fromMap(Map<String, dynamic> map) {
    return DataIntegrityIssue(
      id: map['id'] as int?,
      issueType: map['issue_type'] as String,
      severity: map['severity'] as String,
      description: map['description'] as String,
      recordId: map['record_id'] as String?,
      filePath: map['file_path'] as String?,
      detectedAt: DateTime.parse(map['detected_at'] as String),
      isResolved: (map['is_resolved'] as int?) == 1,
    );
  }
}

/// Data Health Score
class DataHealthScore {
  final int overallScore; // 0-100
  final int orphanCount;
  final int missingMediaCount;
  final int invalidDateCount;
  final int largeFileCount;
  final List<DataIntegrityIssue> issues;
  final DateTime checkedAt;

  DataHealthScore({
    required this.overallScore,
    required this.orphanCount,
    required this.missingMediaCount,
    required this.invalidDateCount,
    required this.largeFileCount,
    required this.issues,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  String get healthLevel {
    if (overallScore >= 90) return '优秀';
    if (overallScore >= 70) return '良好';
    if (overallScore >= 50) return '一般';
    if (overallScore >= 30) return '较差';
    return '危险';
  }

  Color get healthColor {
    if (overallScore >= 90) return Colors.green;
    if (overallScore >= 70) return Colors.blue;
    if (overallScore >= 50) return Colors.orange;
    if (overallScore >= 30) return Colors.deepOrange;
    return Colors.red;
  }

  factory DataHealthScore.empty() {
    return DataHealthScore(
      overallScore: 100,
      orphanCount: 0,
      missingMediaCount: 0,
      invalidDateCount: 0,
      largeFileCount: 0,
      issues: [],
    );
  }
}