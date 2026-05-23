import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 数据导入服务
class ImporterService {
  final AsyncValue<Database> _dbAsync;

  ImporterService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 从 JSON 文件导入记录
  Future<ImportResult> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ImportResult(success: false, message: '文件不存在');
      }

      final content = await file.readAsString();
      final data = jsonDecode(content);

      int imported = 0;
      int failed = 0;

      if (data is List) {
        for (final item in data) {
          try {
            await _importSingleRecord(item);
            imported++;
          } catch (e) {
            failed++;
          }
        }
      } else if (data is Map && data.containsKey('records')) {
        final records = data['records'] as List;
        for (final item in records) {
          try {
            await _importSingleRecord(item);
            imported++;
          } catch (e) {
            failed++;
          }
        }
      }

      return ImportResult(
        success: true,
        message: '导入完成',
        importedCount: imported,
        failedCount: failed,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入失败: $e');
    }
  }

  /// 从 CSV 文件导入记录
  Future<ImportResult> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ImportResult(success: false, message: '文件不存在');
      }

      final content = await file.readAsString();
      final lines = content.split('\n');

      if (lines.isEmpty) {
        return const ImportResult(success: false, message: 'CSV 文件为空');
      }

      // 解析表头
      final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();

      int imported = 0;
      int failed = 0;

      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        try {
          final values = _parseCsvLine(lines[i]);
          final record = _csvToRecord(headers, values);
          await _importSingleRecord(record);
          imported++;
        } catch (e) {
          failed++;
        }
      }

      return ImportResult(
        success: true,
        message: 'CSV 导入完成',
        importedCount: imported,
        failedCount: failed,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'CSV 导入失败: $e');
    }
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    values.add(current.trim());

    return values;
  }

  Map<String, dynamic> _csvToRecord(List<String> headers, List<String> values) {
    final record = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < values.length; i++) {
      final header = headers[i];
      final value = values[i];

      switch (header) {
        case 'occurred_at':
        case 'date':
        case 'time':
          record['occurred_at'] = value;
          break;
        case 'duration':
        case 'duration_sec':
          record['duration_sec'] = int.tryParse(value) ?? 0;
          break;
        case 'note':
        case 'description':
        case 'content':
          record['note'] = value;
          break;
        case 'thing_name':
        case 'category':
          record['thing_name'] = value;
          break;
        case 'address':
        case 'location':
          record['address'] = value;
          break;
        case 'tags':
          record['tags'] = value;
          break;
      }
    }

    return record;
  }

  Future<void> _importSingleRecord(dynamic item) async {
    final db = await _db;

    DateTime occurredAt;
    if (item is Map) {
      final dateStr = item['occurred_at'] ?? item['date'] ?? item['time'];
      if (dateStr != null) {
        occurredAt = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
      } else {
        occurredAt = DateTime.now();
      }
    } else {
      occurredAt = DateTime.now();
    }

    final now = DateTime.now();
    final record = EpisodeRecord(
      occurredAt: occurredAt,
      durationSec: _getIntValue(item, 'duration_sec') ?? _getIntValue(item, 'duration') ?? 0,
      note: _getStringValue(item, 'note') ?? _getStringValue(item, 'description') ?? '',
      thingNameId: await _getOrCreateThingName(_getStringValue(item, 'thing_name')),
      address: _getStringValue(item, 'address'),
      latitude: _getDoubleValue(item, 'latitude'),
      longitude: _getDoubleValue(item, 'longitude'),
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('episode_records', record.toMap());

    // 处理标签
    final tagsStr = _getStringValue(item, 'tags');
    if (tagsStr != null && tagsStr.isNotEmpty) {
      final tagNames = tagsStr.split(',').map((t) => t.trim()).toList();
      final recordId = await _getLastInsertId();
      for (final tagName in tagNames) {
        final tagId = await _getOrCreateTag(tagName);
        await db.insert('record_tags', {
          'record_id': recordId,
          'tag_id': tagId,
        });
      }
    }
  }

  int? _getIntValue(dynamic map, String key) {
    if (map is Map) {
      final value = map[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  String? _getStringValue(dynamic map, String key) {
    if (map is Map) {
      final value = map[key];
      return value?.toString();
    }
    return null;
  }

  double? _getDoubleValue(dynamic map, String key) {
    if (map is Map) {
      final value = map[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  Future<int> _getOrCreateThingName(String? name) async {
    if (name == null || name.isEmpty) return 1;

    final db = await _db;
    final existing = await db.query(
      'thing_names',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return db.insert('thing_names', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _getOrCreateTag(String name) async {
    final db = await _db;
    final existing = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return db.insert('tags', {
      'name': name,
      'color': '#607D8B',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> _getLastInsertId() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  /// 验证导入文件格式
  Future<ValidationResult> validateFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ValidationResult(isValid: false, errors: ['文件不存在']);
      }

      final extension = filePath.toLowerCase().split('.').last;
      final content = await file.readAsString();

      if (extension == 'json') {
        return _validateJson(content);
      } else if (extension == 'csv') {
        return _validateCsv(content);
      }

      return const ValidationResult(isValid: false, errors: ['不支持的文件格式']);
    } catch (e) {
      return ValidationResult(isValid: false, errors: ['文件读取失败: $e']);
    }
  }

  ValidationResult _validateJson(String content) {
    try {
      final data = jsonDecode(content);
      final errors = <String>[];

      if (data is List) {
        if (data.isEmpty) {
          errors.add('JSON 数组为空');
        }
        for (var i = 0; i < data.length && i < 10; i++) {
          if (data[i] is! Map) {
            errors.add('第 ${i + 1} 项不是对象');
          }
        }
      } else if (data is Map) {
        if (!data.containsKey('records') && !data.containsKey('data')) {
          errors.add('JSON 格式不正确，应包含 "records" 或 "data" 字段');
        }
      } else {
        errors.add('JSON 格式不正确');
      }

      return ValidationResult(isValid: errors.isEmpty, errors: errors);
    } catch (e) {
      return ValidationResult(isValid: false, errors: ['JSON 解析失败: $e']);
    }
  }

  ValidationResult _validateCsv(String content) {
    final errors = <String>[];
    final lines = content.split('\n');

    if (lines.isEmpty) {
      errors.add('CSV 文件为空');
      return ValidationResult(isValid: false, errors: errors);
    }

    final headers = lines[0].split(',');
    if (headers.length < 2) {
      errors.add('CSV 表头列数不足');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int failedCount;

  const ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.failedCount = 0,
  });
}

/// 文件验证结果
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });
}

final importerServiceProvider = Provider<ImporterService>((ref) {
    final dbAsync = ref.watch(databaseProvider);
    return ImporterService(dbAsync);
});