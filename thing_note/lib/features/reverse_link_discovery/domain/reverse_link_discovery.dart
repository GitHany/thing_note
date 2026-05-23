// Reverse Link Discovery Models
// 反向链接发现功能 - 发现哪些记录链接到了当前记录

class LinkDiscovery {
  final int? id;
  final int targetRecordId;
  final List<LinkedRecord> linkedRecords;
  final DateTime discoveredAt;

  LinkDiscovery({
    this.id,
    required this.targetRecordId,
    required this.linkedRecords,
    required this.discoveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_record_id': targetRecordId,
      'linked_records': linkedRecords.map((r) => '${r.recordId}:${r.linkType}').join(','),
      'discovered_at': discoveredAt.toIso8601String(),
    };
  }

  factory LinkDiscovery.fromMap(Map<String, dynamic> map) {
    final linksStr = map['linked_records'] as String? ?? '';
    final linkedRecords = <LinkedRecord>[];
    for (final link in linksStr.split(',')) {
      if (link.contains(':')) {
        final parts = link.split(':');
        linkedRecords.add(LinkedRecord(
          recordId: int.tryParse(parts[0]) ?? 0,
          linkType: parts.length > 1 ? parts[1] : 'unknown',
        ));
      }
    }
    return LinkDiscovery(
      id: map['id'] as int?,
      targetRecordId: map['target_record_id'] as int,
      linkedRecords: linkedRecords,
      discoveredAt: DateTime.parse(map['discovered_at'] as String),
    );
  }
}

class LinkedRecord {
  final int recordId;
  final String? note;
  final String linkType;
  final DateTime? linkedAt;

  LinkedRecord({
    required this.recordId,
    this.note,
    this.linkType = 'related',
    this.linkedAt,
  });
}

class BacklinkSuggestion {
  final int? id;
  final int sourceRecordId;
  final int targetRecordId;
  final String reason;
  final double relevanceScore;
  final bool isIgnored;
  final DateTime createdAt;

  BacklinkSuggestion({
    this.id,
    required this.sourceRecordId,
    required this.targetRecordId,
    required this.reason,
    this.relevanceScore = 0,
    this.isIgnored = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_record_id': sourceRecordId,
      'target_record_id': targetRecordId,
      'reason': reason,
      'relevance_score': relevanceScore,
      'is_ignored': isIgnored ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BacklinkSuggestion.fromMap(Map<String, dynamic> map) {
    return BacklinkSuggestion(
      id: map['id'] as int?,
      sourceRecordId: map['source_record_id'] as int,
      targetRecordId: map['target_record_id'] as int,
      reason: map['reason'] as String,
      relevanceScore: (map['relevance_score'] as num?)?.toDouble() ?? 0,
      isIgnored: (map['is_ignored'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class LinkNetwork {
  final int? id;
  final int centralRecordId;
  final List<NetworkNode> nodes;
  final List<NetworkEdge> edges;
  final DateTime generatedAt;

  LinkNetwork({
    this.id,
    required this.centralRecordId,
    required this.nodes,
    required this.edges,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'central_record_id': centralRecordId,
      'nodes': nodes.map((n) => '${n.recordId}:${n.label}').join(','),
      'edges': edges.map((e) => '${e.sourceId}:${e.targetId}:${e.weight}').join(';'),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class NetworkNode {
  final int recordId;
  final String label;
  final int weight;

  NetworkNode({
    required this.recordId,
    required this.label,
    this.weight = 1,
  });
}

class NetworkEdge {
  final int sourceId;
  final int targetId;
  final double weight;

  NetworkEdge({
    required this.sourceId,
    required this.targetId,
    this.weight = 1.0,
  });
}