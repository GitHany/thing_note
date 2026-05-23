class CloudSyncQueue {
  final int? id;
  final String entityType; // 'record', 'goal', 'habit', etc.
  final int entityId;
  final String action; // 'create', 'update', 'delete'
  final String? payload;
  final String status; // 'pending', 'syncing', 'completed', 'failed'
  final int retryCount;
  final DateTime? lastAttempt;
  final String? errorMessage;
  final DateTime createdAt;

  CloudSyncQueue({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.payload,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastAttempt,
    this.errorMessage,
    required this.createdAt,
  });

  bool get canRetry => retryCount < 3 && status == 'failed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload': payload,
      'status': status,
      'retry_count': retryCount,
      'last_attempt': lastAttempt?.toIso8601String(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CloudSyncQueue.fromMap(Map<String, dynamic> map) {
    return CloudSyncQueue(
      id: map['id'] as int?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      action: map['action'] as String,
      payload: map['payload'] as String?,
      status: map['status'] as String? ?? 'pending',
      retryCount: map['retry_count'] as int? ?? 0,
      lastAttempt: map['last_attempt'] != null
          ? DateTime.parse(map['last_attempt'] as String)
          : null,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CloudSyncQueue copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? action,
    String? payload,
    String? status,
    int? retryCount,
    DateTime? lastAttempt,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return CloudSyncQueue(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}