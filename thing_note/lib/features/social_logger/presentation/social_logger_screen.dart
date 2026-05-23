import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/social_interaction.dart';
import '../data/social_logger_repository.dart';

class SocialLoggerScreen extends ConsumerStatefulWidget {
  const SocialLoggerScreen({super.key});

  @override
  ConsumerState<SocialLoggerScreen> createState() => _SocialLoggerScreenState();
}

class _SocialLoggerScreenState extends ConsumerState<SocialLoggerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Interactions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(socialLoggerProvider.notifier).loadInteractions(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Interactions', icon: Icon(Icons.people)),
            Tab(text: 'People', icon: Icon(Icons.person_pin)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildInteractionsTab(),
          _buildPeopleTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInteractionDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Interaction'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final statsAsync = ref.watch(socialStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialStatsProvider);
        ref.read(socialLoggerProvider.notifier).loadInteractions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _buildStatsCard(stats),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPendingFollowUps(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(SocialStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 30 Days Statistics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem(Icons.event, '${stats.totalInteractions}', 'Interactions')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem(Icons.people, '${stats.uniquePeople}', 'People')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem(Icons.timer, _formatDuration(stats.totalMinutes), 'Total Time')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem(Icons.star, stats.avgQuality.toStringAsFixed(1), 'Avg Quality')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingFollowUps() {
    final followUpsAsync = ref.watch(pendingFollowUpsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notification_important, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Pending Follow-ups', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            followUpsAsync.when(
              data: (followUps) {
                if (followUps.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pending follow-ups'),
                  );
                }
                return Column(
                  children: followUps.take(5).map((i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(i.personName[0])),
                    title: Text(i.personName),
                    subtitle: Text('${i.interactionType.displayName} - ${_formatDate(i.interactionDate)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _markFollowUpComplete(i),
                    ),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsTab() {
    final state = ref.watch(socialLoggerProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No interactions logged yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap the button below to log your first interaction'),
          ],
        ),
      );
    }

    // Group interactions by date
    final groupedInteractions = _groupByDate(state.interactions);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedInteractions.length,
      itemBuilder: (context, index) {
        final date = groupedInteractions.keys.elementAt(index);
        final interactions = groupedInteractions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ...interactions.map((i) => _buildInteractionCard(i)),
          ],
        );
      },
    );
  }

  Widget _buildInteractionCard(SocialInteraction interaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showInteractionDetails(interaction),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildTypeIcon(interaction.interactionType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interaction.personName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${interaction.interactionType.displayName} • ${interaction.durationMinutes} min',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildQualityStars(interaction.qualityRating),
              if (interaction.followUpNeeded)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.notification_important, color: Colors.orange, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(InteractionType type) {
    IconData icon;
    Color color;

    switch (type) {
      case InteractionType.chat:
        icon = Icons.chat_bubble_outline;
        color = Colors.blue;
      case InteractionType.call:
        icon = Icons.phone;
        color = Colors.green;
      case InteractionType.meeting:
        icon = Icons.groups;
        color = Colors.purple;
      case InteractionType.dinner:
        icon = Icons.restaurant;
        color = Colors.orange;
      case InteractionType.event:
        icon = Icons.event;
        color = Colors.red;
      case InteractionType.videoCall:
        icon = Icons.videocam;
        color = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildQualityStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 16,
      )),
    );
  }

  Widget _buildPeopleTab() {
    final summaryAsync = ref.watch(interactionSummaryProvider);

    return summaryAsync.when(
      data: (people) {
        if (people.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No people tracked yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: people.length,
          itemBuilder: (context, index) {
            final person = people[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    person.personName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(person.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${person.interactionCount} interactions • ${_formatDuration(person.totalMinutes)} • Avg quality: ${person.avgQuality.toStringAsFixed(1)}',
                ),
                trailing: _buildQualityStars(person.avgQuality.round()),
                onTap: () => _showPersonDetails(person.personName),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Map<DateTime, List<SocialInteraction>> _groupByDate(List<SocialInteraction> interactions) {
    final grouped = <DateTime, List<SocialInteraction>>{};
    for (final interaction in interactions) {
      final date = DateTime(
        interaction.interactionDate.year,
        interaction.interactionDate.month,
        interaction.interactionDate.day,
      );
      grouped.putIfAbsent(date, () => []).add(interaction);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';

    return '${date.month}/${date.day}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';

    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${date.month}/${date.day}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  void _showAddInteractionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddInteractionSheet(),
    );
  }

  void _showInteractionDetails(SocialInteraction interaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InteractionDetailSheet(
        interaction: interaction,
        onDelete: () {
          if (interaction.id != null) {
            ref.read(socialLoggerProvider.notifier).deleteInteraction(interaction.id!);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPersonDetails(String personName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PersonDetailSheet(personName: personName),
    );
  }

  void _markFollowUpComplete(SocialInteraction interaction) {
    final updated = interaction.copyWith(followUpNeeded: false);
    ref.read(socialLoggerProvider.notifier).updateInteraction(updated);
  }
}

class _AddInteractionSheet extends ConsumerStatefulWidget {
  const _AddInteractionSheet();

  @override
  ConsumerState<_AddInteractionSheet> createState() => _AddInteractionSheetState();
}

class _AddInteractionSheetState extends ConsumerState<_AddInteractionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  InteractionType _interactionType = InteractionType.chat;
  int _qualityRating = 3;
  int _durationMinutes = 30;
  bool _followUpNeeded = false;
  final DateTime _interactionDate = DateTime.now();

  @override
  void dispose() {
    _personController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Log Interaction', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _personController,
                decoration: const InputDecoration(
                  labelText: 'Person Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<InteractionType>(
                value: _interactionType,
                decoration: const InputDecoration(
                  labelText: 'Interaction Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: InteractionType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (v) => setState(() => _interactionType = v ?? InteractionType.chat),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quality (1-5)'),
                        Row(
                          children: List.generate(5, (i) => IconButton(
                            icon: Icon(i < _qualityRating ? Icons.star : Icons.star_border),
                            color: Colors.amber,
                            onPressed: () => setState(() => _qualityRating = i + 1),
                          )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration: $_durationMinutes min'),
                        Slider(
                          value: _durationMinutes.toDouble(),
                          min: 5,
                          max: 240,
                          divisions: 47,
                          label: '$_durationMinutes min',
                          onChanged: (v) => setState(() => _durationMinutes = v.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Follow-up needed'),
                subtitle: const Text('Mark to receive a reminder'),
                value: _followUpNeeded,
                onChanged: (v) => setState(() => _followUpNeeded = v),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitInteraction,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Interaction'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submitInteraction() {
    if (!_formKey.currentState!.validate()) return;

    final interaction = SocialInteraction(
      personName: _personController.text.trim(),
      interactionType: _interactionType,
      durationMinutes: _durationMinutes,
      qualityRating: _qualityRating,
      location: _locationController.text.isEmpty ? null : _locationController.text.trim(),
      interactionDate: _interactionDate,
      note: _noteController.text.isEmpty ? null : _noteController.text.trim(),
      followUpNeeded: _followUpNeeded,
    );

    ref.read(socialLoggerProvider.notifier).addInteraction(interaction);
    ref.invalidate(socialStatsProvider);
    ref.invalidate(interactionSummaryProvider);
    ref.invalidate(pendingFollowUpsProvider);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interaction logged successfully!')),
    );
  }
}

class _InteractionDetailSheet extends StatelessWidget {
  final SocialInteraction interaction;
  final VoidCallback onDelete;

  const _InteractionDetailSheet({
    required this.interaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(interaction.personName, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Type', interaction.interactionType.displayName),
          _buildDetailRow('Date', _formatFullDate(interaction.interactionDate)),
          _buildDetailRow('Duration', '${interaction.durationMinutes} minutes'),
          _buildDetailRow('Quality', '${interaction.qualityRating}/5'),
          if (interaction.location != null)
            _buildDetailRow('Location', interaction.location!),
          if (interaction.topicsDiscussed.isNotEmpty)
            _buildDetailRow('Topics', interaction.topicsDiscussed.join(', ')),
          if (interaction.note != null)
            _buildDetailRow('Note', interaction.note!),
          _buildDetailRow('Follow-up', interaction.followUpNeeded ? 'Yes' : 'No'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interaction'),
        content: const Text('Are you sure you want to delete this interaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PersonDetailSheet extends ConsumerWidget {
  final String personName;

  const _PersonDetailSheet({required this.personName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  personName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(personName, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Interaction History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<SocialInteraction>>(
            future: ref.read(socialRepositoryProvider).getInteractionsByPerson(personName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final interactions = snapshot.data ?? [];
              if (interactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No interactions found'),
                );
              }

              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: interactions.length,
                  itemBuilder: (context, index) {
                    final i = interactions[index];
                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(i.interactionType.displayName),
                      subtitle: Text(_formatDate(i.interactionDate)),
                      trailing: Text('${i.durationMinutes} min'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}