import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/location_smart/domain/smart_location.dart';

class SmartLocationRepository {
  final Database db;

  SmartLocationRepository(this.db);

  Future<int> insertLocation(SmartLocation location) async {
    return await db.insert('smart_locations', location.toMap());
  }

  Future<List<SmartLocation>> getAllLocations() async {
    final maps = await db.query(
      'smart_locations',
      orderBy: 'visit_count DESC',
    );
    return maps.map((m) => SmartLocation.fromMap(m)).toList();
  }

  Future<List<SmartLocation>> getFavoriteLocations() async {
    final maps = await db.query(
      'smart_locations',
      where: 'is_favorite = 1',
      orderBy: 'visit_count DESC',
    );
    return maps.map((m) => SmartLocation.fromMap(m)).toList();
  }

  Future<List<SmartLocation>> getTopLocations({int limit = 10}) async {
    final maps = await db.query(
      'smart_locations',
      orderBy: 'visit_count DESC',
      limit: limit,
    );
    return maps.map((m) => SmartLocation.fromMap(m)).toList();
  }

  Future<SmartLocation?> getLocation(int id) async {
    final maps = await db.query(
      'smart_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SmartLocation.fromMap(maps.first);
  }

  Future<SmartLocation?> findNearbyLocation(double lat, double lng, double radiusMeters) async {
    // Simple distance calculation using Haversine approximation
    final maps = await db.rawQuery('''
      SELECT * FROM smart_locations
      WHERE (latitude - ?) * (latitude - ?) + (longitude - ?) * (longitude - ?) < ?
      ORDER BY visit_count DESC
      LIMIT 1
    ''', [lat, lat, lng, lng, (radiusMeters / 111000) * (radiusMeters / 111000)]);

    if (maps.isEmpty) return null;
    return SmartLocation.fromMap(maps.first);
  }

  Future<int> updateLocation(SmartLocation location) async {
    return await db.update(
      'smart_locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(int id) async {
    return await db.delete(
      'smart_locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id) async {
    final location = await getLocation(id);
    if (location != null) {
      return await db.update(
        'smart_locations',
        {'is_favorite': location.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  Future<void> recordVisit(int locationId, int durationSec) async {
    await db.rawUpdate('''
      UPDATE smart_locations
      SET visit_count = visit_count + 1,
          total_duration_sec = total_duration_sec + ?,
          last_visited_at = ?
      WHERE id = ?
    ''', [durationSec, DateTime.now().toIso8601String(), locationId]);
  }

  // Check-ins
  Future<int> insertCheckIn(LocationCheckIn checkIn) async {
    return await db.insert('location_check_ins', checkIn.toMap());
  }

  Future<int> updateCheckOut(int checkInId) async {
    return await db.update(
      'location_check_ins',
      {'check_out_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [checkInId],
    );
  }

  Future<List<LocationCheckIn>> getCheckInsForLocation(int locationId) async {
    final maps = await db.query(
      'location_check_ins',
      where: 'location_id = ?',
      whereArgs: [locationId],
      orderBy: 'check_in_at DESC',
    );
    return maps.map((m) => LocationCheckIn.fromMap(m)).toList();
  }

  Future<List<LocationCheckIn>> getRecentCheckIns({int limit = 20}) async {
    final maps = await db.query(
      'location_check_ins',
      orderBy: 'check_in_at DESC',
      limit: limit,
    );
    return maps.map((m) => LocationCheckIn.fromMap(m)).toList();
  }
}