import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/relationship_models.dart';
import '../data/relationship_repository.dart';

final relationshipProvider = StateNotifierProvider<RelationshipNotifier, RelationshipState>((ref) {
  return RelationshipNotifier(ref.watch(relationshipRepositoryProvider));
});

class RelationshipState {
  final List<Relationship> relationships;
  final List<Relationship> needAttention;
  final bool isLoading;
  final String? error;

  RelationshipState({
    this.relationships = const [],
    this.needAttention = const [],
    this.isLoading = false,
    this.error,
  });

  RelationshipState copyWith({
    List<Relationship>? relationships,
    List<Relationship>? needAttention,
    bool? isLoading,
    String? error,
  }) {
    return RelationshipState(
      relationships: relationships ?? this.relationships,
      needAttention: needAttention ?? this.needAttention,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RelationshipNotifier extends StateNotifier<RelationshipState> {
  final RelationshipRepository _repository;

  RelationshipNotifier(this._repository) : super(RelationshipState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final relationships = await _repository.getAllRelationships();
      final needAttention = await _repository.getNeedAttention();
      state = state.copyWith(
        relationships: relationships,
        needAttention: needAttention,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addRelationship(Relationship relationship) async {
    try {
      await _repository.insertRelationship(relationship);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addInteraction(RelationshipInteraction interaction) async {
    try {
      await _repository.insertInteraction(interaction);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final relationshipStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(relationshipRepositoryProvider).getRelationshipStats();
});

class RelationshipTrackerScreen extends ConsumerStatefulWidget {
  const RelationshipTrackerScreen({super.key});

  @override
  ConsumerState<RelationshipTrackerScreen> createState() => _RelationshipTrackerScreenState();
}

class _RelationshipTrackerScreenState extends ConsumerState<RelationshipTrackerScreen> {
  final _nameController = TextEditingController();
  String _type = 'friend';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(relationshipProvider);
    final statsAsync = ref.watch(relationshipStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relationship Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            statsAsync.when(
              data: (stats) => _buildStats(stats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Need Attention
            if (state.needAttention.isNotEmpty) ...[
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('Need Attention (${state.needAttention.length})'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...state.needAttention.take(3).map((r) => ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(r.personName),
                        subtitle: Text('Last: ${_formatDate(r.lastContactDate)}'),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Add Relationship
            _buildAddForm(),
            const SizedBox(height: 16),

            // All Relationships
            Text('All Relationships', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.relationships.map((r) => _buildRelationshipCard(r)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', '${stats['total'] ?? 0}'),
            _buildStatItem('Avg Closeness', (stats['avg_closeness'] as num?)?.toStringAsFixed(1) ?? '0'),
            _buildStatItem('Contacts', '${stats['total_contacts'] ?? 0}'),
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

  Widget _buildAddForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Person', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ['family', 'friend', 'colleague', 'partner', 'other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'friend'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addRelationship,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipCard(Relationship relationship) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(relationship.personName[0])),
        title: Text(relationship.personName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(relationship.relationshipType ?? 'Unknown'),
            Row(
              children: List.generate(5, (i) => Icon(
                i < relationship.closenessLevel ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              )),
            ),
          ],
        ),
        trailing: Text(_formatDate(relationship.lastContactDate)),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}';
  }

  void _addRelationship() {
    if (_nameController.text.isEmpty) return;
    final relationship = Relationship(
      personName: _nameController.text,
      relationshipType: _type,
    );
    ref.read(relationshipProvider.notifier).addRelationship(relationship);
    _nameController.clear();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: _buildAddForm(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}