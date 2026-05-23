import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/invoice_entry.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return InvoiceRepository(dbAsync);
});

class InvoiceRepository {
  final AsyncValue<dynamic> _dbAsync;

  InvoiceRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertInvoice(InvoiceEntry invoice) async {
    final db = await _db;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<List<InvoiceEntry>> getAllInvoices() async {
    final db = await _db;
    final maps = await db.query('invoices', orderBy: 'created_at DESC');
    return maps.map((map) => InvoiceEntry.fromMap(map)).toList();
  }

  Future<InvoiceEntry?> getInvoiceById(int id) async {
    final db = await _db;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? InvoiceEntry.fromMap(maps.first) : null;
  }

  Future<int> updateInvoice(InvoiceEntry invoice) async {
    final db = await _db;
    return await db.update('invoices', invoice.toMap(),
        where: 'id = ?', whereArgs: [invoice.id]);
  }

  Future<int> deleteInvoice(int id) async {
    final db = await _db;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InvoiceEntry>> getInvoicesByStatus(String status) async {
    final db = await _db;
    final maps = await db.query('invoices', where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
    return maps.map((map) => InvoiceEntry.fromMap(map)).toList();
  }

  Future<double> getTotalPendingAmount() async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM invoices WHERE status IN ('sent', 'overdue')",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalPaidAmount() async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM invoices WHERE status = 'paid'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> generateInvoiceNumber() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    final count = (result.first['count'] as int?) ?? 0;
    final year = DateTime.now().year;
    return year * 10000 + count + 1;
  }
}