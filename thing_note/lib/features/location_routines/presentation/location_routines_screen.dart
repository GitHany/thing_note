import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_routines/data/location_routine_provider.dart';

class LocationRoutinesScreen extends ConsumerWidget {
  const LocationRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(locationRoutineNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('位置触发Routine'),
      ),
      body: routinesAsync.when(
        data: (routines) => _buildRoutinesList(context, ref, routines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoutineDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加Routine'),
      ),
    );
  }

  Widget _buildRoutinesList(BuildContext context, WidgetRef ref, List<LocationRoutine> routines) {
    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无位置Routine', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: routine.isEnabled ? Colors.green.withOpacity(0.2) : Colors.grey[300],
              child: Icon(Icons.location_on, color: routine.isEnabled ? Colors.green : Colors.grey),
            ),
            title: Text(routine.locationName),
            subtitle: Text('${routine.triggerType} → ${routine.routineAction}'),
            trailing: Text('${routine.triggerCount}次'),
          ),
        );
      },
    );
  }

  void _showAddRoutineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String triggerType = 'arrive';
    String action = '记录位置';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加位置Routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '位置名称', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: triggerType,
              decoration: const InputDecoration(labelText: '触发类型', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'arrive', child: Text('到达')),
                DropdownMenuItem(value: 'leave', child: Text('离开')),
              ],
              onChanged: (v) => triggerType = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(locationRoutineNotifierProvider.notifier).addRoutine(
                  nameController.text, 0, 0, triggerType, action,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}