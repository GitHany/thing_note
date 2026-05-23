import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_version_history/data/record_version_repository.dart';
import 'package:thing_note/features/record_version_history/domain/record_version.dart';

final recordVersionsProvider = FutureProvider.family<List<RecordVersion>, int>((ref, recordId) async {
  final repository = ref.watch(recordVersionRepositoryProvider);
  return repository.getVersionsForRecord(recordId);
});

class RecordVersionHistoryScreen extends ConsumerWidget {
  final int recordId;

  const RecordVersionHistoryScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(recordVersionsProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('版本历史'),
      ),
      body: versionsAsync.when(
        data: (versions) {
          if (versions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text('暂无版本记录'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: versions.length,
            itemBuilder: (context, index) => _buildVersionCard(context, ref, versions[index], versions.length - index),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, WidgetRef ref, RecordVersion version, int displayNumber) {
    final isLatest = displayNumber == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showVersionDetail(context, ref, version),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '版本 $displayNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLatest
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLatest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity( 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('当前', style: TextStyle(fontSize: 12, color: Colors.green)),
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(version.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (version.changeSummary != null) ...[
                const SizedBox(height: 12),
                Text(
                  version.changeSummary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isLatest)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _restoreVersion(context, ref, version),
                        child: const Text('恢复此版本'),
                      ),
                    ),
                  if (!isLatest) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _compareVersions(context, version),
                      child: const Text('对比'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showVersionDetail(BuildContext context, WidgetRef ref, RecordVersion version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本 ${version.versionNumber}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('创建于: ${_formatDate(version.createdAt)}'),
            const SizedBox(height: 16),
            if (version.changeSummary != null) ...[
              const Text('变更说明:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(version.changeSummary!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _restoreVersion(context, ref, version);
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('恢复'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreVersion(BuildContext context, WidgetRef ref, RecordVersion version) async {
    final repository = ref.read(recordVersionRepositoryProvider);
    await repository.restoreVersion(version.recordId, version.versionNumber);
    ref.invalidate(recordVersionsProvider(recordId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('版本已恢复')),
      );
    }
  }

  void _compareVersions(BuildContext context, RecordVersion version) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('对比功能开发中')),
    );
  }
}