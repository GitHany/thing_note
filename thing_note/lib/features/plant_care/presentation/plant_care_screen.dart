import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/plant_care/data/plant_repository.dart';
import 'package:thing_note/features/plant_care/domain/plant.dart';

class PlantCareScreen extends ConsumerStatefulWidget {
  const PlantCareScreen({super.key});

  @override
  ConsumerState<PlantCareScreen> createState() => _PlantCareScreenState();
}

class _PlantCareScreenState extends ConsumerState<PlantCareScreen> {
  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('植物养护'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPlantDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Plants needing water
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: ref.watch(plantsNeedingWaterProvider).when(
              data: (plants) {
                if (plants.isEmpty) return const Text('所有植物都浇过水了 🌱');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('需要浇水:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...plants.map((p) => ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text(p.name),
                      trailing: ElevatedButton(
                        onPressed: () => ref.read(plantsProvider.notifier).waterPlant(p.id!),
                        child: const Text('浇水'),
                      ),
                    )),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('错误: $e'),
            ),
          ),
          // All plants
          Expanded(
            child: plantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (plants) {
                if (plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_florist, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无植物', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddPlantDialog(context),
                          child: const Text('添加植物'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plants.length,
                  itemBuilder: (context, index) => _PlantCard(plant: plants[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final speciesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加植物'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '植物名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: speciesController,
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
                final plant = Plant(
                  name: nameController.text.trim(),
                  species: speciesController.text.trim().isEmpty ? null : speciesController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(plantsProvider.notifier).addPlant(plant);
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

class _PlantCard extends ConsumerWidget {
  final Plant plant;

  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(Icons.local_florist, color: Colors.green),
        ),
        title: Text(plant.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plant.species != null) Text('品种: ${plant.species}'),
            Row(
              children: [
                Text('状态: ${plant.status.displayName}'),
                if (plant.needsWater) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('需要浇水', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'water':
                ref.read(plantsProvider.notifier).waterPlant(plant.id!);
                break;
              case 'fertilize':
                ref.read(plantsProvider.notifier).fertilizePlant(plant.id!);
                break;
              case 'delete':
                ref.read(plantsProvider.notifier).deletePlant(plant.id!);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'water', child: Text('💧 浇水')),
            const PopupMenuItem(value: 'fertilize', child: Text('🌿 施肥')),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ 删除')),
          ],
        ),
      ),
    );
  }
}