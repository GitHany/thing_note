import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/search/presentation/providers/search_provider.dart';
import 'package:thing_note/features/search/presentation/advanced_search_dialog.dart';
import 'package:thing_note/features/search/presentation/voice_search_widget.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final filters = ref.watch(searchFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchRecords),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showAdvancedSearch(context, ref),
            tooltip: l10n.advancedSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with voice
          _buildSearchBar(context, ref),

          // Active filters indicator
          if (filters.hasActiveFilters) _buildActiveFiltersBar(context, ref, filters),

          // Search results
          Expanded(
            child: searchResultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(l10n.loadFailed(err.toString()))),
              data: (results) {
                if (results.isEmpty) {
                  return _buildEmptyState(context, l10n);
                }
                return _buildSearchResults(context, ref, results, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref.read(searchHistoryProvider.notifier).addSearch(value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Voice search button
          FloatingActionButton.small(
            onPressed: () => _showVoiceSearchDialog(context, ref),
            child: const Icon(Icons.mic),
          ),
        ],
      ),
    );
  }

  Future<void> _showVoiceSearchDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VoiceSearchDialog(
        onResult: (text) {
          Navigator.pop(ctx);
          _searchController.text = text;
          ref.read(searchQueryProvider.notifier).state = text;
          if (text.isNotEmpty) {
            ref.read(searchHistoryProvider.notifier).addSearch(text);
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _searchController.text = result;
      ref.read(searchQueryProvider.notifier).state = result;
      ref.read(searchHistoryProvider.notifier).addSearch(result);
    }
  }

  Widget _buildActiveFiltersBar(BuildContext context, WidgetRef ref, SearchFilters filters) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (filters.hasPhotos) _buildFilterChip(context, l10n.photos, Icons.photo),
                if (filters.hasAudio) _buildFilterChip(context, l10n.audio, Icons.mic),
                if (filters.hasVideos) _buildFilterChip(context, l10n.videos, Icons.videocam),
                if (filters.isFavorite == true) _buildFilterChip(context, l10n.favorites, Icons.star),
                if (filters.startDate != null)
                  _buildFilterChip(
                    context,
                    DateFormatter.formatDate(filters.startDate!),
                    Icons.calendar_today,
                    isDate: true,
                  ),
                if (filters.thingNameId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final thingNamesAsync = ref.watch(thingNameListProvider);
                      return thingNamesAsync.when(
                        data: (names) {
                          final name = names.firstWhere(
                            (n) => n.id == filters.thingNameId,
                            orElse: () => throw Exception(),
                          );
                          return _buildFilterChip(context, name.name, Icons.category);
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
            },
            child: Text(l10n.clearFilters),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, IconData icon, {bool isDate = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSearchResults,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词或调整筛选条件',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    WidgetRef ref,
    List<EpisodeRecord> results,
    AppLocalizations l10n,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final record = results[index];
        return _SearchResultCard(
          record: record,
          onTap: () => context.push('/record/${record.id}'),
        );
      },
    );
  }

  void _showAdvancedSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AdvancedSearchDialog(
        onSearch: (query, filters) {
          _searchController.text = query;
          ref.read(searchQueryProvider.notifier).state = query;
          ref.read(searchFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final EpisodeRecord record;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thingNamesAsync = ref.watch(thingNameListProvider);

    String? thingName;
    try {
      final names = thingNamesAsync.valueOrNull ?? [];
      final found = names.firstWhere((n) => n.id == record.thingNameId);
      thingName = found.name;
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRecordIcon(record),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (thingName != null)
                          Text(
                            thingName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        Text(
                          DateFormatter.formatDateTime(record.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (record.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),

              // Note preview
              if (record.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  record.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // Media indicators
              const SizedBox(height: 8),
              Row(
                children: [
                  if (record.photoPaths.isNotEmpty)
                    _buildMediaIndicator(
                      context,
                      Icons.photo,
                      '${record.photoPaths.length}',
                      Colors.blue,
                    ),
                  if (record.audioPaths.isNotEmpty)
                    _buildMediaIndicator(
                      context,
                      Icons.mic,
                      '${record.audioPaths.length}',
                      Colors.orange,
                    ),
                  if (record.videoPaths.isNotEmpty)
                    _buildMediaIndicator(
                      context,
                      Icons.videocam,
                      '${record.videoPaths.length}',
                      Colors.red,
                    ),
                  if (record.documentPaths.isNotEmpty)
                    _buildMediaIndicator(
                      context,
                      Icons.description,
                      '${record.documentPaths.length}',
                      Colors.purple,
                    ),
                  const Spacer(),
                  if (record.address != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          record.address!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaIndicator(BuildContext context, IconData icon, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
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