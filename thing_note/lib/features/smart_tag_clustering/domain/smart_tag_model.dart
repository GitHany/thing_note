/// Tag Cluster model
class TagCluster {
  final int? id;
  final String clusterName;
  final String? description;
  final List<String> tags;
  final int usageCount;
  final double avgCooccurrence;
  final DateTime lastUsed;
  final DateTime createdAt;

  TagCluster({
    this.id,
    required this.clusterName,
    this.description,
    required this.tags,
    this.usageCount = 0,
    this.avgCooccurrence = 0,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) : lastUsed = lastUsed ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cluster_name': clusterName,
      'description': description,
      'tags': tags.join(','),
      'usage_count': usageCount,
      'avg_cooccurrence': avgCooccurrence,
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TagCluster.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return TagCluster(
      id: map['id'] as int?,
      clusterName: map['cluster_name'] as String,
      description: map['description'] as String?,
      tags: tagsStr != null && tagsStr.isNotEmpty ? tagsStr.split(',') : [],
      usageCount: map['usage_count'] as int? ?? 0,
      avgCooccurrence: (map['avg_cooccurrence'] as num?)?.toDouble() ?? 0,
      lastUsed: DateTime.parse(map['last_used'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Tag Co-occurrence model
class TagCooccurrence {
  final String tag1;
  final String tag2;
  final int cooccurrenceCount;
  final double confidence;

  TagCooccurrence({
    required this.tag1,
    required this.tag2,
    required this.cooccurrenceCount,
    required this.confidence,
  });
}

/// Tag Cluster Suggestion
class TagClusterSuggestion {
  final List<String> tags;
  final String? suggestedClusterName;
  final double confidence;
  final String reason;

  TagClusterSuggestion({
    required this.tags,
    this.suggestedClusterName,
    required this.confidence,
    required this.reason,
  });
}