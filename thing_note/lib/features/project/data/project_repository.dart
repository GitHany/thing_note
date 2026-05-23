import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/project/domain/project.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ProjectRepository(dbAsync);
});

final projectsProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectsNotifier(repository);
});

final activeProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projects = ref.watch(projectsProvider);
  return projects.whenData(
    (list) => list.where((p) => p.status == ProjectStatus.active).toList(),
  );
});

class ProjectRepository {
  final AsyncValue<Database> _dbAsync;

  ProjectRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertProject(Project project) async {
    final db = await _db;
    return db.insert('projects', project.toMap());
  }

  Future<int> updateProject(Project project) async {
    final db = await _db;
    return db.update(
      'projects',
      project.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await _db;
    return db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Project>> getAllProjects() async {
    final db = await _db;
    final maps = await db.query('projects', orderBy: 'created_at DESC');
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  Future<Project?> getProjectById(int id) async {
    final db = await _db;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<void> updateProgress(int projectId, int progress) async {
    final db = await _db;
    await db.update(
      'projects',
      {'progress': progress, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> linkRecord(int projectId, int recordId) async {
    final db = await _db;
    final project = await getProjectById(projectId);
    if (project == null) return;

    final linkedIds = List<int>.from(project.linkedRecordIds);
    if (!linkedIds.contains(recordId)) {
      linkedIds.add(recordId);
      await db.update(
        'projects',
        {'linked_record_ids': linkedIds.join(',')},
        where: 'id = ?',
        whereArgs: [projectId],
      );
    }
  }

  Future<void> unlinkRecord(int projectId, int recordId) async {
    final db = await _db;
    final project = await getProjectById(projectId);
    if (project == null) return;

    final linkedIds = List<int>.from(project.linkedRecordIds);
    linkedIds.remove(recordId);
    await db.update(
      'projects',
      {'linked_record_ids': linkedIds.join(',')},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }
}

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectRepository _repository;

  ProjectsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await _repository.insertProject(project);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await _repository.updateProject(project);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _repository.deleteProject(id);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(int projectId, int progress) async {
    try {
      await _repository.updateProgress(projectId, progress);
      await loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}