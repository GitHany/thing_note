import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/advanced_search/data/advanced_search_repository.dart';
import 'package:thing_note/features/advanced_search/domain/search_filters.dart';

final searchFiltersProvider = StateProvider<SearchFilters>((ref) => SearchFilters());

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  SearchFilters _filters = SearchFilters();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _showFilters = false;
  List<SearchHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(advancedSearchRepositoryProvider);
    _history = await repo.getSearchHistory();
    setState(() {});
  }

  Future<void> _performSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty && !_filters.hasFilters) return;

    setState(() => _isLoading = true);

    final repo = ref.read(advancedSearchRepositoryProvider);
    _results = await repo.searchRecords(_filters, query: query);

    // Save to history
    if (query.isNotEmpty) {
      await repo.saveSearchHistory(SearchHistoryEntry(
        query: query,
        resultCount: _results.length,
        searchedAt: DateTime.now(),
      ));
      _loadHistory();
    }

    setState(() => _isLoading = false);
  }

  void _clearFilters() {
    setState(() {
      _filters = SearchFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级搜索'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: '筛选器',
          ),
          if (_filters.hasFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: '清除筛选',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFiltersPanel(),
          if (_history.isNotEmpty && _results.isEmpty) _buildHistoryList(),
          if (_results.isNotEmpty) _buildResultsList(),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: '搜索记录...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _queryController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _performSearch,
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '筛选条件',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDateFilter(),
            const SizedBox(height: 16),
            _buildMediaFilter(),
            const SizedBox(height: 16),
            _buildQuickFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('日期范围'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_filters.startDate != null
                    ? _formatDate(_filters.startDate!)
                    : '开始日期'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_filters.endDate != null
                    ? _formatDate(_filters.endDate!)
                    : '结束日期'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('媒体类型'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('有照片'),
              selected: _filters.hasPhoto == true,
              onSelected: (s) => setState(() {
                _filters = _filters.copyWith(hasPhoto: s ? true : null);
              }),
            ),
            FilterChip(
              label: const Text('有音频'),
              selected: _filters.hasAudio == true,
              onSelected: (s) => setState(() {
                _filters = _filters.copyWith(hasAudio: s ? true : null);
              }),
            ),
            FilterChip(
              label: const Text('有视频'),
              selected: _filters.hasVideo == true,
              onSelected: (s) => setState(() {
                _filters = _filters.copyWith(hasVideo: s ? true : null);
              }),
            ),
            FilterChip(
              label: const Text('有位置'),
              selected: _filters.hasLocation == true,
              onSelected: (s) => setState(() {
                _filters = _filters.copyWith(hasLocation: s ? true : null);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('快捷筛选'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.star, size: 16),
              label: const Text('收藏'),
              backgroundColor: _filters.isFavorite == true ? Colors.amber.withOpacity(0.3) : null,
              onPressed: () => setState(() {
                _filters = _filters.copyWith(isFavorite: _filters.isFavorite == true ? null : true);
              }),
            ),
            ActionChip(
              avatar: const Icon(Icons.timer, size: 16),
              label: const Text('30分钟内'),
              onPressed: () => setState(() {
                _filters = _filters.copyWith(maxDuration: 30);
              }),
            ),
            ActionChip(
              avatar: const Icon(Icons.today, size: 16),
              label: const Text('今天'),
              onPressed: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                setState(() {
                  _filters = _filters.copyWith(startDate: today, endDate: now);
                });
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.weekend, size: 16),
              label: const Text('本周'),
              onPressed: () {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                setState(() {
                  _filters = _filters.copyWith(
                    startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
                    endDate: now,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Expanded(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(advancedSearchRepositoryProvider);
                    await repo.clearSearchHistory();
                    _loadHistory();
                  },
                  child: const Text('清除历史'),
                ),
              ],
            ),
          ),
          ...List.generate(_history.length, (index) {
            final entry = _history[index];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry.query),
              subtitle: Text('${entry.resultCount} 条结果'),
              trailing: Text(
                _formatTimeAgo(entry.searchedAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () {
                _queryController.text = entry.query;
                _performSearch();
              },
              onLongPress: () async {
                final repo = ref.read(advancedSearchRepositoryProvider);
                await repo.deleteSearchHistoryEntry(entry.id!);
                _loadHistory();
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '找到 ${_results.length} 条记录',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final record = _results[index];
                return _SearchResultCard(
                  record: record,
                  onTap: () => context.push('/record/${record['id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _filters.startDate : _filters.endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _filters = _filters.copyWith(startDate: picked);
        } else {
          _filters = _filters.copyWith(endDate: picked);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final occurredAt = DateTime.parse(record['occurred_at'] as String);
    final hasPhoto = (record['photo_paths'] as String?)?.isNotEmpty == true &&
        record['photo_paths'] != '[]';
    final hasAudio = (record['audio_paths'] as String?)?.isNotEmpty == true &&
        record['audio_paths'] != '[]';
    final hasVideo = (record['video_paths'] as String?)?.isNotEmpty == true &&
        record['video_paths'] != '[]';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          record['note'] as String? ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              _formatDateTime(occurredAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            if (record['thing_name'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record['thing_name'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            const Spacer(),
            if (hasPhoto) const Icon(Icons.photo, size: 16, color: Colors.grey),
            if (hasAudio) const Icon(Icons.mic, size: 16, color: Colors.grey),
            if (hasVideo) const Icon(Icons.videocam, size: 16, color: Colors.grey),
          ],
        ),
        trailing: record['is_favorite'] == 1
            ? const Icon(Icons.star, color: Colors.amber, size: 20)
            : null,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}