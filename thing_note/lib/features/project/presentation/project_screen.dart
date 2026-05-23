import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/project/data/project_repository.dart';
import 'package:thing_note/features/project/domain/project.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('项目管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProjectDialog(context),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无项目', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddProjectDialog(context),
                    child: const Text('创建项目'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) => _ProjectCard(project: projects[index]),
          );
        },
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedColor = ProjectColors.presets[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建项目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '项目名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('项目颜色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProjectColors.presets.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final project = Project(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    color: selectedColor,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  ref.read(projectsProvider.notifier).addProject(project);
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse(project.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProjectDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.status.displayName,
                      style: TextStyle(color: _getStatusColor(project.status), fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${project.progress}%'),
                ],
              ),
              if (project.linkedRecordIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${project.linkedRecordIds.length} 条关联记录',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Colors.blue;
      case ProjectStatus.paused:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.archived:
        return Colors.grey;
    }
  }

  void _showProjectDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProjectDetailSheet(project: project),
    );
  }
}

class _ProjectDetailSheet extends ConsumerWidget {
  final Project project;

  const _ProjectDetailSheet({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse(project.color.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(project.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (project.description != null && project.description!.isNotEmpty) ...[
            Text(project.description!),
            const SizedBox(height: 16),
          ],
          Text('进度: ${project.progress}%'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('更新进度: '),
              Expanded(
                child: Slider(
                  value: project.progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (v) {
                    ref.read(projectsProvider.notifier).updateProgress(project.id!, v.toInt());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  final updated = project.copyWith(status: ProjectStatus.completed, updatedAt: DateTime.now());
                  ref.read(projectsProvider.notifier).updateProject(updated);
                  Navigator.pop(context);
                },
                child: const Text('标记完成'),
              ),
              OutlinedButton(
                onPressed: () {
                  ref.read(projectsProvider.notifier).deleteProject(project.id!);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}