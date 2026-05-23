import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class Place {
  final int? id;
  final String name;
  final String? alias;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? icon;
  final String color;
  final String? category;
  final int visitCount;
  final int totalDurationSec;
  final DateTime createdAt;

  Place({
    this.id,
    required this.name,
    this.alias,
    this.latitude,
    this.longitude,
    this.address,
    this.icon,
    this.color = '#607D8B',
    this.category,
    this.visitCount = 0,
    this.totalDurationSec = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'alias': alias,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'icon': icon,
      'color': color,
      'category': category,
      'visit_count': visitCount,
      'total_duration_sec': totalDurationSec,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as int?,
      name: map['name'] as String,
      alias: map['alias'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String? ?? '#607D8B',
      category: map['category'] as String?,
      visitCount: map['visit_count'] as int? ?? 0,
      totalDurationSec: map['total_duration_sec'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Place copyWith({
    int? id,
    String? name,
    String? alias,
    double? latitude,
    double? longitude,
    String? address,
    String? icon,
    String? color,
    String? category,
    int? visitCount,
    int? totalDurationSec,
    DateTime? createdAt,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      visitCount: visitCount ?? this.visitCount,
      totalDurationSec: totalDurationSec ?? this.totalDurationSec,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PlaceRepository {
  final Database _db;

  PlaceRepository(this._db);

  Future<Database> get _dbFuture async => _db;

  Future<int> insert(Place place) async {
    final db = await _dbFuture;
    return db.insert('places', place.toMap()..remove('id'));
  }

  Future<int> update(Place place) async {
    final db = await _dbFuture;
    return db.update(
      'places',
      place.toMap(),
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbFuture;
    return db.delete('places', where: 'id = ?', whereArgs: [id]);
  }

  Future<Place?> getById(int id) async {
    final db = await _dbFuture;
    final results = await db.query(
      'places',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Place.fromMap(results.first);
  }

  Future<List<Place>> getAll() async {
    final db = await _dbFuture;
    final results = await db.query('places', orderBy: 'visit_count DESC');
    return results.map((e) => Place.fromMap(e)).toList();
  }

  Future<List<Place>> getByCategory(String category) async {
    final db = await _dbFuture;
    final results = await db.query(
      'places',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'visit_count DESC',
    );
    return results.map((e) => Place.fromMap(e)).toList();
  }

  Future<List<Place>> getFrequent({int limit = 10}) async {
    final db = await _dbFuture;
    final results = await db.query(
      'places',
      orderBy: 'visit_count DESC',
      limit: limit,
    );
    return results.map((e) => Place.fromMap(e)).toList();
  }

  Future<void> incrementVisitCount(int placeId) async {
    final place = await getById(placeId);
    if (place != null) {
      await update(place.copyWith(visitCount: place.visitCount + 1));
    }
  }

  Future<List<String>> getCategories() async {
    final db = await _dbFuture;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM places WHERE category IS NOT NULL ORDER BY category',
    );
    return results.map((e) => e['category'] as String).toList();
  }
}

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return PlaceRepository(db);
});

final placeListProvider = FutureProvider<List<Place>>((ref) async {
  final repo = ref.watch(placeRepositoryProvider);
  return repo.getAll();
});

final frequentPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final repo = ref.watch(placeRepositoryProvider);
  return repo.getFrequent();
});