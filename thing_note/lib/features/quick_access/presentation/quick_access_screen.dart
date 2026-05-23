import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/features/quick_access/domain/quick_access_repository.dart';
import 'package:thing_note/features/quick_access/presentation/providers/quick_access_provider.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class QuickAccessScreen extends ConsumerWidget {
  const QuickAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickAccessAsync = ref.watch(quickAccessDataProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.quickAccess),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak section
            _buildStreakSection(context, ref),
            const SizedBox(height: 20),

            // Frequently used
            _buildFrequentlyUsedSection(context, ref, quickAccessAsync, thingNamesAsync),
            const SizedBox(height: 20),

            // Quick actions
            _buildQuickActionsSection(context, ref),
            const SizedBox(height: 20),

            // Recent records
            _buildRecentRecordsSection(context, ref, quickAccessAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context, WidgetRef ref) {
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final longestStreakAsync = ref.watch(longestStreakProvider);

    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.recordStreaks,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  context,
                  title: AppLocalizations.of(context)!.currentStreak,
                  valueAsync: currentStreakAsync,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  context,
                  title: AppLocalizations.of(context)!.longestStreak,
                  valueAsync: longestStreakAsync,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context, {
    required String title,
    required AsyncValue<int> valueAsync,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          currentStreakValueBuilder(valueAsync, color),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget currentStreakValueBuilder(AsyncValue<int> valueAsync, Color color) {
    return valueAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(Icons.error, size: 32, color: color),
      data: (value) {
        if (value == 0) {
          return Column(
            children: [
              Icon(Icons.sentiment_dissatisfied, size: 32, color: color),
              const SizedBox(height: 4),
              Text(
                'No streak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          );
        }
        return Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              'days',
              style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrequentlyUsedSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuickAccessData> quickAccessAsync,
    AsyncValue<List<dynamic>> thingNamesAsync,
  ) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.frequentlyUsed,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          quickAccessAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading'),
            data: (data) {
              if (data.frequentlyUsedThingNameIds.isEmpty) {
                return Text(
                  'No frequently used items yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                );
              }

              return thingNamesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error'),
                data: (thingNames) {
                  final thingNameMap = {for (final tn in thingNames) if (tn.id != null) tn.id!: tn};

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.frequentlyUsedThingNameIds.take(5).map((id) {
                      final thingName = thingNameMap[id];
                      if (thingName == null) return const SizedBox.shrink();

                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${data.thingNameUsageCount[id] ?? 0}'),
                        ),
                        label: Text(thingName.name),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.quickActions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionChip(
                context,
                icon: Icons.add,
                label: AppLocalizations.of(context)!.newRecord,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => Navigator.pop(context),
              ),
              _buildActionChip(
                context,
                icon: Icons.search,
                label: AppLocalizations.of(context)!.search,
                color: Colors.blue,
                onTap: () {},
              ),
              _buildActionChip(
                context,
                icon: Icons.star,
                label: AppLocalizations.of(context)!.favorites,
                color: Colors.amber,
                onTap: () {},
              ),
              _buildActionChip(
                context,
                icon: Icons.alarm,
                label: AppLocalizations.of(context)!.reminders,
                color: Colors.orange,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecordsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuickAccessData> quickAccessAsync,
  ) {
    return Container(
      decoration: AppTheme.softCardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.recentRecords,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          quickAccessAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading'),
            data: (data) {
              if (data.recentRecordIds.isEmpty) {
                return Text(
                  'No recent records',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                );
              }

              // Show last 5 records
              return Column(
                children: data.recentRecordIds.take(5).map<Widget>((id) {
                  return _buildRecentRecordItem(context, ref, id);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordItem(BuildContext context, WidgetRef ref, int recordId) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));

    return recordAsync.when(
      loading: () => const ListTile(
        leading: CircularProgressIndicator(strokeWidth: 2),
        title: Text('Loading...'),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.error_outline),
        title: Text('Error loading record'),
      ),
      data: (record) {
        if (record == null) {
          return const SizedBox.shrink();
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getRecordIcon(record),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            record.note.isNotEmpty ? record.note : AppLocalizations.of(context)!.noNote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            DateFormatter.formatRelative(record.occurredAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.hasPhotos) const Icon(Icons.photo, size: 14, color: Colors.blue),
              if (record.hasAudio) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.mic, size: 14, color: Colors.orange)),
              if (record.hasVideos) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.videocam, size: 14, color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  IconData _getRecordIcon(dynamic record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }
}