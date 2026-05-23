import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:intl/intl.dart';

// Cross-Record Linking State
final linkedRecordsProvider = FutureProvider.family<List<RecordLink>, int>((ref, recordId) async {
  // Simulated linked records
  return [];
});

class RecordLink {
  final int id;
  final int recordIdA;
  final int recordIdB;
  final String? linkType;
  final String? note;
  final DateTime createdAt;

  RecordLink({
    required this.id,
    required this.recordIdA,
    required this.recordIdB,
    this.linkType,
    this.note,
    required this.createdAt,
  });
}

// Link Types
enum LinkType {
  related('相关', Icons.link),
  parent('主记录', Icons.subdirectory_arrow_right),
  child('子记录', Icons.arrow_forward),
  reference('参考', Icons.bookmark),
  sequence('序列', Icons.format_list_numbered),
  duplicate('重复', Icons.content_copy);

  final String label;
  final IconData icon;

  const LinkType(this.label, this.icon);
}

class CrossRecordLinkingScreen extends ConsumerStatefulWidget {
  const CrossRecordLinkingScreen({super.key});

  @override
  ConsumerState<CrossRecordLinkingScreen> createState() => _CrossRecordLinkingScreenState();
}

class _CrossRecordLinkingScreenState extends ConsumerState<CrossRecordLinkingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedRecordId;
  LinkType _selectedLinkType = LinkType.related;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录关联'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '关联记录'),
            Tab(text: '创建关联'),
            Tab(text: '关联图谱'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLinkedRecordsTab(),
          _buildCreateLinkTab(),
          _buildLinkGraphTab(),
        ],
      ),
    );
  }

  Widget _buildLinkedRecordsTab() {
    final recordsAsync = ref.watch(recordListProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('加载失败: $err')),
      data: (records) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordCard(record);
          },
        );
      },
    );
  }

  Widget _buildRecordCard(EpisodeRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRecordId = record.id;
          });
          _showLinkOptions(context, record);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getRecordIcon(record),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.note.isNotEmpty ? record.note : '无内容记录',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(record.occurredAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.link, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateLinkTab() {
    final recordsAsync = ref.watch(recordListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择关联类型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LinkType.values.map((type) {
                      final isSelected = _selectedLinkType == type;
                      return ChoiceChip(
                        avatar: Icon(type.icon, size: 18),
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedLinkType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择要关联的记录',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  recordsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (err, _) => Text('加载失败: $err'),
                    data: (records) {
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return CheckboxListTile(
                              value: _selectedRecordId == record.id,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRecordId = value == true ? record.id : null;
                                });
                              },
                              title: Text(
                                record.note.isNotEmpty ? record.note : '无内容',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat('MM-dd HH:mm').format(record.occurredAt),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关联说明（可选）',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: '添加关联说明...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRecordId != null ? _createLink : null,
              child: const Text('创建关联'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkGraphTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '关联图谱',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '可视化展示记录之间的关联关系',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement link graph visualization
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('生成图谱'),
          ),
        ],
      ),
    );
  }

  IconData _getRecordIcon(EpisodeRecord record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }

  void _showLinkOptions(BuildContext context, EpisodeRecord record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择关联方式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...LinkType.values.map((type) {
              return ListTile(
                leading: Icon(type.icon),
                title: Text(type.label),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedLinkType = type;
                    _selectedRecordId = record.id;
                  });
                  _tabController.animateTo(1);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _createLink() {
    if (_selectedRecordId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已创建${_selectedLinkType.label}关联')),
    );

    ref.read(recordNotifierProvider.notifier).createLink(
      _selectedRecordId!,
      _selectedRecordId!,
    );

    setState(() {
      _selectedRecordId = null;
      _noteController.clear();
      _selectedLinkType = LinkType.related;
    });
  }
}
