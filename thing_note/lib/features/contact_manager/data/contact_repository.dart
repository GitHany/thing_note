import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/contact_entry.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref);
});

class ContactRepository {
  final Ref _ref;

  ContactRepository(this._ref);

  Future<int> insertContact(ContactEntry contact) async {
    final db = await _ref.read(databaseProvider.future);
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<ContactEntry>> getAllContacts() async {
    final db = await _ref.read(databaseProvider.future);
    final maps = await db.query(
      'contacts',
      orderBy: 'name ASC',
    );
    return maps.map((map) => ContactEntry.fromMap(map)).toList();
  }

  Future<List<ContactEntry>> searchContacts(String query) async {
    final db = await _ref.read(databaseProvider.future);
    final maps = await db.query(
      'contacts',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ? OR company LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ContactEntry.fromMap(map)).toList();
  }

  Future<List<ContactEntry>> getContactsByGroup(String group) async {
    final db = await _ref.read(databaseProvider.future);
    final maps = await db.query(
      'contacts',
      where: 'group_name = ?',
      whereArgs: [group],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ContactEntry.fromMap(map)).toList();
  }

  Future<List<ContactEntry>> getFavoriteContacts() async {
    final db = await _ref.read(databaseProvider.future);
    final maps = await db.query(
      'contacts',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return maps.map((map) => ContactEntry.fromMap(map)).toList();
  }

  Future<int> updateContact(ContactEntry contact) async {
    final db = await _ref.read(databaseProvider.future);
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _ref.read(databaseProvider.future);
    return await db.update(
      'contacts',
      {'is_favorite': isFavorite ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}