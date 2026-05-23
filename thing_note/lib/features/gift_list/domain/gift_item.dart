/// 礼物清单数据模型
class GiftItem {
  final int? id;
  final String recipient;
  final String? occasion;
  final String title;
  final String? description;
  final double? price;
  final String? currency;
  final String? url;
  final String? imageUrl;
  final GiftPriority priority;
  final GiftStatus status;
  final String? note;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GiftItem({
    this.id,
    required this.recipient,
    this.occasion,
    required this.title,
    this.description,
    this.price,
    this.currency = 'CNY',
    this.url,
    this.imageUrl,
    this.priority = GiftPriority.medium,
    this.status = GiftStatus.pending,
    this.note,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  GiftItem copyWith({
    int? id,
    String? recipient,
    String? occasion,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? url,
    String? imageUrl,
    GiftPriority? priority,
    GiftStatus? status,
    String? note,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftItem(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      occasion: occasion ?? this.occasion,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipient': recipient,
      'occasion': occasion,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'url': url,
      'image_url': imageUrl,
      'priority': priority.name,
      'status': status.name,
      'note': note,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GiftItem.fromMap(Map<String, dynamic> map) {
    return GiftItem(
      id: map['id'] as int?,
      recipient: map['recipient'] as String,
      occasion: map['occasion'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      currency: map['currency'] as String? ?? 'CNY',
      url: map['url'] as String?,
      imageUrl: map['image_url'] as String?,
      priority: GiftPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => GiftPriority.medium,
      ),
      status: GiftStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GiftStatus.pending,
      ),
      note: map['note'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum GiftPriority { low, medium, high, urgent }

enum GiftStatus { pending, purchased, given }

extension GiftPriorityExtension on GiftPriority {
  String get displayName {
    switch (this) {
      case GiftPriority.low: return '低';
      case GiftPriority.medium: return '中';
      case GiftPriority.high: return '高';
      case GiftPriority.urgent: return '紧急';
    }
  }
}

extension GiftStatusExtension on GiftStatus {
  String get displayName {
    switch (this) {
      case GiftStatus.pending: return '待购';
      case GiftStatus.purchased: return '已购';
      case GiftStatus.given: return '已送';
    }
  }
}