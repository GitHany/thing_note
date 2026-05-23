import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smartSearchEnhanceProvider = StateNotifierProvider<SmartSearchEnhanceNotifier, List<Map<String, dynamic>>>((ref) {
  return SmartSearchEnhanceNotifier();
});

class SmartSearchEnhanceNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  SmartSearchEnhanceNotifier() : super([
    {'id': 1, 'query': '上周的运动记录', 'results': 5},
    {'id': 2, 'query': '关于工作的记录', 'results': 12},
    {'id': 3, 'query': '带照片的记录', 'results': 8},
  ]);

  void addSavedSearch(Map<String, dynamic> search) {}
  void deleteSearch(int id) {}
}

class SmartSearchEnhanceScreen extends ConsumerStatefulWidget {
  const SmartSearchEnhanceScreen({super.key});

  @override
  ConsumerState<SmartSearchEnhanceScreen> createState() => _SmartSearchEnhanceScreenState();
}

class _SmartSearchEnhanceScreenState extends ConsumerState<SmartSearchEnhanceScreen> {
  final _searchController = TextEditingController();
  String _searchMode = 'semantic';

  @override
  Widget build(BuildContext context) {
    final savedSearches = ref.watch(smartSearchEnhanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能搜索增强'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSearchModes(),
          Expanded(
            child: _buildResults(savedSearches),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '输入自然语言搜索...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {},
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (value) => _performSearch(value),
      ),
    );
  }

  Widget _buildSearchModes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SearchModeChip(
            label: '语义搜索',
            icon: Icons.auto_fix_high,
            isSelected: _searchMode == 'semantic',
            onTap: () => setState(() => _searchMode = 'semantic'),
          ),
          const SizedBox(width: 8),
          _SearchModeChip(
            label: '精确搜索',
            icon: Icons.search,
            isSelected: _searchMode == 'exact',
            onTap: () => setState(() => _searchMode = 'exact'),
          ),
          const SizedBox(width: 8),
          _SearchModeChip(
            label: '模糊搜索',
            icon: Icons.blur_on,
            isSelected: _searchMode == 'fuzzy',
            onTap: () => setState(() => _searchMode = 'fuzzy'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Map<String, dynamic>> savedSearches) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('保存的搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (savedSearches.isEmpty)
          const Text('暂无保存的搜索', style: TextStyle(color: Colors.grey))
        else
          ...savedSearches.map((s) => _SavedSearchCard(
            search: s,
            onTap: () => _searchController.text = s['query'] as String,
            onDelete: () => ref.read(smartSearchEnhanceProvider.notifier).deleteSearch(s['id'] as int),
          )),
        const SizedBox(height: 24),
        const Text('💡 搜索提示', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const _SearchTip(
          icon: Icons.schedule,
          tip: '"上周" - 搜索7天前的记录',
        ),
        const _SearchTip(
          icon: Icons.photo,
          tip: '"带照片" - 只显示有照片的记录',
        ),
        const _SearchTip(
          icon: Icons.location_on,
          tip: '"在公司" - 搜索特定地点的记录',
        ),
      ],
    );
  }

  void _performSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('搜索: $query')),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('搜索历史', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('上周的运动'),
              trailing: Icon(Icons.north_west),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('工作的记录'),
              trailing: Icon(Icons.north_west),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('带照片的记录'),
              trailing: Icon(Icons.north_west),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SearchModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.blue) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  final Map<String, dynamic> search;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedSearchCard({
    required this.search,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark),
        title: Text(search['query'] as String),
        subtitle: Text('${search['results']} 个结果'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SearchTip extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _SearchTip({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(tip, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}