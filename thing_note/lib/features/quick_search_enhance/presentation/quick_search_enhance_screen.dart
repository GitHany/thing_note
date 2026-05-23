import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_search_enhance/data/search_provider.dart';
import 'package:thing_note/features/quick_search_enhance/domain/search_config.dart';

class QuickSearchEnhanceScreen extends ConsumerStatefulWidget {
  const QuickSearchEnhanceScreen({super.key});

  @override
  ConsumerState<QuickSearchEnhanceScreen> createState() => _QuickSearchEnhanceScreenState();
}

class _QuickSearchEnhanceScreenState extends ConsumerState<QuickSearchEnhanceScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  DateTime? _startDate;
  DateTime? _endDate;
  bool? _hasPhotos;
  bool? _hasAudio;
  bool? _hasVideo;
  bool? _hasLocation;
  bool? _isFavorite;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(quickSearchNotifierProvider);
    final historyAsync = ref.watch(searchHistoryProvider);
    final savedSearchesAsync = ref.watch(savedSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Search'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(quickSearchNotifierProvider.notifier).clearResults();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) => _performSearch(),
              onChanged: (value) {
                // Debounce could be added here
              },
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(),

          // Saved searches
          savedSearchesAsync.when(
            data: (savedSearches) {
              if (savedSearches.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedSearches.length,
                  itemBuilder: (context, index) {
                    final search = savedSearches[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(search.name),
                        onPressed: () {
                          ref.read(quickSearchNotifierProvider.notifier).loadSavedSearch(search.id!);
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Results or history
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (results.isEmpty) {
                  // Show history when no search
                  return historyAsync.when(
                    data: (history) {
                      if (history.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Start typing to search', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Recent Searches',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: history.length,
                              itemBuilder: (context, index) {
                                final entry = history[index];
                                return ListTile(
                                  leading: const Icon(Icons.history),
                                  title: Text(entry.query),
                                  subtitle: Text('${entry.resultCount} results'),
                                  onTap: () {
                                    _searchController.text = entry.query;
                                    _performSearch();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            result.recordId.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(
                          result.note.isNotEmpty ? result.note : 'No content',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(result.occurredAt)),
                            Row(
                              children: [
                                if (result.hasPhotos) const Icon(Icons.photo, size: 14),
                                if (result.hasAudio) const Icon(Icons.audiotrack, size: 14),
                                if (result.hasVideo) const Icon(Icons.videocam, size: 14),
                                if (result.hasLocation) const Icon(Icons.location_on, size: 14),
                                if (result.isFavorite) const Icon(Icons.star, size: 14, color: Colors.amber),
                              ],
                            ),
                            if (result.tags.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: result.tags.take(3).map((t) => Chip(
                                  label: Text(t, style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                )).toList(),
                              ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to record detail
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_startDate != null ? _formatDate(_startDate!) : 'Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_endDate != null ? _formatDate(_endDate!) : 'End'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('📷 Photos'),
                selected: _hasPhotos == true,
                onSelected: (v) => setState(() => _hasPhotos = v ? true : null),
              ),
              FilterChip(
                label: const Text('🎵 Audio'),
                selected: _hasAudio == true,
                onSelected: (v) => setState(() => _hasAudio = v ? true : null),
              ),
              FilterChip(
                label: const Text('📹 Video'),
                selected: _hasVideo == true,
                onSelected: (v) => setState(() => _hasVideo = v ? true : null),
              ),
              FilterChip(
                label: const Text('📍 Location'),
                selected: _hasLocation == true,
                onSelected: (v) => setState(() => _hasLocation = v ? true : null),
              ),
              FilterChip(
                label: const Text('⭐ Favorite'),
                selected: _isFavorite == true,
                onSelected: (v) => setState(() => _isFavorite = v ? true : null),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _hasPhotos = null;
                _hasAudio = null;
                _hasVideo = null;
                _hasLocation = null;
                _isFavorite = null;
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _performSearch() {
    final filter = SearchFilter(
      startDate: _startDate,
      endDate: _endDate,
      hasPhotos: _hasPhotos,
      hasAudio: _hasAudio,
      hasVideo: _hasVideo,
      hasLocation: _hasLocation,
      isFavorite: _isFavorite,
    );
    ref.read(quickSearchNotifierProvider.notifier).search(_searchController.text, filter: filter);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}