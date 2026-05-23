import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/templates/data/template_repository_impl.dart';
import 'package:thing_note/features/templates/domain/record_template.dart';

// Template list provider
final templateListProvider = FutureProvider<List<RecordTemplate>>((ref) async {
  final repo = await ref.watch(templateRepositoryProvider.future);
  return repo.getAll();
});

// Template notifier for CRUD operations
final templateNotifierProvider = AsyncNotifierProvider<TemplateNotifier, List<RecordTemplate>>(() {
  return TemplateNotifier();
});

class TemplateNotifier extends AsyncNotifier<List<RecordTemplate>> {
  @override
  Future<List<RecordTemplate>> build() async {
    final repo = await ref.watch(templateRepositoryProvider.future);
    return repo.getAll();
  }

  Future<int> create(RecordTemplate template) async {
    final repo = await ref.read(templateRepositoryProvider.future);
    final id = await repo.create(template);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateTemplate(RecordTemplate template) async {
    final repo = await ref.read(templateRepositoryProvider.future);
    await repo.update(template);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final repo = await ref.read(templateRepositoryProvider.future);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}