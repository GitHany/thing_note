import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/quick_capture/domain/quick_capture_model.dart';

/// Repository for Quick Capture data operations
class QuickCaptureRepository {
  final Database db;

  QuickCaptureRepository(this.db);

  /// Create a quick capture
  Future<int> createCapture(QuickCaptureModel capture) async {
    return await db.insert('quick_captures', capture.toMap());
  }

  /// Update a quick capture
  Future<int> updateCapture(QuickCaptureModel capture) async {
    return await db.update(
      'quick_captures',
      capture.toMap(),
      where: 'id = ?',
      whereArgs: [capture.id],
    );
  }

  /// Delete a quick capture
  Future<int> deleteCapture(int id) async {
    return await db.delete(
      'quick_captures',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all captures
  Future<List<QuickCaptureModel>> getAllCaptures() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_captures',
      orderBy: 'captured_at DESC',
    );
    return maps.map((map) => QuickCaptureModel.fromMap(map)).toList();
  }

  /// Get captures by type
  Future<List<QuickCaptureModel>> getCapturesByType(String type) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_captures',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'captured_at DESC',
    );
    return maps.map((map) => QuickCaptureModel.fromMap(map)).toList();
  }

  /// Get unconverted captures
  Future<List<QuickCaptureModel>> getUnconvertedCaptures() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_captures',
      where: 'is_converted = 0',
      orderBy: 'captured_at DESC',
    );
    return maps.map((map) => QuickCaptureModel.fromMap(map)).toList();
  }

  /// Mark capture as converted
  Future<int> markAsConverted(int id, int linkedRecordId) async {
    return await db.update(
      'quick_captures',
      {
        'is_converted': 1,
        'linked_record_id': linkedRecordId.toString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get capture by ID
  Future<QuickCaptureModel?> getCaptureById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_captures',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return QuickCaptureModel.fromMap(maps.first);
  }

  /// Get recent captures
  Future<List<QuickCaptureModel>> getRecentCaptures({int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_captures',
      orderBy: 'captured_at DESC',
      limit: limit,
    );
    return maps.map((map) => QuickCaptureModel.fromMap(map)).toList();
  }

  /// Get capture statistics
  Future<Map<String, dynamic>> getCaptureStats() async {
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM quick_captures');
    final converted = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quick_captures WHERE is_converted = 1'
    );
    final byType = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM quick_captures 
      GROUP BY type
    ''');

    return {
      'total': (total.first['count'] as int?) ?? 0,
      'converted': (converted.first['count'] as int?) ?? 0,
      'by_type': byType,
    };
  }

  // ========== Configuration Operations ==========

  /// Get quick capture configuration
  Future<QuickCaptureConfig> getConfig() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_capture_config',
      limit: 1,
    );
    if (maps.isEmpty) {
      return QuickCaptureConfig();
    }
    return QuickCaptureConfig.fromMap(maps.first);
  }

  /// Save quick capture configuration
  Future<void> saveConfig(QuickCaptureConfig config) async {
    final existing = await db.query('quick_capture_config', limit: 1);
    
    if (existing.isEmpty) {
      await db.insert('quick_capture_config', config.toMap());
    } else {
      await db.update(
        'quick_capture_config',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }
}