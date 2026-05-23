import 'package:thing_note/features/record/domain/episode_record.dart';

class ExcelRecordRow {
  final int? id;
  final String occurredAt;
  final String durationMinutes;
  final String note;
  final String thingName;
  final String tags;
  final String hasReminder;
  final String location;
  final String isFavorite;
  final String createdAt;

  const ExcelRecordRow({
    this.id,
    required this.occurredAt,
    required this.durationMinutes,
    required this.note,
    required this.thingName,
    required this.tags,
    required this.hasReminder,
    required this.location,
    required this.isFavorite,
    required this.createdAt,
  });
}

class ExcelExporter {
  /// 导出记录到 Excel 兼容的二维数组
  /// 返回 [headers, ...rows] 形式的列表
  List<List<String>> exportToExcelData(
    List<EpisodeRecord> records, {
    List<String> thingNames = const [],
    List<String> tagNames = const [],
  }) {
    final headers = [
      'ID',
      '日期时间',
      '时长(分钟)',
      '备注',
      '事情名称',
      '标签',
      '提醒',
      '位置',
      '收藏',
      '创建时间',
    ];

    final rows = records.map((record) {
      String thingName = '';
      if (record.thingNameId != null && record.thingNameId! < thingNames.length) {
        thingName = thingNames[record.thingNameId!];
      }

      final durationMinutes = record.durationSec > 0
          ? (record.durationSec / 60).toStringAsFixed(1)
          : '0';

      String location = '';
      if (record.address != null && record.address!.isNotEmpty) {
        location = record.address!;
      } else if (record.latitude != null && record.longitude != null) {
        location = '${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}';
      }

      return [
        record.id?.toString() ?? '',
        record.occurredAt.toIso8601String(),
        durationMinutes,
        record.note,
        thingName,
        '', // 标签需要单独处理
        record.hasReminder ? '是' : '否',
        location,
        record.isFavorite ? '是' : '否',
        record.createdAt.toIso8601String(),
      ];
    }).toList();

    return [headers, ...rows];
  }

  /// 生成 CSV 格式数据
  String exportToCsv(
    List<EpisodeRecord> records, {
    List<String> thingNames = const [],
  }) {
    final buffer = StringBuffer();

    // CSV 表头
    buffer.writeln('ID,日期时间,时长(分钟),备注,事情名称,提醒,位置,收藏,创建时间');

    // 数据行
    for (final record in records) {
      String thingName = '';
      if (record.thingNameId != null && record.thingNameId! < thingNames.length) {
        thingName = thingNames[record.thingNameId!];
      }

      final durationMinutes = record.durationSec > 0
          ? (record.durationSec / 60).toStringAsFixed(1)
          : '0';

      String location = '';
      if (record.address != null && record.address!.isNotEmpty) {
        location = record.address!;
      } else if (record.latitude != null && record.longitude != null) {
        location = '${record.latitude}, ${record.longitude}';
      }

      buffer.writeln([
        record.id ?? '',
        record.occurredAt.toIso8601String(),
        durationMinutes,
        _escapeCsvField(record.note),
        _escapeCsvField(thingName),
        record.hasReminder ? '是' : '否',
        _escapeCsvField(location),
        record.isFavorite ? '是' : '否',
        record.createdAt.toIso8601String(),
      ].join(','));
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}