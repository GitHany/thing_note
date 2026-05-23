import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/tag_cloud/data/tag_cloud_repository.dart';
import 'package:thing_note/features/tag_cloud/domain/tag_cloud_entry.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final tagCloudProvider = Provider((ref) => ref.watch(tagCloudRepositoryProvider));

class TagCloudScreen extends ConsumerStatefulWidget {
  const TagCloudScreen({super.key});

  @override
  ConsumerState<TagCloudScreen> createState() => _TagCloudScreenState();
}

class _TagCloudScreenState extends ConsumerState<TagCloudScreen> {
  List<TagCloudEntry> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final repo = ref.read(tagCloudProvider);
    await repo.syncFromTags();
    _tags = await repo.getAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagCloud),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTags,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
           ? const Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.tag, size: 64, color: Colors.grey),
                       SizedBox(height: 16),
                       Text('还没有标签'),
                       SizedBox(height: 8),
                       Text('添加记录时使用标签，这里会显示标签云'),
                     ],
                   ),
                 )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTagCloud(),
                      const SizedBox(height: 24),
                      _buildTagList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTagCloud() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: _tags.take(30).map((tag) {
            return GestureDetector(
              onTap: () => _showTagDetails(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getTagColor(tag.usageCount).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTagColor(tag.usageCount),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag.tagName,
                  style: TextStyle(
                    fontSize: tag.fontSize,
                    fontWeight: tag.usageCount > 20 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标签统计', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTagColor(tag.usageCount).withOpacity(0.2),
                    child: Icon(Icons.tag, color: _getTagColor(tag.usageCount)),
                  ),
                  title: Text(tag.tagName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tag.usageCount}次',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTagColor(tag.usageCount),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showTagDetails(tag),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getTagColor(int usageCount) {
    if (usageCount >= 50) return Colors.red;
    if (usageCount >= 30) return Colors.orange;
    if (usageCount >= 15) return Colors.blue;
    if (usageCount >= 5) return Colors.green;
    return Colors.grey;
  }

  void _showTagDetails(TagCloudEntry tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tag, color: _getTagColor(tag.usageCount)),
            const SizedBox(width: 8),
            Text(tag.tagName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('使用次数', '${tag.usageCount}'),
            if (tag.lastUsed != null)
              _DetailRow('最近使用', tag.lastUsed!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}