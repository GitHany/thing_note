import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/custom_gesture/domain/custom_gesture.dart';

class CustomGestureRepository {
  final Ref _ref;

  CustomGestureRepository(this._ref);

  Future<List<CustomGesture>> getAllGestures() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'custom_gestures',
      orderBy: 'use_count DESC',
    );
    return result.map((e) => CustomGesture.fromMap(e)).toList();
  }

  Future<List<CustomGesture>> getEnabledGestures() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'custom_gestures',
      where: 'is_enabled = 1',
      orderBy: 'use_count DESC',
    );
    return result.map((e) => CustomGesture.fromMap(e)).toList();
  }

  Future<int> insertGesture(CustomGesture gesture) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('custom_gestures', gesture.toMap()..remove('id'));
  }

  Future<int> updateGesture(CustomGesture gesture) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'custom_gestures',
      gesture.toMap(),
      where: 'id = ?',
      whereArgs: [gesture.id],
    );
  }

  Future<int> deleteGesture(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('custom_gestures', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleEnabled(int id) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query('custom_gestures', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return 0;

    final current = (result.first['is_enabled'] as int?) == 1;
    return db.update(
      'custom_gestures',
      {'is_enabled': current ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementUseCount(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.rawUpdate(
      'UPDATE custom_gestures SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }
}