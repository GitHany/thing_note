import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchHistoryProvider = StateProvider<List<String>>((_) => [
  '工作记录', '学习笔记', '运动打卡'
]);

final smartSearchFiltersProvider = StateProvider<List<SearchFilter>>((_) => [
  SearchFilter(id: '1', name: '今天', icon: Icons.today),
  SearchFilter(id: '2', name: '本周', icon: Icons.date_range),
  SearchFilter(id: '3', name: '本月', icon: Icons.calendar_month),
  SearchFilter(id: '4', name: '有图片', icon: Icons.image),
  SearchFilter(id: '5', name: '有位置', icon: Icons.location_on),
]);

class SearchFilter {
  final String id;
  final String name;
  final IconData icon;

  SearchFilter({required this.id, required this.name, required this.icon});
}

class SmartSearchFiltersScreen extends ConsumerStatefulWidget {
  const SmartSearchFiltersScreen({super.key});

  @override
  ConsumerState<SmartSearchFiltersScreen> createState() => _SmartSearchFiltersScreenState();
}

class _SmartSearchFiltersScreenState extends ConsumerState<SmartSearchFiltersScreen> {
  final _searchController = TextEditingController();
  bool _fuzzySearch = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(smartSearchFiltersProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能搜索过滤器'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索记录...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('智能匹配'),
                const Spacer(),
                Switch(
                  value: _fuzzySearch,
                  onChanged: (v) => setState(() => _fuzzySearch = v),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('快速筛选', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAdvancedFilters(context),
                  child: const Text('高级筛选'),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((f) => FilterChip(
              avatar: Icon(f.icon, size: 16),
              label: Text(f.name),
              selected: false,
              onSelected: (_) {
                // Apply filter
              },
            )).toList(),
          ),
          const SizedBox(height: 16),
          if (history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('搜索历史', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(searchHistoryProvider.notifier).state = [],
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(history[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west),
                  onPressed: () {
                    _searchController.text = history[index];
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('高级筛选', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilterOption('日期范围', Icons.date_range),
            _buildFilterOption('标签筛选', Icons.label),
            _buildFilterOption('事情名称', Icons.category),
            _buildFilterOption('媒体类型', Icons.photo),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}