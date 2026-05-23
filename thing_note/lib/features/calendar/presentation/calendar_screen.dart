import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Cache for date grouping - recomputed only when records change
  Map<DateTime, List<EpisodeRecord>> _cachedRecordsByDate = {};

  // Responsive marker size
  double _getMarkerSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 6.0;
    if (screenWidth > 600) return 8.0;
    return 7.0;
  }

  Future<void> _refresh() async {
    _cachedRecordsByDate = {};
    ref.invalidate(recordListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordListProvider);
    final thingNamesAsync = ref.watch(thingNameListProvider);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    
    // Responsive spacing
    final horizontalPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final iconSize = isUltraSmall ? 18.0 : (isSmall ? 20.0 : 24.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: iconSize),
            onPressed: () => context.go('/'),
          ),
          title: Text(AppLocalizations.of(context)!.calendar),
          actions: [
            IconButton(
              icon: Icon(Icons.today, size: iconSize),
              tooltip: AppLocalizations.of(context)!.today,
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
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

              // Build records by date map if needed
              if (_cachedRecordsByDate.isEmpty && records.isNotEmpty) {
                final recordsByDate = <DateTime, List<EpisodeRecord>>{};
                for (final record in records) {
                  final date = DateTime(record.occurredAt.year, record.occurredAt.month, record.occurredAt.day);
                  recordsByDate.putIfAbsent(date, () => []).add(record);
                }
                _cachedRecordsByDate = recordsByDate;
              }

              final recordsByDate = _cachedRecordsByDate;

              return Column(
                children: [
                  TableCalendar<EpisodeRecord>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) {
                    final date = DateTime(day.year, day.month, day.day);
                    return recordsByDate[date] ?? [];
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: isUltraSmall ? 11 : 12,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: isUltraSmall ? 11 : 12,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSize: _getMarkerSize(context),
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    // Responsive day cell size
                    cellMargin: EdgeInsets.all(isUltraSmall ? 2 : (isSmall ? 3 : 4)),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(isUltraSmall ? 8 : 10),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: isUltraSmall ? 10 : 12,
                    ),
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: isUltraSmall ? 14 : 16,
                    ),
                    leftChevronPadding: EdgeInsets.all(isUltraSmall ? 4 : 6),
                    rightChevronPadding: EdgeInsets.all(isUltraSmall ? 4 : 6),
                  ),
                  daysOfWeekHeight: isUltraSmall ? 28 : (isSmall ? 32 : 36),
                  rowHeight: isUltraSmall ? 38 : (isSmall ? 42 : 46),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      final dayRecords = events.cast<EpisodeRecord>();
                      final hasPhotos = dayRecords.any((r) => r.hasPhotos);
                      final hasAudio = dayRecords.any((r) => r.hasAudio);
                      final hasVideos = dayRecords.any((r) => r.hasVideos);

                      // Responsive marker size
                      final markerSize = isUltraSmall ? 3.0 : (isSmall ? 4.0 : 5.0);

                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasPhotos)
                              Container(
                                width: markerSize,
                                height: markerSize,
                                margin: EdgeInsets.symmetric(horizontal: isUltraSmall ? 0.3 : 0.5),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasAudio)
                              Container(
                                width: markerSize,
                                height: markerSize,
                                margin: EdgeInsets.symmetric(horizontal: isUltraSmall ? 0.3 : 0.5),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasVideos)
                              Container(
                                width: markerSize,
                                height: markerSize,
                                margin: EdgeInsets.symmetric(horizontal: isUltraSmall ? 0.3 : 0.5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  color: Theme.of(context).colorScheme.outlineVariant.withAlpha(128),
                ),
                Expanded(
                  child: _selectedDay == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: isUltraSmall ? 48 : 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              SizedBox(height: isUltraSmall ? 12 : 16),
                              Text(
                                AppLocalizations.of(context)!.selectDayToViewRecords,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                      fontSize: isUltraSmall ? 13 : 14,
                                    ),
                              ),
                              SizedBox(height: isUltraSmall ? 12 : 16),
                              FilledButton.icon(
                                onPressed: () {
                                  context.push('/record/new');
                                },
                                icon: Icon(Icons.add, size: isUltraSmall ? 16 : 18),
                                label: Text(AppLocalizations.of(context)!.addRecord),
                              ),
                            ],
                          ),
                        )
                      : _buildDayRecords(
                          context,
                          recordsByDate[DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                          )] ?? [],
                          thingNameMap,
                          horizontalPadding,
                          isUltraSmall,
                        ),
                ),
              ],
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildDayRecords(
    BuildContext context,
    List<EpisodeRecord> records,
    Map<int, String> thingNameMap,
    double horizontalPadding,
    bool isUltraSmall,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = AppSpacing.isSmall(screenWidth);
    final isLargeScreen = AppSpacing.isLarge(screenWidth);
    
    final itemPadding = isUltraSmall ? 10.0 : (isSmall ? 12.0 : (isLargeScreen ? 16.0 : 14.0));
    final iconSize = isUltraSmall ? 28.0 : (isSmall ? 32.0 : 40.0);
    final emptyIconSize = isUltraSmall ? 48.0 : 64.0;
    
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: emptyIconSize,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: isUltraSmall ? 12 : 16),
            Text(
              AppLocalizations.of(context)!.noRecordsOnDay,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: isUltraSmall ? 13 : 14,
                  ),
            ),
            SizedBox(height: isUltraSmall ? 12 : 16),
            FilledButton.icon(
              onPressed: () {
                context.push('/record/new');
              },
              icon: Icon(Icons.add, size: isUltraSmall ? 16 : 18),
              label: Text(AppLocalizations.of(context)!.addRecord),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: isUltraSmall ? 10 : 14,
          ),
          child: Row(
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(_selectedDay!),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: isUltraSmall ? 14 : 16,
                ),
              ),
              SizedBox(width: isUltraSmall ? 4 : 8),
              Text(
                '(${records.length} ${AppLocalizations.of(context)!.records})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: isUltraSmall ? 11 : 12,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: isUltraSmall ? 12 : 16, 
              left: horizontalPadding, 
              right: horizontalPadding,
            ),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final thingName = record.thingNameId != null
                  ? thingNameMap[record.thingNameId]
                  : null;

              return Card(
                margin: EdgeInsets.only(bottom: isUltraSmall ? 6 : 8),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: itemPadding, 
                    vertical: isUltraSmall ? 6 : (itemPadding / 2),
                  ),
                  leading: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(isUltraSmall ? 6 : 8),
                    ),
                    child: Icon(
                      _getRecordIcon(record),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: isUltraSmall ? 16 : 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      if (record.isFavorite)
                        Padding(
                          padding: EdgeInsets.only(right: isUltraSmall ? 2 : 4),
                          child: Icon(
                            Icons.star,
                            size: isUltraSmall ? 12 : 16,
                            color: Colors.amber,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          thingName ?? (record.note.isNotEmpty
                              ? record.note
                              : AppLocalizations.of(context)!.noNote),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isUltraSmall ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    DateFormat('HH:mm').format(record.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isUltraSmall ? 10 : 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (record.hasPhotos)
                        Icon(Icons.photo, size: isUltraSmall ? 12 : 16, color: Colors.blue),
                      if (record.hasAudio)
                        Padding(
                          padding: EdgeInsets.only(left: isUltraSmall ? 2 : 4),
                          child: Icon(Icons.mic, size: isUltraSmall ? 12 : 16, color: Colors.orange),
                        ),
                      if (record.hasVideos)
                        Padding(
                          padding: EdgeInsets.only(left: isUltraSmall ? 2 : 4),
                          child: Icon(Icons.videocam, size: isUltraSmall ? 12 : 16, color: Colors.red),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/record/${record.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getRecordIcon(EpisodeRecord record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }
}