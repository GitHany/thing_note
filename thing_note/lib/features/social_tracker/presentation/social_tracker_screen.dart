import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/social_tracker/data/social_tracker_repository.dart';
import 'package:thing_note/features/social_tracker/domain/social_interaction.dart';

class SocialTrackerScreen extends ConsumerStatefulWidget {
  const SocialTrackerScreen({super.key});

  @override
  ConsumerState<SocialTrackerScreen> createState() => _SocialTrackerScreenState();
}

class _SocialTrackerScreenState extends ConsumerState<SocialTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final interactionsAsync = ref.watch(socialInteractionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('社交互动'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddInteractionDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekly summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.purple),
                const SizedBox(width: 8),
                const Text('本周互动: ', style: TextStyle(fontSize: 16)),
                FutureBuilder<int>(
                  future: ref.read(socialTrackerRepositoryProvider).getInteractionCountThisWeek(),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0} 次',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                    );
                  },
                ),
              ],
            ),
          ),
          // Recent contacts
          Expanded(
            child: interactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (interactions) {
                if (interactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无互动记录', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddInteractionDialog(context),
                          child: const Text('记录互动'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: interactions.length,
                  itemBuilder: (context, index) => _InteractionCard(interaction: interactions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddInteractionDialog(BuildContext context) {
    final nameController = TextEditingController();
    InteractionType selectedType = InteractionType.meet;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录互动'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '联系人/群组名称'),
                ),
                const SizedBox(height: 16),
                const Text('互动类型'),
                Wrap(
                  spacing: 8,
                  children: InteractionType.values.map((t) => ChoiceChip(
                    label: Text('${t.icon} ${t.displayName}'),
                    selected: selectedType == t,
                    onSelected: (selected) => setState(() => selectedType = t),
                  )).toList(),
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
                final interaction = SocialInteraction(
                  contactName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  interactionType: selectedType,
                  occurredAt: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                ref.read(socialInteractionsProvider.notifier).addInteraction(interaction);
                Navigator.pop(context);
              },
              child: const Text('记录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionCard extends ConsumerWidget {
  final SocialInteraction interaction;

  const _InteractionCard({required this.interaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.2),
          child: Text(interaction.interactionType.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(interaction.contactName ?? interaction.interactionType.displayName),
        subtitle: Text(interaction.interactionType.displayName),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref.read(socialInteractionsProvider.notifier).deleteInteraction(interaction.id!),
        ),
      ),
    );
  }
}