import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 导入源类型
enum ImportSource { json, csv, txt, excel }

/// 导出格式
enum ExportFormat { json, csv, txt, pdf, excel }

/// 导入任务
class ImportTask {
  final String id;
  final ImportSource source;
  final String fileName;
  final int totalRecords;
  final int importedRecords;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final DateTime createdAt;
  final String? errorMessage;

  const ImportTask({
    required this.id,
    required this.source,
    required this.fileName,
    required this.totalRecords,
    this.importedRecords = 0,
    this.status = 'pending',
    required this.createdAt,
    this.errorMessage,
  });

  double get progress => totalRecords > 0 ? importedRecords / totalRecords : 0;
}

/// 导出任务
class ExportTask {
  final String id;
  final ExportFormat format;
  final int recordCount;
  final String status;
  final DateTime createdAt;
  final String? filePath;

  const ExportTask({
    required this.id,
    required this.format,
    required this.recordCount,
    this.status = 'pending',
    required this.createdAt,
    this.filePath,
  });
}

/// 数据导入导出中心 Provider
final dataIOProvider = StateNotifierProvider<DataIONotifier, AsyncValue<List<ImportTask>>>((ref) {
  return DataIONotifier();
});

class DataIONotifier extends StateNotifier<AsyncValue<List<ImportTask>>> {
  DataIONotifier() : super(const AsyncValue.loading());

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data([
        ImportTask(id: '1', source: ImportSource.csv, fileName: 'records.csv', totalRecords: 100, importedRecords: 100, status: 'completed', createdAt: DateTime.now().subtract(const Duration(days: 1))),
        ImportTask(id: '2', source: ImportSource.json, fileName: 'backup.json', totalRecords: 50, importedRecords: 30, status: 'processing', createdAt: DateTime.now()),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startImport(String filePath, ImportSource source) async {
    // 实现导入逻辑
    await Future.delayed(const Duration(seconds: 5));
    await loadTasks();
  }
}

/// 导出任务列表
final exportTasksProvider = FutureProvider<List<ExportTask>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    ExportTask(id: '1', format: ExportFormat.csv, recordCount: 100, status: 'completed', createdAt: DateTime.now().subtract(const Duration(hours: 2)), filePath: '/path/to/export.csv'),
    ExportTask(id: '2', format: ExportFormat.pdf, recordCount: 50, status: 'pending', createdAt: DateTime.now()),
  ];
});