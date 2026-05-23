import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';

// Smart Search Suggestions Provider
final smartSearchSuggestionsProvider = FutureProvider<List<SearchSuggestion>>((ref) async {
  // Simulated suggestions based on search history and patterns
  return [
    SearchSuggestion(
      type: SuggestionType.recent,
      title: '今天的工作记录',
      subtitle: '最近搜索',
      icon: Icons.history,
    ),
    SearchSuggestion(
      type: SuggestionType.trending,
      title: '#工作 #学习',
      subtitle: '热门组合',
      icon: Icons.trending_up,
    ),
    SearchSuggestion(
      type: SuggestionType.semantic,
      title: '项目进度',
      subtitle: '智能推荐',
      icon: Icons.lightbulb,
    ),
    SearchSuggestion(
      type: SuggestionType.location,
      title: '公司附近的记录',
      subtitle: '位置相关',
      icon: Icons.location_on,
    ),
    SearchSuggestion(
      type: SuggestionType.time,
      title: '过去一周',
      subtitle: '时间范围',
      icon: Icons.calendar_today,
    ),
  ];
});

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super(['工作', '学习', '项目', '会议']);

  void addSearch(String query) {
    if (query.isNotEmpty) {
      state = [query, ...state.where((q) => q != query).take(10)];
    }
  }

  void removeSearch(String query) {
    state = state.where((q) => q != query).toList();
  }

  void clearHistory() {
    state = [];
  }
}

enum SuggestionType { recent, trending, semantic, location, time }

class SearchSuggestion {
  final SuggestionType type;
  final String title;
  final String subtitle;
  final IconData icon;

  SearchSuggestion({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class SmartSearchSuggestionScreen extends ConsumerStatefulWidget {
  const SmartSearchSuggestionScreen({super.key});

  @override
  ConsumerState<SmartSearchSuggestionScreen> createState() => _SmartSearchSuggestionScreenState();
}

class _SmartSearchSuggestionScreenState extends ConsumerState<SmartSearchSuggestionScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<SearchSuggestion> _suggestions = [];
  List<String> _searchHistory = [];
  List<String> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _searchHistory = ref.read(searchHistoryProvider);
    _filteredHistory = _searchHistory;
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestionsAsync = await ref.read(smartSearchSuggestionsProvider.future);
      setState(() {
        _suggestions = suggestionsAsync;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _filterHistory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHistory = _searchHistory;
      } else {
        _filteredHistory = _searchHistory
            .where((h) => h.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能搜索建议'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _filterHistory('');
                setState(() {});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSuggestionsView()
                : _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '输入搜索内容...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () => _showVoiceSearch(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _showImageSearch(context),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
            ),
            onChanged: (value) {
              _filterHistory(value);
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ref.read(searchHistoryProvider.notifier).addSearch(value);
                _searchHistory = ref.read(searchHistoryProvider);
                _filterHistory(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSearchFilters(),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('综合', true),
          _buildFilterChip('记录', false),
          _buildFilterChip('标签', false),
          _buildFilterChip('时间', false),
          _buildFilterChip('位置', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Toggle filter
        },
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_filteredHistory.isNotEmpty) ...[
            _buildSectionHeader('搜索历史', action: TextButton(
              onPressed: () {
                ref.read(searchHistoryProvider.notifier).clearHistory();
                setState(() {
                  _searchHistory = [];
                  _filteredHistory = [];
                });
              },
              child: const Text('清除'),
            )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredHistory.map((history) {
                return _buildHistoryChip(history);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (_suggestions.isNotEmpty) ...[
            _buildSectionHeader('智能推荐'),
            const SizedBox(height: 8),
            _buildSuggestionsList(),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader('搜索技巧'),
          const SizedBox(height: 8),
          _buildSearchTips(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildHistoryChip(String history) {
    return InkWell(
      onTap: () {
        _searchController.text = history;
        _filterHistory(history);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        avatar: const Icon(Icons.history, size: 16),
        label: Text(history),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          ref.read(searchHistoryProvider.notifier).removeSearch(history);
          setState(() {
            _searchHistory = ref.read(searchHistoryProvider);
            _filterHistory(_searchController.text);
          });
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      children: _suggestions.map((suggestion) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSuggestionColor(suggestion.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                suggestion.icon,
                color: _getSuggestionColor(suggestion.type),
              ),
            ),
            title: Text(suggestion.title),
            subtitle: Text(suggestion.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _searchController.text = suggestion.title;
              setState(() {});
              // Execute search
            },
          ),
        );
      }).toList(),
    );
  }

  Color _getSuggestionColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.recent:
        return Colors.blue;
      case SuggestionType.trending:
        return Colors.orange;
      case SuggestionType.semantic:
        return Colors.purple;
      case SuggestionType.location:
        return Colors.green;
      case SuggestionType.time:
        return Colors.red;
    }
  }

  Widget _buildSearchTips() {
    final tips = [
      {'icon': Icons.tag, 'text': '使用 #标签 搜索特定标签'},
      {'icon': Icons.calendar_today, 'text': '使用 时间:今天 搜索日期'},
      {'icon': Icons.location_on, 'text': '使用 位置:公司 搜索位置'},
      {'icon': Icons.photo, 'text': '包含[图片] 搜索带图片的记录'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    tip['icon'] as IconData,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip['text'] as String)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final recordsAsync = ref.watch(recordListProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('加载失败: $err')),
      data: (records) {
        final query = _searchController.text.toLowerCase();
        final filtered = records.where((r) {
          return r.note.toLowerCase().contains(query) ||
              (r.address?.toLowerCase().contains(query) ?? false);
        }).toList();

        if (filtered.isEmpty) {
          return _buildNoResults();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final record = filtered[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  record.note.isNotEmpty ? record.note : '无内容记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${record.occurredAt.year}-${record.occurredAt.month}-${record.occurredAt.day}',
                ),
                trailing: record.isFavorite
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
                onTap: () => context.push('/record/${record.id}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults() {
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
            '没有找到相关结果',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  void _showVoiceSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('语音搜索'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('正在聆听...'),
            const SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showImageSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照识别'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera OCR
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image picker
              },
            ),
          ],
        ),
      ),
    );
  }
}
