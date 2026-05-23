import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/relationship_models.dart';

final relationshipRepositoryProvider = Provider<RelationshipRepository>((ref) {
  return RelationshipRepository(ref.watch(databaseProvider).value!);
});

class RelationshipRepository {
  final Database _db;

  RelationshipRepository(this._db);

  Future<int> insertRelationship(Relationship relationship) async {
    return await _db.insert('relationships', relationship.toMap());
  }

  Future<List<Relationship>> getAllRelationships() async {
    final maps = await _db.query('relationships', orderBy: 'last_contact_date DESC');
    return maps.map((m) => Relationship.fromMap(m)).toList();
  }

  Future<int> updateRelationship(Relationship relationship) async {
    return await _db.update(
      'relationships',
      relationship.toMap(),
      where: 'id = ?',
      whereArgs: [relationship.id],
    );
  }

  Future<int> deleteRelationship(int id) async {
    return await _db.delete('relationships', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertInteraction(RelationshipInteraction interaction) async {
    return await _db.insert('relationship_interactions', interaction.toMap());
  }

  Future<List<RelationshipInteraction>> getInteractionsByRelationship(int relationshipId) async {
    final maps = await _db.query(
      'relationship_interactions',
      where: 'relationship_id = ?',
      whereArgs: [relationshipId],
      orderBy: 'interaction_date DESC',
    );
    return maps.map((m) => RelationshipInteraction.fromMap(m)).toList();
  }

  Future<List<Relationship>> getNeedAttention() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final maps = await _db.query(
      'relationships',
      where: 'last_contact_date IS NULL OR last_contact_date < ?',
      whereArgs: [sevenDaysAgo.toIso8601String()],
      orderBy: 'last_contact_date ASC',
    );
    return maps.map((m) => Relationship.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getRelationshipStats() async {
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        AVG(closeness_level) as avg_closeness,
        SUM(contact_frequency) as total_contacts
      FROM relationships
    ''');
    return result.first;
  }
}