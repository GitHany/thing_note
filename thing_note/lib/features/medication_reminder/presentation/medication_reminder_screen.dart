import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/medication_reminder/data/medication_repository.dart';
import 'package:thing_note/features/medication_reminder/domain/medication.dart';

class MedicationReminderScreen extends ConsumerStatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  ConsumerState<MedicationReminderScreen> createState() => _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends ConsumerState<MedicationReminderScreen> {
  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('药物提醒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMedicationDialog(context),
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (meds) {
          if (meds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无药物记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddMedicationDialog(context),
                    child: const Text('添加药物'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (context, index) => _MedicationCard(medication: meds[index]),
          );
        },
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加药物'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '药物名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: '剂量（可选）'),
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
                final med = Medication(
                  name: nameController.text.trim(),
                  dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(medicationsProvider.notifier).addMedication(med);
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

class _MedicationCard extends ConsumerWidget {
  final Medication medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMedicationDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: medication.isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.medication, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (medication.dosage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        medication.dosage!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    if (medication.frequency != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        medication.frequency!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(medicationsProvider.notifier).logMedicationTaken(medication.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已记录服用 ${medication.name}')),
                  );
                },
                child: const Text('服用'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(medication.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (medication.dosage != null) Text('剂量: ${medication.dosage}'),
            if (medication.frequency != null) Text('频率: ${medication.frequency}'),
            if (medication.instructions != null) Text('说明: ${medication.instructions}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(medicationsProvider.notifier).deleteMedication(medication.id!);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}