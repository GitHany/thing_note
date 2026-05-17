import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/thing_name/data/thing_name_repository_impl.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/domain/thing_name_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final thingNameRepositoryProvider = Provider<ThingNameRepository>((ref) {
  final dbFuture = ref.watch(databaseProvider.future);
  return FutureThingNameRepositoryProxy(dbFuture);
});

class FutureThingNameRepositoryProxy implements ThingNameRepository {
  final Future<Database> _dbFuture;

  Future<ThingNameRepository> get _repo async {
    final db = await _dbFuture;
    return ThingNameRepositoryImpl(db);
  }

  FutureThingNameRepositoryProxy(this._dbFuture);

  @override
  Future<List<ThingName>> getAll() async {
    final repo = await _repo;
    return repo.getAll();
  }

  @override
  Future<ThingName?> getById(int id) async {
    final repo = await _repo;
    return repo.getById(id);
  }

  @override
  Future<ThingName> create(ThingName thingName) async {
    final repo = await _repo;
    return repo.create(thingName);
  }

  @override
  Future<void> update(ThingName thingName) async {
    final repo = await _repo;
    return repo.update(thingName);
  }

  @override
  Future<void> delete(int id) async {
    final repo = await _repo;
    return repo.delete(id);
  }

  @override
  Stream<List<ThingName>> watchAll() {
    throw UnimplementedError();
  }
}

final thingNameListProvider = FutureProvider<List<ThingName>>((ref) async {
  final repo = ref.watch(thingNameRepositoryProvider);
  return await repo.getAll();
});

final defaultThingNameProvider = FutureProvider<ThingName?>((ref) async {
  final repo = ref.watch(thingNameRepositoryProvider);
  final all = await repo.getAll();
  return all.firstWhere((tn) => tn.name == '默认', orElse: () => all.first);
});

final thingNameByIdProvider = FutureProvider.family<ThingName?, int>((ref, id) async {
  final repo = ref.watch(thingNameRepositoryProvider);
  return await repo.getById(id);
});

final thingNameNotifierProvider = NotifierProvider<ThingNameNotifier, void>(() {
  return ThingNameNotifier();
});

class ThingNameNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> add(String name, {String? remark}) async {
    final repo = ref.read(thingNameRepositoryProvider);
    await repo.create(
      ThingName(name: name, remark: remark, createdAt: DateTime.now()),
    );
    ref.invalidate(thingNameListProvider);
  }

  Future<void> update(int id, String name, {String? remark}) async {
    final repo = ref.read(thingNameRepositoryProvider);
    final existing = await repo.getById(id);
    if (existing != null) {
      await repo.update(existing.copyWith(name: name, remark: remark));
    }
    ref.invalidate(thingNameListProvider);
  }

  Future<void> remove(int id) async {
    final repo = ref.read(thingNameRepositoryProvider);
    await repo.delete(id);
    ref.invalidate(thingNameListProvider);
  }
}
