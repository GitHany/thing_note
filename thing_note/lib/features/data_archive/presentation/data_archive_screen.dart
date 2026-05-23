import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final archiveDataProvider = StateNotifierProvider<ArchiveDataNotifier, List<Map<String, dynamic>>>((ref) {
  return ArchiveDataNotifier();
});

class ArchiveDataNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ArchiveDataNotifier() : super(_defaultArchives);

  static final List<Map<String, dynamic>> _defaultArchives = [
    {'name': '旧记录', 'count': 120, 'size': '2.5MB', 'date': '2025-01-01'},
    {'name': '测试数据', 'count': 45, 'size': '800KB', 'date': '2025-03-15'},
  ];

  void archiveData(String tableName, int recordCount) {
    state = [
      ...state,
      {'name': tableName, 'count': recordCount, 'size': '${(recordCount * 0.02).toStringAsFixed(1)}MB', 'date': DateTime.now().toIso8601String().substring(0, 10)},
    ];
  }

  void restoreData(int index) {
    // Restore logic would go here
  }

  void deleteArchive(int index) {
    state = [...state]..removeAt(index);
  }
}

class DataArchiveScreen extends ConsumerWidget {
  const DataArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archives = ref.watch(archiveDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据归档'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showArchiveRulesDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStorageOverview(),
          Expanded(
            child: archives.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: archives.length,
                    itemBuilder: (context, index) {
                      final archive = archives[index];
                      return _ArchiveCard(
                        archive: archive,
                        onRestore: () => ref.read(archiveDataProvider.notifier).restoreData(index),
                        onDelete: () => ref.read(archiveDataProvider.notifier).deleteArchive(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStorageItem('总占用', '15.2MB', Icons.storage),
          _buildStorageItem('已归档', '3.3MB', Icons.archive),
          _buildStorageItem('可释放', '1.2MB', Icons.cleaning_services),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无归档数据', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('归档旧数据可以释放存储空间', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.archive),
            label: const Text('创建归档'),
          ),
        ],
      ),
    );
  }

  void _showArchiveRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档规则设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('自动归档30天前的记录'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('归档删除的项目'),
              value: false,
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            const Text('归档后数据可在30天内恢复', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final Map<String, dynamic> archive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ArchiveCard({
    required this.archive,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.archive, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archive['name'] ?? '归档',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${archive['count']} 条记录 • ${archive['size']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              child: const Text('恢复'),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}