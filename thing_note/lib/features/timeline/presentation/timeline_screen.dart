import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _timeRange = 'all'; // 'week', 'month', 'year', 'all'

  Future<void> _refresh() async {
    ref.invalidate(recordListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordListProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 20.0 : 16.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: Text(AppLocalizations.of(context)!.timeline),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: AppLocalizations.of(context)!.filterRecords,
              onSelected: (value) {
                setState(() => _timeRange = value);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'week',
                  child: Row(
                    children: [
                      if (_timeRange == 'week')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(ctx)!.thisWeek),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'month',
                  child: Row(
                    children: [
                      if (_timeRange == 'month')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(ctx)!.thisMonth),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'year',
                  child: Row(
                    children: [
                      if (_timeRange == 'year')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(ctx)!.thisYear),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      if (_timeRange == 'all')
                        const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(ctx)!.allTime),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (records) {
            final thingNames = thingNamesAsync.valueOrNull ?? [];
            final thingNameMap = {
              for (final tn in thingNames) if (tn.id != null) tn.id!: tn.name,
            };

            // Filter records based on time range
            final now = DateTime.now();
            final filteredRecords = records.where((record) {
              switch (_timeRange) {
                case 'week':
                  return record.occurredAt.isAfter(now.subtract(const Duration(days: 7)));
                case 'month':
                  return record.occurredAt.isAfter(DateTime(now.year, now.month - 1, now.day));
                case 'year':
                  return record.occurredAt.isAfter(DateTime(now.year - 1, now.month, now.day));
                default:
                  return true;
              }
            }).toList();

            if (filteredRecords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timeline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noData,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/record/new'),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addRecord),
                    ),
                  ],
                ),
              );
            }

            // Group records by time period
            final groupedRecords = _groupRecordsByTime(filteredRecords);

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              itemCount: groupedRecords.length,
              itemBuilder: (context, index) {
                final group = groupedRecords[index];
                return _buildTimeGroup(
                  context,
                  group['title'] as String,
                  group['records'] as List<EpisodeRecord>,
                  thingNameMap,
                  isFirst: index == 0,
                  isLast: index == groupedRecords.length - 1,
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

  List<Map<String, dynamic>> _groupRecordsByTime(List<EpisodeRecord> records) {
    final groups = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisYearStart = DateTime(now.year, 1, 1);

    // Group by time period
    final todayRecords = <EpisodeRecord>[];
    final yesterdayRecords = <EpisodeRecord>[];
    final thisWeekRecords = <EpisodeRecord>[];
    final thisMonthRecords = <EpisodeRecord>[];
    final thisYearRecords = <EpisodeRecord>[];
    final olderRecords = <EpisodeRecord>[];

    for (final record in records) {
      final recordDate = DateTime(
        record.occurredAt.year,
        record.occurredAt.month,
        record.occurredAt.day,
      );

      if (recordDate == today) {
        todayRecords.add(record);
      } else if (recordDate == yesterday) {
        yesterdayRecords.add(record);
      } else if (recordDate.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
        thisWeekRecords.add(record);
      } else if (recordDate.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        thisMonthRecords.add(record);
      } else if (recordDate.isAfter(thisYearStart.subtract(const Duration(days: 1)))) {
        thisYearRecords.add(record);
      } else {
        olderRecords.add(record);
      }
    }

    // Build groups with headers
    if (todayRecords.isNotEmpty) {
      groups.add({'title': AppLocalizations.of(context)!.today, 'records': todayRecords});
    }
    if (yesterdayRecords.isNotEmpty) {
      groups.add({'title': AppLocalizations.of(context)!.yesterday, 'records': yesterdayRecords});
    }
    if (thisWeekRecords.isNotEmpty) {
      groups.add({
        'title': AppLocalizations.of(context)!.thisWeek,
        'records': thisWeekRecords
      });
    }
    if (thisMonthRecords.isNotEmpty) {
      groups.add({
        'title': AppLocalizations.of(context)!.thisMonth,
        'records': thisMonthRecords
      });
    }
    if (thisYearRecords.isNotEmpty) {
      groups.add({
        'title': AppLocalizations.of(context)!.thisYear,
        'records': thisYearRecords
      });
    }
    if (olderRecords.isNotEmpty) {
      groups.add({
        'title': AppLocalizations.of(context)!.older,
        'records': olderRecords
      });
    }

    return groups;
  }

  Widget _buildTimeGroup(
    BuildContext context,
    String title,
    List<EpisodeRecord> records,
    Map<int, String> thingNameMap,
    {bool isFirst = false, bool isLast = false}
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final groupPadding = isWideScreen ? 16.0 : 12.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time period header
        Padding(
          padding: EdgeInsets.only(top: groupPadding, bottom: groupPadding / 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${records.length})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        // Timeline line
        if (!isFirst)
          Container(
            margin: const EdgeInsets.only(left: 5),
            width: 2,
            height: 8,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        // Records
        ...records.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          final isFirstRecord = index == 0;
          final isLastRecord = index == records.length - 1;
          final thingName = record.thingNameId != null
              ? thingNameMap[record.thingNameId]
              : null;

          return _buildTimelineItem(
            context,
            record,
            thingName,
            isFirstRecord: isFirstRecord,
            isLastRecord: isLastRecord,
            isLastGroup: isLast && isLastRecord,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    EpisodeRecord record,
    String? thingName, {
    bool isFirstRecord = false,
    bool isLastRecord = false,
    bool isLastGroup = false,
  }) {
    final lineColor = Theme.of(context).colorScheme.outline.withOpacity(0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator and line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top line
                if (!isFirstRecord)
                  Container(
                    width: 2,
                    height: 12,
                    color: lineColor,
                  ),
                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: record.hasLocation
                        ? Colors.green
                        : record.isFavorite
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                // Bottom line
                if (!isLastRecord || !isLastGroup)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Record card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/record/${record.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time and icon row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(record.occurredAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                            const Spacer(),
                            if (record.hasPhotos)
                              const Icon(Icons.photo, size: 14, color: Colors.blue),
                            if (record.hasAudio)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.mic, size: 14, color: Colors.orange),
                              ),
                            if (record.hasVideos)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.videocam, size: 14, color: Colors.red),
                              ),
                            if (record.hasLocation)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.location_on, size: 14, color: Colors.green),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Row(
                          children: [
                            if (record.isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.star, size: 16, color: Colors.amber),
                              ),
                            Expanded(
                              child: Text(
                                thingName ??
                                    (record.note.isNotEmpty
                                        ? record.note
                                        : AppLocalizations.of(context)!.noNote),
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Duration
                        if (record.durationSec > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(record.durationSec),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}