import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/search/presentation/providers/search_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';

class AdvancedSearchDialog extends ConsumerStatefulWidget {
  final Function(String query, SearchFilters filters) onSearch;

  const AdvancedSearchDialog({
    super.key,
    required this.onSearch,
  });

  @override
  ConsumerState<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends ConsumerState<AdvancedSearchDialog> {
  final _searchController = TextEditingController();
  SearchFilters _filters = const SearchFilters();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    _filters = ref.read(searchFiltersProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            AppBar(
              title: Text(l10n.advancedSearch),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchRecords,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _performSearch(),
              ),
            ),

            // Quick filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.photos,
                    icon: Icons.photo,
                    isSelected: _filters.hasPhotos,
                    onTap: () {
                      setState(() {
                        _filters = _filters.copyWith(hasPhotos: !_filters.hasPhotos);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.audio,
                    icon: Icons.mic,
                    isSelected: _filters.hasAudio,
                    onTap: () {
                      setState(() {
                        _filters = _filters.copyWith(hasAudio: !_filters.hasAudio);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.videos,
                    icon: Icons.videocam,
                    isSelected: _filters.hasVideos,
                    onTap: () {
                      setState(() {
                        _filters = _filters.copyWith(hasVideos: !_filters.hasVideos);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.favorites,
                    icon: Icons.star,
                    isSelected: _filters.isFavorite == true,
                    onTap: () {
                      setState(() {
                        _filters = _filters.copyWith(
                          isFavorite: _filters.isFavorite == true ? null : true,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Advanced filters section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range section
                    _buildSectionTitle(l10n.dateRange),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerButton(
                            label: l10n.startDate,
                            date: _filters.startDate,
                            onClear: () {
                              setState(() {
                                _filters = _filters.copyWith(clearStartDate: true);
                              });
                            },
                            onPicked: (date) {
                              setState(() {
                                _filters = _filters.copyWith(startDate: date);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DatePickerButton(
                            label: l10n.endDate,
                            date: _filters.endDate,
                            onClear: () {
                              setState(() {
                                _filters = _filters.copyWith(clearEndDate: true);
                              });
                            },
                            onPicked: (date) {
                              setState(() {
                                _filters = _filters.copyWith(endDate: date);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Thing name filter
                    _buildSectionTitle(l10n.thingName),
                    const SizedBox(height: 8),
                    _ThingNameDropdown(
                      selectedId: _filters.thingNameId,
                      onChanged: (id) {
                        setState(() {
                          _filters = id == null
                              ? _filters.copyWith(clearThingNameId: true)
                              : _filters.copyWith(thingNameId: id);
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tag filter
                    _buildSectionTitle(l10n.tags),
                    const SizedBox(height: 8),
                    _TagDropdown(
                      selectedId: _filters.tagId,
                      onChanged: (id) {
                        setState(() {
                          _filters = id == null
                              ? _filters.copyWith(clearTagId: true)
                              : _filters.copyWith(tagId: id);
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_filters.hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filters = const SearchFilters();
                          _searchController.clear();
                        });
                      },
                      child: Text(l10n.clearFilters),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search),
                    label: Text(l10n.search),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  void _performSearch() {
    widget.onSearch(_searchController.text, _filters);

    // Add to search history
    if (_searchController.text.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearch(_searchController.text);
    }

    Navigator.pop(context);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onClear;
  final Function(DateTime) onPicked;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onClear,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(
        date != null
            ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
            : label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _ThingNameDropdown extends ConsumerWidget {
  final int? selectedId;
  final Function(int?) onChanged;

  const _ThingNameDropdown({
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thingNamesAsync = ref.watch(thingNameListProvider);
    final l10n = AppLocalizations.of(context)!;

    return thingNamesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(l10n.loadFailed('error')),
      data: (thingNames) {
        return DropdownButtonFormField<int?>(
          value: selectedId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text(l10n.pleaseSelect),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(l10n.doNotSelect),
            ),
            ...thingNames.map((tn) => DropdownMenuItem<int?>(
                  value: tn.id,
                  child: Text(tn.name),
                )),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _TagDropdown extends ConsumerWidget {
  final int? selectedId;
  final Function(int?) onChanged;

  const _TagDropdown({
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListProvider);
    final l10n = AppLocalizations.of(context)!;

    return tagsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(l10n.loadFailed('error')),
      data: (tags) {
        if (tags.isEmpty) {
          return Text(l10n.noTags);
        }
        return DropdownButtonFormField<int?>(
          value: selectedId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text(l10n.pleaseSelect),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(l10n.doNotSelect),
            ),
            ...tags.map((tag) => DropdownMenuItem<int?>(
                  value: tag.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tag.name),
                    ],
                  ),
                )),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}