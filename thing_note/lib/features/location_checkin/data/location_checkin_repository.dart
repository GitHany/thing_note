import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/location_checkin/domain/location_checkin.dart';

class LocationCheckinRepository {
  final Ref _ref;

  LocationCheckinRepository(this._ref);

  Future<List<LocationCheckin>> getAllCheckins() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'location_checkins',
      orderBy: 'check_in_at DESC',
    );
    return result.map((e) => LocationCheckin.fromMap(e)).toList();
  }

  Future<List<LocationCheckin>> getRecentCheckins({int limit = 20}) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'location_checkins',
      orderBy: 'check_in_at DESC',
      limit: limit,
    );
    return result.map((e) => LocationCheckin.fromMap(e)).toList();
  }

  Future<List<LocationCheckin>> getCheckinsByPlace(String placeName) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'location_checkins',
      where: 'place_name LIKE ?',
      whereArgs: ['%$placeName%'],
      orderBy: 'check_in_at DESC',
    );
    return result.map((e) => LocationCheckin.fromMap(e)).toList();
  }

  Future<int> insertCheckin(LocationCheckin checkin) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('location_checkins', checkin.toMap()..remove('id'));
  }

  Future<int> deleteCheckin(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('location_checkins', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getPlaceStats() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.rawQuery('''
      SELECT place_name, COUNT(*) as count
      FROM location_checkins
      GROUP BY place_name
      ORDER BY count DESC
      LIMIT 10
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['place_name'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<List<Map<String, dynamic>>> getFrequentPlaces({int limit = 5}) async {
    final db = await _ref.read(databaseProvider.future);
    return db.rawQuery('''
      SELECT place_name, latitude, longitude, COUNT(*) as count
      FROM location_checkins
      GROUP BY place_name
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
  }
}