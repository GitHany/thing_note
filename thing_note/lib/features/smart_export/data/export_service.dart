import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_export/domain/export_models.dart';

/// 智能导出服务 Provider
final smartExportServiceProvider = Provider<SmartExportService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartExportService(dbAsync);
});

/// 导出预设 Provider
final exportProfilesProvider = FutureProvider<List<ExportProfile>>((ref) async {
  final service = ref.watch(smartExportServiceProvider);
  return service.getProfiles();
});

class SmartExportService {
  final AsyncValue<Database> _dbAsync;

  SmartExportService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有导出预设
  Future<List<ExportProfile>> getProfiles() async {
    final db = await _db;
    final maps = await db.query('export_profiles', orderBy: 'use_count DESC');
    return maps.map((m) => ExportProfile.fromMap(m)).toList();
  }

  /// 创建导出预设
  Future<int> createProfile(ExportProfile profile) async {
    final db = await _db;
    return db.insert('export_profiles', profile.toMap()..remove('id'));
  }

  /// 更新导出预设
  Future<int> updateProfile(ExportProfile profile) async {
    final db = await _db;
    return db.update(
      'export_profiles',
      profile.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// 删除导出预设
  Future<int> deleteProfile(int id) async {
    final db = await _db;
    return db.delete('export_profiles', where: 'id = ?', whereArgs: [id]);
  }

  /// 导出记录
  Future<String> exportRecords({
    required ExportFormat format,
    required ExportOptions options,
    List<String>? fields,
  }) async {
    final db = await _db;
    
    // 构建查询条件
    String whereClause = '1=1';
    final List<dynamic> whereArgs = [];
    
    if (options.startDate != null) {
      whereClause += ' AND occurred_at >= ?';
      whereArgs.add(options.startDate!.toIso8601String());
    }
    
    if (options.endDate != null) {
      whereClause += ' AND occurred_at <= ?';
      whereArgs.add(options.endDate!.toIso8601String());
    }
    
    if (options.recordIds != null && options.recordIds!.isNotEmpty) {
      whereClause += ' AND id IN (${options.recordIds!.map((_) => '?').join(',')})';
      whereArgs.addAll(options.recordIds!);
    }

    final records = await db.rawQuery('''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
      ORDER BY occurred_at DESC
    ''', whereArgs);

    // 根据格式导出
    switch (format) {
      case ExportFormat.json:
        return _exportJson(records, options);
      case ExportFormat.csv:
        return _exportCsv(records, options, fields);
      case ExportFormat.markdown:
        return _exportMarkdown(records, options);
      case ExportFormat.pdf:
        // PDF 需要特殊处理，这里返回空字符串
        return '';
    }
  }

  String _exportJson(List<Map<String, dynamic>> records, ExportOptions options) {
    final exportRecords = records.map((record) {
      final Map<String, dynamic> item = {};

      item['id'] = record['id'];
      item['note'] = record['note'];
      item['thing_name'] = record['thing_name'];
      item['occurred_at'] = record['occurred_at'];
      item['duration_sec'] = record['duration_sec'];

      if (options.includeLocation && record['latitude'] != null) {
        item['location'] = {
          'latitude': record['latitude'],
          'longitude': record['longitude'],
          'address': record['address'],
        };
      }

      if (options.includeTags) {
        item['tags'] = _getTagsForRecord(record['id'] as int);
      }

      return item;
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'export_date': DateTime.now().toIso8601String(),
      'total_records': records.length,
      'records': exportRecords,
    });
  }

  String _exportCsv(List<Map<String, dynamic>> records, ExportOptions options, List<String>? fields) {
    final buffer = StringBuffer();
    
    // 表头
    final headers = ['ID', '时间', '内容', '事情类型', '时长(秒)'];
    if (options.includeLocation) headers.addAll(['纬度', '经度', '地址']);
    if (options.includeTags) headers.add('标签');
    
    if (fields != null && fields.isNotEmpty) {
      // 使用指定的字段
      buffer.writeln(fields.join(','));
    } else {
      buffer.writeln(headers.join(','));
    }

    // 数据行
    for (final record in records) {
      final row = <String>[];
      
      if (fields != null && fields.isNotEmpty) {
        for (final field in fields) {
          row.add(_escapeCsvField(record[field]?.toString() ?? ''));
        }
      } else {
        row.add(record['id'].toString());
        row.add(_escapeCsvField(record['occurred_at']?.toString() ?? ''));
        row.add(_escapeCsvField(record['note']?.toString() ?? ''));
        row.add(_escapeCsvField(record['thing_name']?.toString() ?? ''));
        row.add(record['duration_sec']?.toString() ?? '0');
        
        if (options.includeLocation) {
          row.add(record['latitude']?.toString() ?? '');
          row.add(record['longitude']?.toString() ?? '');
          row.add(_escapeCsvField(record['address']?.toString() ?? ''));
        }
        
        if (options.includeTags) {
          row.add(_getTagsForRecord(record['id'] as int).join(';'));
        }
      }
      
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _exportMarkdown(List<Map<String, dynamic>> records, ExportOptions options) {
    final buffer = StringBuffer();
    
    buffer.writeln('# 事件记录导出');
    buffer.writeln();
    buffer.writeln('**导出时间**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('**记录数量**: ${records.length}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final record in records) {
      buffer.writeln('## ${record['thing_name'] ?? '默认'}');
      buffer.writeln();
      buffer.writeln('- **时间**: ${record['occurred_at']}');
      buffer.writeln('- **时长**: ${record['duration_sec']} 秒');
      
      if (options.includeLocation && record['latitude'] != null) {
        buffer.writeln('- **位置**: ${record['address'] ?? '未知'}');
      }
      
      if (record['note'] != null && record['note'].toString().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('**内容**:');
        buffer.writeln(record['note']);
      }
      
      if (options.includeTags) {
        final tags = _getTagsForRecord(record['id'] as int);
        if (tags.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('**标签**: ${tags.join(', ')}');
        }
      }
      
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  List<String> _getTagsForRecord(int recordId) {
    // 这里需要查询标签表，返回关联的标签列表
    return [];
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 获取导出历史
  Future<List<Map<String, dynamic>>> getExportHistory() async {
    final db = await _db;
    return db.query('export_history', orderBy: 'created_at DESC', limit: 20);
  }

  /// 记录导出历史
  Future<void> recordExport(String format, int recordCount, String? filePath) async {
    final db = await _db;
    await db.insert('export_history', {
      'format': format,
      'record_count': recordCount,
      'file_path': filePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}