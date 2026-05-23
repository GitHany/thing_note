import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/creative_project.dart';
import '../data/creative_repository.dart';

final creativeProvider = StateNotifierProvider<CreativeNotifier, CreativeState>((ref) {
  return CreativeNotifier(ref.watch(creativeRepositoryProvider));
});

class CreativeState {
  final List<CreativeProject> projects;
  final bool isLoading;
  final String? error;

  CreativeState({this.projects = const [], this.isLoading = false, this.error});

  CreativeState copyWith({List<CreativeProject>? projects, bool? isLoading, String? error}) {
    return CreativeState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CreativeNotifier extends StateNotifier<CreativeState> {
  final CreativeRepository _repository;

  CreativeNotifier(this._repository) : super(CreativeState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final projects = await _repository.getAllProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addProject(CreativeProject project) async {
    try {
      await _repository.insertProject(project);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateProject(CreativeProject project) async {
    try {
      await _repository.updateProject(project);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final creativeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(creativeRepositoryProvider).getCreativeStats();
});

class CreativeTrackerScreen extends ConsumerStatefulWidget {
  const CreativeTrackerScreen({super.key});

  @override
  ConsumerState<CreativeTrackerScreen> createState() => _CreativeTrackerScreenState();
}

class _CreativeTrackerScreenState extends ConsumerState<CreativeTrackerScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _projectType = 'writing';

  @override
  Widget build(BuildContext context) {
    final creativeState = ref.watch(creativeProvider);
    final statsAsync = ref.watch(creativeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creative Projects'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            statsAsync.when(
              data: (stats) => _buildStatsCard(stats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Add Project
            _buildAddProjectForm(),
            const SizedBox(height: 24),

            // Project List
            Text('Active Projects', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...creativeState.projects
                .where((p) => p.status == 'active')
                .map((p) => _buildProjectCard(p)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', '${stats['total'] ?? 0}'),
            _buildStatItem('Active', '${stats['active'] ?? 0}'),
            _buildStatItem('Sessions', '${stats['sessions'] ?? 0}'),
            _buildStatItem('Minutes', '${stats['total_minutes'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAddProjectForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Creative Project', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _projectType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: ['writing', 'art', 'music', 'coding', 'design', 'other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _projectType = v ?? 'writing'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addProject,
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(CreativeProject project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getTypeIcon(project.projectType),
        title: Text(project.projectName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: project.progressPercent / 100),
            Text('${project.progressPercent}% complete'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showUpdateProgressDialog(project),
        ),
      ),
    );
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case 'writing': return const Icon(Icons.edit_document);
      case 'art': return const Icon(Icons.brush);
      case 'music': return const Icon(Icons.music_note);
      case 'coding': return const Icon(Icons.code);
      case 'design': return const Icon(Icons.design_services);
      default: return const Icon(Icons.lightbulb);
    }
  }

  void _addProject() {
    if (_nameController.text.isEmpty) return;
    final project = CreativeProject(
      projectName: _nameController.text,
      projectType: _projectType,
      description: _descController.text.isNotEmpty ? _descController.text : null,
      startedAt: DateTime.now(),
    );
    ref.read(creativeProvider.notifier).addProject(project);
    _nameController.clear();
    _descController.clear();
  }

  void _showAddProjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: _buildAddProjectForm(),
      ),
    );
  }

  void _showUpdateProgressDialog(CreativeProject project) {
    int dialogProgress = project.progressPercent;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update: ${project.projectName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: dialogProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$dialogProgress%',
                onChanged: (v) => setDialogState(() => dialogProgress = v.round()),
              ),
              Text('$dialogProgress%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = project.copyWith(
                  progressPercent: dialogProgress,
                  updatedAt: DateTime.now(),
                );
                ref.read(creativeProvider.notifier).updateProject(updated);
                Navigator.pop(dialogContext);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}