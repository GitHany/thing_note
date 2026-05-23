import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/multi_export/domain/export_config.dart';
import 'package:thing_note/features/multi_export/data/export_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final exportRepositoryProvider = FutureProvider<ExportRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ExportRepository(db);
});

final exportTemplatesProvider = FutureProvider<List<ExportTemplate>>((ref) async {
  final repo = await ref.watch(exportRepositoryProvider.future);
  return repo.getAllTemplates();
});

class ExportNotifier extends StateNotifier<AsyncValue<ExportResult?>> {
  ExportNotifier() : super(const AsyncValue.data(null));

  Future<ExportResult> export(ExportConfig config) async {
    final result = ExportResult(
      filePath: '',
      format: config.format,
      recordCount: 0,
      fileSizeBytes: 0,
      exportedAt: DateTime.now(),
    );
    state = AsyncValue.data(result);
    return result;
  }
}

final exportNotifierProvider = StateNotifierProvider<ExportNotifier, AsyncValue<ExportResult?>>((ref) {
  return ExportNotifier();
});