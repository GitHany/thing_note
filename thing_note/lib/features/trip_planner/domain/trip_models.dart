/// 旅行规划领域模型
class Trip {
  final int? id;
  final String title;
  final String? destination;
  final DateTime startDate;
  final DateTime? endDate;
  final int participants;
  final double? budget;
  final String? coverImagePath;
  final String status; // planning, ongoing, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    this.id,
    required this.title,
    this.destination,
    required this.startDate,
    this.endDate,
    this.participants = 1,
    this.budget,
    this.coverImagePath,
    this.status = 'planning',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'participants': participants,
      'budget': budget,
      'cover_image_path': coverImagePath,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      title: map['title'] as String,
      destination: map['destination'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      participants: map['participants'] as int? ?? 1,
      budget: map['budget'] as double?,
      coverImagePath: map['cover_image_path'] as String?,
      status: map['status'] as String? ?? 'planning',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Trip copyWith({
    int? id,
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? participants,
    double? budget,
    String? coverImagePath,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      budget: budget ?? this.budget,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 旅行行程项
class TripItinerary {
  final int? id;
  final int tripId;
  final String title;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? note;
  final int orderIndex;

  TripItinerary({
    this.id,
    required this.tripId,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.note,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'title': title,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'note': note,
      'order_index': orderIndex,
    };
  }

  factory TripItinerary.fromMap(Map<String, dynamic> map) {
    return TripItinerary(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      note: map['note'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}

/// 旅行预订
class TripBooking {
  final int? id;
  final int tripId;
  final String bookingType; // flight, hotel, car, ticket, other
  final String title;
  final String? provider;
  final double? amount;
  final String currency;
  final DateTime? bookingDate;
  final String status;
  final String? confirmationCode;
  final String? note;

  TripBooking({
    this.id,
    required this.tripId,
    required this.bookingType,
    required this.title,
    this.provider,
    this.amount,
    this.currency = 'CNY',
    this.bookingDate,
    this.status = 'pending',
    this.confirmationCode,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'booking_type': bookingType,
      'title': title,
      'provider': provider,
      'amount': amount,
      'currency': currency,
      'booking_date': bookingDate?.toIso8601String(),
      'status': status,
      'confirmation_code': confirmationCode,
      'note': note,
    };
  }

  factory TripBooking.fromMap(Map<String, dynamic> map) {
    return TripBooking(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      bookingType: map['booking_type'] as String,
      title: map['title'] as String,
      provider: map['provider'] as String?,
      amount: map['amount'] as double?,
      currency: map['currency'] as String? ?? 'CNY',
      bookingDate: map['booking_date'] != null ? DateTime.parse(map['booking_date'] as String) : null,
      status: map['status'] as String? ?? 'pending',
      confirmationCode: map['confirmation_code'] as String?,
      note: map['note'] as String?,
    );
  }
}

/// 旅行支出
class TripExpense {
  final int? id;
  final int tripId;
  final String category;
  final double amount;
  final String currency;
  final int? paidBy;
  final String splitType;
  final String? note;
  final DateTime date;

  TripExpense({
    this.id,
    required this.tripId,
    required this.category,
    required this.amount,
    this.currency = 'CNY',
    this.paidBy,
    this.splitType = 'equal',
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'category': category,
      'amount': amount,
      'currency': currency,
      'paid_by': paidBy,
      'split_type': splitType,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory TripExpense.fromMap(Map<String, dynamic> map) {
    return TripExpense(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      category: map['category'] as String,
      amount: map['amount'] as double,
      currency: map['currency'] as String? ?? 'CNY',
      paidBy: map['paid_by'] as int?,
      splitType: map['split_type'] as String? ?? 'equal',
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }
}