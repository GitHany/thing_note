import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_search_suggestion/data/smart_search_suggestion_service.dart';
import '../domain/smart_search_suggestion_models.dart';

/// 智能搜索建议组件
class SmartSearchSuggestions extends ConsumerStatefulWidget {
  final String? currentQuery;
  final Function(String) onSuggestionTap;
  final int maxSuggestions;

  const SmartSearchSuggestions({
    super.key,
    this.currentQuery,
    required this.onSuggestionTap,
    this.maxSuggestions = 8,
  });

  @override
  ConsumerState<SmartSearchSuggestions> createState() => _SmartSearchSuggestionsState();
}

class _SmartSearchSuggestionsState extends ConsumerState<SmartSearchSuggestions> {
  List<SearchSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(SmartSearchSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuery != widget.currentQuery) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(smartSearchSuggestionServiceProvider);
      final suggestions = await service.getSuggestions(
        currentQuery: widget.currentQuery,
        limit: widget.maxSuggestions,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((suggestion) {
        return _buildSuggestionChip(suggestion);
      }).toList(),
    );
  }

  Widget _buildSuggestionChip(SearchSuggestion suggestion) {
    IconData icon;
    Color? iconColor;

    switch (suggestion.type) {
      case SuggestionType.history:
        icon = Icons.history;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case SuggestionType.popular:
        icon = Icons.trending_up;
        iconColor = Colors.orange;
        break;
      case SuggestionType.smart:
        icon = Icons.auto_awesome;
        iconColor = Colors.purple;
        break;
      case SuggestionType.tag:
        icon = Icons.label;
        iconColor = Colors.blue;
        break;
      case SuggestionType.thing:
        icon = Icons.category;
        iconColor = Colors.green;
        break;
      case SuggestionType.recent:
        icon = Icons.schedule;
        iconColor = Colors.grey;
        break;
    }

    return ActionChip(
      avatar: Icon(icon, size: 16, color: iconColor),
      label: Text(suggestion.query),
      onPressed: () => widget.onSuggestionTap(suggestion.query),
    );
  }
}

/// 搜索建议行
class SearchSuggestionRow extends StatelessWidget {
  final List<SearchSuggestion> suggestions;
  final Function(String) onTap;
  final String title;

  const SearchSuggestionRow({
    super.key,
    required this.suggestions,
    required this.onTap,
    this.title = '建议',
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  label: Text(suggestion.query),
                  onPressed: () => onTap(suggestion.query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 搜索历史组件
class SearchHistoryList extends ConsumerWidget {
  final Function(String) onTap;
  final VoidCallback? onClear;

  const SearchHistoryList({
    super.key,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(smartSearchSuggestionServiceProvider).getSavedSearches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final searches = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '保存的搜索',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (onClear != null)
                    TextButton(
                      onPressed: onClear,
                      child: const Text('清除'),
                    ),
                ],
              ),
            ),
            ...searches.map((search) {
              return ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(search['name'] as String),
                subtitle: Text(search['query'] as String),
                trailing: Text('${search['use_count'] ?? 0} 次'),
                onTap: () => onTap(search['query'] as String),
              );
            }),
          ],
        );
      },
    );
  }
}