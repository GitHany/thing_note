import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_search/data/quick_search_repository.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final quickSearchProvider = Provider((ref) => ref.watch(quickSearchRepositoryProvider));

class QuickSearchScreen extends ConsumerStatefulWidget {
  const QuickSearchScreen({super.key});

  @override
  ConsumerState<QuickSearchScreen> createState() => _QuickSearchScreenState();
}

class _QuickSearchScreenState extends ConsumerState<QuickSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final repo = ref.read(quickSearchProvider);
    final searches = await repo.getRecentSearches(10);
    setState(() => _recentSearches = searches.map((e) => e.query).toList());
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(quickSearchProvider);
    final results = await repo.searchRecords(query);
    await repo.saveSearch(query, results.length);
    setState(() {
      _results = results;
      _isSearching = false;
      _showResults = true;
    });
    _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickSearch),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showSearchHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索记录、标签、地点...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _showResults = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _search,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_showResults)
            Expanded(child: _buildResults())
          else
            Expanded(child: _buildRecentSearches()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('没有找到 "${_searchController.text}" 相关结果'),
          ],
        ),
      );
    }

    // Group results by type
    final records = _results.where((r) => r['type'] == 'record').toList();
    final things = _results.where((r) => r['type'] == 'thing').toList();
    final tags = _results.where((r) => r['type'] == 'tag').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (records.isNotEmpty) ...[
          _buildResultSection('记录', Icons.note, records),
          const SizedBox(height: 16),
        ],
        if (things.isNotEmpty) ...[
          _buildResultSection('事情名称', Icons.label, things),
          const SizedBox(height: 16),
        ],
        if (tags.isNotEmpty) ...[
          _buildResultSection('标签', Icons.tag, tags),
        ],
      ],
    );
  }

  Widget _buildResultSection(String title, IconData icon, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Text('(${items.length})', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ...items.take(10).map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['title']?.toString() ?? ''),
                  subtitle: Text(item['date']?.toString() ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('输入关键词开始搜索'),
          SizedBox(height: 8),
          Text('可以搜索记录、标签、地点等'),
        ],
      ),
    );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('最近搜索', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._recentSearches.map((query) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              trailing: IconButton(
                icon: const Icon(Icons.north_west),
                onPressed: () {
                  _searchController.text = query;
                  _search(query);
                },
              ),
              onTap: () {
                _searchController.text = query;
                _search(query);
              },
            )),
      ],
    );
  }

  void _showSearchHistory() async {
    final repo = ref.read(quickSearchProvider);
    final searches = await repo.getRecentSearches(20);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('搜索历史', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () async {
                    await repo.clearHistory();
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadRecentSearches();
                  },
                  child: const Text('清除全部'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searches.length,
                itemBuilder: (context, index) {
                  final search = searches[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(search.query),
                    subtitle: Text('${search.resultCount}个结果'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await repo.deleteSearch(search.id!);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadRecentSearches();
                      },
                    ),
                    onTap: () {
                      _searchController.text = search.query;
                      Navigator.pop(ctx);
                      _search(search.query);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}