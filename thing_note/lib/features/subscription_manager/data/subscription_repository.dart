import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/subscription_entry.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SubscriptionRepository(dbAsync);
});

class SubscriptionRepository {
  final AsyncValue<dynamic> _dbAsync;

  SubscriptionRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSubscription(SubscriptionEntry subscription) async {
    final db = await _db;
    return await db.insert('subscriptions', subscription.toMap());
  }

  Future<List<SubscriptionEntry>> getAllSubscriptions() async {
    final db = await _db;
    final maps = await db.query('subscriptions', orderBy: 'name ASC');
    return maps.map((map) => SubscriptionEntry.fromMap(map)).toList();
  }

  Future<List<SubscriptionEntry>> getActiveSubscriptions() async {
    final db = await _db;
    final maps = await db.query('subscriptions', where: 'is_active = 1', orderBy: 'name ASC');
    return maps.map((map) => SubscriptionEntry.fromMap(map)).toList();
  }

  Future<int> updateSubscription(SubscriptionEntry subscription) async {
    final db = await _db;
    return await db.update('subscriptions', subscription.toMap(),
        where: 'id = ?', whereArgs: [subscription.id]);
  }

  Future<int> deleteSubscription(int id) async {
    final db = await _db;
    return await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalMonthlyAmount() async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT SUM(CASE WHEN billing_cycle = 'monthly' THEN amount WHEN billing_cycle = 'yearly' THEN amount/12 WHEN billing_cycle = 'quarterly' THEN amount/3 ELSE amount END) as total FROM subscriptions WHERE is_active = 1",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryStats() async {
    final db = await _db;
    final result = await db.rawQuery(
      '''SELECT category, SUM(CASE WHEN billing_cycle = 'monthly' THEN amount WHEN billing_cycle = 'yearly' THEN amount/12 WHEN billing_cycle = 'quarterly' THEN amount/3 ELSE amount END) as total 
         FROM subscriptions WHERE is_active = 1 GROUP BY category''',
    );
    return {for (final row in result) row['category'] as String: (row['total'] as num?)?.toDouble() ?? 0.0};
  }
}