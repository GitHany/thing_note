import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_template/data/quick_template_repository.dart';
import 'package:thing_note/features/quick_template/domain/quick_template.dart';

final quickTemplateRepositoryProvider = Provider((ref) => QuickTemplateRepository(ref));

final allTemplatesProvider = FutureProvider<List<QuickTemplate>>((ref) async {
  final repo = ref.read(quickTemplateRepositoryProvider);
  return repo.getAllTemplates();
});

final favoriteTemplatesProvider = FutureProvider<List<QuickTemplate>>((ref) async {
  final repo = ref.read(quickTemplateRepositoryProvider);
  return repo.getFavoriteTemplates();
});

final mostUsedTemplatesProvider = FutureProvider<List<QuickTemplate>>((ref) async {
  final repo = ref.read(quickTemplateRepositoryProvider);
  return repo.getMostUsedTemplates();
});