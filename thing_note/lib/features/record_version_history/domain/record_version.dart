class RecordVersion {
  final int? id;
  final int recordId;
  final int versionNumber;
  final String versionData;
  final String? changeSummary;
  final DateTime createdAt;

  RecordVersion({
    this.id,
    required this.recordId,
    this.versionNumber = 1,
    required this.versionData,
    this.changeSummary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RecordVersion.fromMap(Map<String, dynamic> map) {
    return RecordVersion(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      versionNumber: map['version_number'] as int? ?? 1,
      versionData: map['version_data'] as String,
      changeSummary: map['change_summary'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}