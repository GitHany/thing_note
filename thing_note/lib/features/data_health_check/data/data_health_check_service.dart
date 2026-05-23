import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/data_health_check/domain/health_issue.dart';

class DataHealthCheckService {
  final Database db;

  DataHealthCheckService(this.db);

  /// Run all health checks
  Future<DataHealthStatus> runHealthCheck() async {
    final issues = <HealthIssue>[];

    // Check for missing media files
    issues.addAll(await _checkMissingMedia());

    // Check for orphaned records
    issues.addAll(await _checkOrphanedRecords());

    // Check for invalid dates
    issues.addAll(await _checkInvalidDates());

    // Check for large files
    issues.addAll(await _checkLargeFiles());

    // Categorize issues
    final critical = issues.where((i) => i.severity == HealthSeverity.critical).toList();
    final warnings = issues.where((i) => i.severity == HealthSeverity.warning).toList();
    final info = issues.where((i) => i.severity == HealthSeverity.info).toList();

    // Get total records
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records');
    final totalRecords = Sqflite.firstIntValue(countResult) ?? 0;

    return DataHealthStatus(
      totalRecords: totalRecords,
      healthyRecords: totalRecords - issues.length,
      issueCount: issues.length,
      criticalIssues: critical,
      warnings: warnings,
      infoMessages: info,
      lastChecked: DateTime.now(),
    );
  }

  /// Check for missing media files
  Future<List<HealthIssue>> _checkMissingMedia() async {
    final issues = <HealthIssue>[];

    final records = await db.query('episode_records');
    for (final record in records) {
      final id = record['id'] as int;

      // Check photos
      final photoPaths = (record['photo_paths'] as String?) ?? '[]';
      if (photoPaths != '[]' && photoPaths.isNotEmpty) {
        final paths = _parseJsonList(photoPaths);
        for (final path in paths) {
          if (!await File(path).exists()) {
            issues.add(HealthIssue(
              type: HealthIssueType.missingPhoto,
              title: 'Missing Photo',
              description: 'Photo file not found: $path',
              affectedId: id.toString(),
              severity: HealthSeverity.warning,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }

      // Check audio
      final audioPaths = (record['audio_paths'] as String?) ?? '[]';
      if (audioPaths != '[]' && audioPaths.isNotEmpty) {
        final paths = _parseJsonList(audioPaths);
        for (final path in paths) {
          if (!await File(path).exists()) {
            issues.add(HealthIssue(
              type: HealthIssueType.missingAudio,
              title: 'Missing Audio',
              description: 'Audio file not found: $path',
              affectedId: id.toString(),
              severity: HealthSeverity.warning,
              detectedAt: DateTime.now(),
            ));
          }
        }
      }
    }

    return issues;
  }

  /// Check for orphaned records (records with deleted thing names)
  Future<List<HealthIssue>> _checkOrphanedRecords() async {
    final issues = <HealthIssue>[];

    final records = await db.rawQuery('''
      SELECT r.id, r.thing_name_id
      FROM episode_records r
      LEFT JOIN thing_names t ON r.thing_name_id = t.id
      WHERE r.thing_name_id IS NOT NULL AND t.id IS NULL
    ''');

    for (final record in records) {
      issues.add(HealthIssue(
        type: HealthIssueType.orphanedRecord,
        title: 'Orphaned Record',
        description: 'Record has invalid thing name reference',
        affectedId: (record['id'] as int).toString(),
        severity: HealthSeverity.warning,
        detectedAt: DateTime.now(),
        canAutoFix: true,
      ));
    }

    return issues;
  }

  /// Check for invalid dates
  Future<List<HealthIssue>> _checkInvalidDates() async {
    final issues = <HealthIssue>[];

    final records = await db.rawQuery('''
      SELECT id, occurred_at FROM episode_records
      WHERE occurred_at IS NULL OR occurred_at = ''
    ''');

    for (final record in records) {
      issues.add(HealthIssue(
        type: HealthIssueType.invalidDate,
        title: 'Invalid Date',
        description: 'Record has no occurrence date',
        affectedId: (record['id'] as int).toString(),
        severity: HealthSeverity.critical,
        detectedAt: DateTime.now(),
        canAutoFix: true,
      ));
    }

    return issues;
  }

  /// Check for large files
  Future<List<HealthIssue>> _checkLargeFiles() async {
    final issues = <HealthIssue>[];
    const maxSize = 50 * 1024 * 1024; // 50MB

    final appDir = await getApplicationDocumentsDirectory();
    await for (final entity in appDir.list(recursive: true)) {
      if (entity is File) {
        final size = await entity.length();
        if (size > maxSize) {
          issues.add(HealthIssue(
            type: HealthIssueType.largeFile,
            title: 'Large File',
            description: 'File larger than 50MB: ${entity.path}',
            severity: HealthSeverity.info,
            detectedAt: DateTime.now(),
          ));
        }
      }
    }

    return issues;
  }

  /// Auto-fix an issue
  Future<bool> fixIssue(HealthIssue issue) async {
    switch (issue.type) {
      case HealthIssueType.orphanedRecord:
        // Set thing_name_id to null
        if (issue.affectedId == null) return false;
        await db.update(
          'episode_records',
          {'thing_name_id': null},
          where: 'id = ?',
          whereArgs: [int.parse(issue.affectedId!)],
        );
        return true;

      case HealthIssueType.invalidDate:
        // Set to created_at date
        if (issue.affectedId == null) return false;
        final record = await db.query(
          'episode_records',
          where: 'id = ?',
          whereArgs: [int.parse(issue.affectedId!)],
        );
        if (record.isNotEmpty) {
          await db.update(
            'episode_records',
            {'occurred_at': record.first['created_at']},
            where: 'id = ?',
            whereArgs: [int.parse(issue.affectedId!)],
          );
        }
        return true;

      default:
        return false;
    }
  }

  List<String> _parseJsonList(String json) {
    // Simple JSON array parsing
    final result = <String>[];
    final content = json.trim();
    if (content.startsWith('[') && content.endsWith(']')) {
      final inner = content.substring(1, content.length - 1);
      for (final item in inner.split(',')) {
        final trimmed = item.trim();
        if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
          result.add(trimmed.substring(1, trimmed.length - 1));
        }
      }
    }
    return result;
  }
}