/// Daily Progress Snapshot Model
class DailyProgressSnapshot {
  final int? id;
  final DateTime snapshotDate;
  final int completedItems;
  final int totalItems;
  final double progressPercent;
  final String? highlights;
  final String? weekComparison;
  final DateTime createdAt;

  DailyProgressSnapshot({
    this.id,
    required this.snapshotDate,
    this.completedItems = 0,
    this.totalItems = 0,
    this.progressPercent = 0,
    this.highlights,
    this.weekComparison,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'snapshot_date': _formatDate(snapshotDate),
      'completed_items': completedItems,
      'total_items': totalItems,
      'progress_percent': progressPercent,
      'highlights': highlights,
      'week_comparison': weekComparison,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyProgressSnapshot.fromMap(Map<String, dynamic> map) {
    return DailyProgressSnapshot(
      id: map['id'] as int?,
      snapshotDate: DateTime.parse(map['snapshot_date'] as String),
      completedItems: map['completed_items'] as int? ?? 0,
      totalItems: map['total_items'] as int? ?? 0,
      progressPercent: (map['progress_percent'] as num?)?.toDouble() ?? 0,
      highlights: map['highlights'] as String?,
      weekComparison: map['week_comparison'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyProgressSnapshot copyWith({
    int? id,
    DateTime? snapshotDate,
    int? completedItems,
    int? totalItems,
    double? progressPercent,
    String? highlights,
    String? weekComparison,
    DateTime? createdAt,
  }) {
    return DailyProgressSnapshot(
      id: id ?? this.id,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      completedItems: completedItems ?? this.completedItems,
      totalItems: totalItems ?? this.totalItems,
      progressPercent: progressPercent ?? this.progressPercent,
      highlights: highlights ?? this.highlights,
      weekComparison: weekComparison ?? this.weekComparison,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get progressStatus {
    if (progressPercent >= 100) return '已完成';
    if (progressPercent >= 75) return '进展良好';
    if (progressPercent >= 50) return '过半';
    if (progressPercent >= 25) return '刚开始';
    return '待开始';
  }
}