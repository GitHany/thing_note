import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pet_management/data/pet_repository.dart';
import 'package:thing_note/features/pet_management/domain/pet.dart';
import 'package:thing_note/features/pet_management/domain/pet_care_log.dart';

class PetManagementScreen extends ConsumerStatefulWidget {
  const PetManagementScreen({super.key});

  @override
  ConsumerState<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends ConsumerState<PetManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('宠物管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPetDialog(context),
          ),
        ],
      ),
      body: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无宠物', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddPetDialog(context),
                    child: const Text('添加宠物'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) => _PetCard(pet: pets[index]),
          );
        },
      ),
    );
  }

  void _showAddPetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    PetType selectedType = PetType.dog;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加宠物'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '宠物名称'),
                ),
                const SizedBox(height: 16),
                DropdownButton<PetType>(
                  value: selectedType,
                  isExpanded: true,
                  items: PetType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text('${t.icon} ${t.displayName}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: breedController,
                  decoration: const InputDecoration(labelText: '品种（可选）'),
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
                  final now = DateTime.now();
                  final pet = Pet(
                    name: nameController.text.trim(),
                    type: selectedType,
                    breed: breedController.text.trim().isEmpty ? null : breedController.text.trim(),
                    createdAt: now,
                    updatedAt: now,
                  );
                  ref.read(petsProvider.notifier).addPet(pet);
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends ConsumerWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPetDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(pet.type.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed ?? pet.type.displayName,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (pet.birthDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${pet.ageInYears} 岁',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_task),
                onPressed: () => _showAddCareLogDialog(context, ref),
                tooltip: '添加护理记录',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPetDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pet.type.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(child: Text(pet.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text('类型: ${pet.type.displayName}'),
            if (pet.breed != null) Text('品种: ${pet.breed}'),
            if (pet.ageInYears > 0) Text('年龄: ${pet.ageInYears} 岁'),
            const SizedBox(height: 16),
            const Text('护理记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final logsAsync = ref.watch(petCareLogsProvider(pet.id!));
                return logsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('错误: $e'),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const Text('暂无护理记录');
                    }
                    return Column(
                      children: logs.take(5).map((log) => ListTile(
                        leading: Text(log.careType.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(log.careType.displayName),
                        subtitle: Text(_formatDate(log.date)),
                      )).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCareLogDialog(BuildContext context, WidgetRef ref) {
    CareType selectedType = CareType.feeding;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加护理记录'),
          content: SingleChildScrollView(
            child: DropdownButton<CareType>(
              value: selectedType,
              isExpanded: true,
              items: CareType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text('${t.icon} ${t.displayName}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedType = v!),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final log = PetCareLog(
                  petId: pet.id!,
                  careType: selectedType,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                ref.read(petCareLogsProvider(pet.id!).notifier).addCareLog(log);
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}