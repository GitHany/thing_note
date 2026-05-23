import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/social_accountability/domain/accountability.dart';

final socialAccountabilityRepositoryProvider = Provider<SocialAccountabilityRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SocialAccountabilityRepository(dbAsync);
});

final accountabilityGroupsProvider = StateNotifierProvider<AccountabilityGroupsNotifier, AsyncValue<List<AccountabilityGroup>>>((ref) {
  final repository = ref.watch(socialAccountabilityRepositoryProvider);
  return AccountabilityGroupsNotifier(repository);
});

final groupUpdatesProvider = FutureProvider.family<List<AccountabilityUpdate>, int>((ref, groupId) async {
  final repository = ref.watch(socialAccountabilityRepositoryProvider);
  return repository.getUpdatesForGroup(groupId);
});

class SocialAccountabilityRepository {
  final AsyncValue<Database> _dbAsync;

  SocialAccountabilityRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Group CRUD
  Future<int> insertGroup(AccountabilityGroup group) async {
    final db = await _db;
    return db.insert('accountability_groups', group.toMap());
  }

  Future<int> updateGroup(AccountabilityGroup group) async {
    final db = await _db;
    return db.update('accountability_groups', group.toMap(), where: 'id = ?', whereArgs: [group.id]);
  }

  Future<int> deleteGroup(int id) async {
    final db = await _db;
    return db.delete('accountability_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AccountabilityGroup>> getAllGroups() async {
    final db = await _db;
    final maps = await db.query('accountability_groups', orderBy: 'created_at DESC');
    return maps.map((m) => AccountabilityGroup.fromMap(m)).toList();
  }

  // Update CRUD
  Future<int> insertUpdate(AccountabilityUpdate update) async {
    final db = await _db;
    return db.insert('accountability_updates', update.toMap());
  }

  Future<List<AccountabilityUpdate>> getUpdatesForGroup(int groupId) async {
    final db = await _db;
    final maps = await db.query(
      'accountability_updates',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AccountabilityUpdate.fromMap(m)).toList();
  }

  Future<List<AccountabilityUpdate>> getRecentUpdates(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'accountability_updates',
      where: 'created_at >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AccountabilityUpdate.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalGroups = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM accountability_groups'),
    ) ?? 0;
    
    final totalUpdates = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM accountability_updates'),
    ) ?? 0;
    
    final encouragements = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM accountability_updates WHERE is_encouragement = 1'),
    ) ?? 0;
    
    return {
      'total_groups': totalGroups,
      'total_updates': totalUpdates,
      'encouragements': encouragements,
    };
  }

  Future<List<AccountabilityUpdate>> getEncouragementsForMember(String memberId) async {
    final db = await _db;
    final maps = await db.query(
      'accountability_updates',
      where: 'member_id = ? AND is_encouragement = 1',
      whereArgs: [memberId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AccountabilityUpdate.fromMap(m)).toList();
  }
}

class AccountabilityGroupsNotifier extends StateNotifier<AsyncValue<List<AccountabilityGroup>>> {
  final SocialAccountabilityRepository _repository;

  AccountabilityGroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repository.getAllGroups();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup(AccountabilityGroup group) async {
    try {
      await _repository.insertGroup(group);
      await loadGroups();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _repository.deleteGroup(id);
      await loadGroups();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> postUpdate(int groupId, String memberId, String? note, {int? goalId}) async {
    try {
      final update = AccountabilityUpdate(
        groupId: groupId,
        memberId: memberId,
        goalId: goalId,
        progressNote: note,
      );
      await _repository.insertUpdate(update);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendEncouragement(int groupId, String memberId, String? note) async {
    try {
      final update = AccountabilityUpdate(
        groupId: groupId,
        memberId: memberId,
        progressNote: note,
        isEncouragement: 1,
      );
      await _repository.insertUpdate(update);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}