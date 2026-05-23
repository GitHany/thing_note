/// Data health check issue
class HealthIssue {
  final HealthIssueType type;
  final String title;
  final String description;
  final String? affectedId;
  final HealthSeverity severity;
  final DateTime detectedAt;
  final bool canAutoFix;
  final bool isFixed;

  HealthIssue({
    required this.type,
    required this.title,
    required this.description,
    this.affectedId,
    required this.severity,
    required this.detectedAt,
    this.canAutoFix = false,
    this.isFixed = false,
  });
}

enum HealthIssueType {
  missingPhoto,
  missingAudio,
  missingVideo,
  missingDocument,
  orphanedRecord,
  duplicateRecord,
  invalidDate,
  largeFile,
  missingThingName,
}

enum HealthSeverity {
  critical,
  warning,
  info,
}

/// Overall health status
class DataHealthStatus {
  final int totalRecords;
  final int healthyRecords;
  final int issueCount;
  final List<HealthIssue> criticalIssues;
  final List<HealthIssue> warnings;
  final List<HealthIssue> infoMessages;
  final DateTime lastChecked;
  final bool isHealthy;

  DataHealthStatus({
    required this.totalRecords,
    required this.healthyRecords,
    required this.issueCount,
    required this.criticalIssues,
    required this.warnings,
    required this.infoMessages,
    required this.lastChecked,
  }) : isHealthy = criticalIssues.isEmpty;
}