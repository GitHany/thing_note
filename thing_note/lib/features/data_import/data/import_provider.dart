import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/data_import/domain/import_config.dart';
import 'package:thing_note/features/data_import/data/import_repository.dart';
import 'package:thing_note/core/database/database_provider.dart';

final dataImportRepositoryProvider = FutureProvider<DataImportRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DataImportRepository(db);
});

final importTemplatesProvider = FutureProvider<List<ImportTemplate>>((ref) async {
  final repo = await ref.watch(dataImportRepositoryProvider.future);
  return repo.getTemplates();
});

final importPreviewProvider = FutureProvider.family<ImportPreview, (String, ImportSourceType)>((ref, params) async {
  final repo = await ref.watch(dataImportRepositoryProvider.future);
  return repo.previewImport(params.$1, params.$2);
});

class DataImportNotifier extends StateNotifier<AsyncValue<ImportResult?>> {
  DataImportNotifier() : super(const AsyncValue.data(null));

  Future<ImportResult> import(ImportConfig config) async {
    final result = ImportResult(
      duration: Duration.zero,
    );
    state = AsyncValue.data(result);
    return result;
  }

  Future<void> saveTemplate(ImportTemplate template) async {
    // Placeholder - would need repository
  }
}

final dataImportNotifierProvider = StateNotifierProvider<DataImportNotifier, AsyncValue<ImportResult?>>((ref) {
  return DataImportNotifier();
});