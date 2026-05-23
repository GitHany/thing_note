class VehicleEntry {
  final int? id;
  final String name;
  final String? brand;
  final String? model;
  final String? licensePlate;
  final int purchaseYear;
  final int currentMileage;
  final String? color;
  final String? vin;
  final String? insuranceExpiry;
  final String? inspectionExpiry;
  final String? note;
  final String createdAt;
  final String? updatedAt;

  VehicleEntry({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.licensePlate,
    this.purchaseYear = 2020,
    this.currentMileage = 0,
    this.color,
    this.vin,
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'license_plate': licensePlate,
      'purchase_year': purchaseYear,
      'current_mileage': currentMileage,
      'color': color,
      'vin': vin,
      'insurance_expiry': insuranceExpiry,
      'inspection_expiry': inspectionExpiry,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory VehicleEntry.fromMap(Map<String, dynamic> map) {
    return VehicleEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      licensePlate: map['license_plate'] as String?,
      purchaseYear: map['purchase_year'] as int? ?? 2020,
      currentMileage: map['current_mileage'] as int? ?? 0,
      color: map['color'] as String?,
      vin: map['vin'] as String?,
      insuranceExpiry: map['insurance_expiry'] as String?,
      inspectionExpiry: map['inspection_expiry'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  VehicleEntry copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? licensePlate,
    int? purchaseYear,
    int? currentMileage,
    String? color,
    String? vin,
    String? insuranceExpiry,
    String? inspectionExpiry,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return VehicleEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      licensePlate: licensePlate ?? this.licensePlate,
      purchaseYear: purchaseYear ?? this.purchaseYear,
      currentMileage: currentMileage ?? this.currentMileage,
      color: color ?? this.color,
      vin: vin ?? this.vin,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FuelRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final int mileage;
  final double amount;
  final double liters;
  final String? station;
  final String? note;
  final String createdAt;

  FuelRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.amount,
    required this.liters,
    this.station,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'amount': amount,
      'liters': liters,
      'station': station,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      date: DateTime.parse(map['date'] as String),
      mileage: map['mileage'] as int,
      amount: (map['amount'] as num).toDouble(),
      liters: (map['liters'] as num).toDouble(),
      station: map['station'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}