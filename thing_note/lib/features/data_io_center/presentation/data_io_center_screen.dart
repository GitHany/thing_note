import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/io_models.dart';

/// 数据导入导出中心屏幕
class DataIOCenterScreen extends ConsumerWidget {
  const DataIOCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importTasksAsync = ref.watch(dataIOProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('数据管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '导入'),
              Tab(text: '导出'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 导入标签页
            Column(
              children: [
                // 导入按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('导入 JSON'),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart),
                          label: const Text('导入 CSV'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // 导入历史
                Expanded(
                  child: importTasksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('加载失败: $e')),
                    data: (tasks) => tasks.isEmpty
                        ? const Center(child: Text('暂无导入记录'))
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return ListTile(
                                leading: Icon(_getSourceIcon(task.source)),
                                title: Text(task.fileName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(value: task.progress),
                                    Text('${task.importedRecords}/${task.totalRecords}'),
                                  ],
                                ),
                                trailing: _buildStatusBadge(task.status),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
            // 导出标签页
            Column(
              children: [
                // 导出按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.table_chart),
                          label: const Text('CSV'),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.code),
                          label: const Text('JSON'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // 导出历史
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final historyAsync = ref.watch(exportTasksProvider);
                      return historyAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const Center(child: Text('加载失败')),
                        data: (tasks) => tasks.isEmpty
                            ? const Center(child: Text('暂无导出记录'))
                            : ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return ListTile(
                                    leading: const Icon(Icons.file_download),
                                    title: Text('导出 ${task.format.name.toUpperCase()}'),
                                    subtitle: Text('${task.recordCount} 条记录'),
                                    trailing: task.filePath != null
                                        ? TextButton(
                                            onPressed: () {},
                                            child: const Text('下载'),
                                          )
                                        : null,
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSourceIcon(ImportSource source) {
    switch (source) {
      case ImportSource.json: return Icons.data_object;
      case ImportSource.csv: return Icons.table_chart;
      case ImportSource.txt: return Icons.text_snippet;
      case ImportSource.excel: return Icons.grid_on;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = '完成';
        break;
      case 'processing':
        color = Colors.orange;
        label = '处理中';
        break;
      case 'failed':
        color = Colors.red;
        label = '失败';
        break;
      default:
        color = Colors.grey;
        label = '等待';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}