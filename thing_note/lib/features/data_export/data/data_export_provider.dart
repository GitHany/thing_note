import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/data_export/data/data_export_repository.dart';

final dataExportRepositoryProvider = Provider((ref) => DataExportRepository(ref));

final exportPreviewProvider = FutureProvider.family<Map<String, dynamic>, (DateTime, DateTime)>((ref, params) async {
  final repo = ref.read(dataExportRepositoryProvider);
  return repo.getExportPreview(startDate: params.$1, endDate: params.$2);
});