import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_place_cluster/domain/place_cluster.dart';

final placeClusterRepositoryProvider = Provider<PlaceClusterRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PlaceClusterRepository(dbAsync);
});

class PlaceClusterRepository {
  final AsyncValue<Database> _dbAsync;

  PlaceClusterRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<PlaceCluster>> getAllClusters() async {
    final db = await _db;
    final result = await db.query(
      'smart_place_clusters',
      orderBy: 'visit_count DESC',
    );
    return result.map((map) => PlaceCluster.fromMap(map)).toList();
  }

  Future<List<PlaceCluster>> getTopClusters({int limit = 10}) async {
    final db = await _db;
    final result = await db.query(
      'smart_place_clusters',
      orderBy: 'visit_count DESC',
      limit: limit,
    );
    return result.map((map) => PlaceCluster.fromMap(map)).toList();
  }

  Future<PlaceCluster?> getClusterById(int id) async {
    final db = await _db;
    final result = await db.query(
      'smart_place_clusters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return PlaceCluster.fromMap(result.first);
  }

  Future<int> insertCluster(PlaceCluster cluster) async {
    final db = await _db;
    return await db.insert('smart_place_clusters', cluster.toMap()..remove('id'));
  }

  Future<void> updateCluster(PlaceCluster cluster) async {
    final db = await _db;
    await db.update(
      'smart_place_clusters',
      cluster.toMap(),
      where: 'id = ?',
      whereArgs: [cluster.id],
    );
  }

  Future<void> deleteCluster(int id) async {
    final db = await _db;
    await db.delete(
      'smart_place_clusters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementVisitCount(int clusterId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_place_clusters SET visit_count = visit_count + 1 WHERE id = ?',
      [clusterId],
    );
  }

  Future<void> addVisitHistory(PlaceVisitHistory history) async {
    final db = await _db;
    await db.insert('place_visit_history', history.toMap()..remove('id'));
    
    await incrementVisitCount(history.clusterId);
    
    await _updateAverageDuration(history.clusterId);
  }

  Future<void> _updateAverageDuration(int clusterId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT AVG(duration_minutes) as avg_duration 
      FROM place_visit_history 
      WHERE cluster_id = ? AND duration_minutes IS NOT NULL
      ''',
      [clusterId],
    );
    
    if (result.isNotEmpty && result.first['avg_duration'] != null) {
      final avgDuration = (result.first['avg_duration'] as num).round();
      await db.update(
        'smart_place_clusters',
        {'avg_duration_minutes': avgDuration},
        where: 'id = ?',
        whereArgs: [clusterId],
      );
    }
  }

  Future<List<PlaceVisitHistory>> getVisitHistory(int clusterId, {int limit = 20}) async {
    final db = await _db;
    final result = await db.query(
      'place_visit_history',
      where: 'cluster_id = ?',
      whereArgs: [clusterId],
      orderBy: 'arrived_at DESC',
      limit: limit,
    );
    return result.map((map) => PlaceVisitHistory.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getClusterStatistics() async {
    final db = await _db;
    
    final totalClusters = await db.rawQuery(
      'SELECT COUNT(*) as count FROM smart_place_clusters',
    );
    
    final totalVisits = await db.rawQuery(
      'SELECT SUM(visit_count) as total FROM smart_place_clusters',
    );
    
    final topTypes = await db.rawQuery(
      '''
      SELECT cluster_type, COUNT(*) as count 
      FROM smart_place_clusters 
      GROUP BY cluster_type 
      ORDER BY count DESC 
      LIMIT 5
      ''',
    );
    
    return {
      'total_clusters': (totalClusters.first['count'] as int?) ?? 0,
      'total_visits': (totalVisits.first['total'] as int?) ?? 0,
      'top_types': topTypes,
    };
  }
}
