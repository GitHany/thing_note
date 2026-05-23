import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BatchTagV2Screen extends ConsumerStatefulWidget {
  const BatchTagV2Screen({super.key});

  @override
  ConsumerState<BatchTagV2Screen> createState() => _BatchTagV2ScreenState();
}

class _BatchTagV2ScreenState extends ConsumerState<BatchTagV2Screen> {
  final Set<int> _selectedRecords = {};
  String _selectedAction = 'add';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量标签管理 V2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedRecords.isNotEmpty)
            TextButton(
              onPressed: () => _executeBatchOperation(),
              child: Text('执行 (${_selectedRecords.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildActionSelector(),
          Expanded(
            child: _buildRecordList(),
          ),
          if (_selectedRecords.isNotEmpty) _buildSelectedSummary(),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    final actions = [
      {'action': 'add', 'icon': Icons.add, 'label': '添加标签'},
      {'action': 'remove', 'icon': Icons.remove, 'label': '移除标签'},
      {'action': 'replace', 'icon': Icons.swap_horiz, 'label': '替换标签'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((a) {
          final isSelected = _selectedAction == a['action'];
          return ChoiceChip(
            label: Text(a['label'] as String),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedAction = a['action'] as String;
              });
            },
            avatar: Icon(
              a['icon'] as IconData,
              size: 18,
              color: isSelected ? Colors.white : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordList() {
    final records = _getSampleRecords();
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isSelected = _selectedRecords.contains(record['id']);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedRecords.add(record['id'] as int);
                  } else {
                    _selectedRecords.remove(record['id']);
                  }
                });
              },
            ),
            title: Text(record['title'] as String),
            subtitle: Row(
              children: (record['tags'] as List<String>).map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
            trailing: Text(
              record['date'] as String,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedRecords.remove(record['id']);
                } else {
                  _selectedRecords.add(record['id'] as int);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selectedRecords.length} 条记录',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRecords.clear();
              });
            },
            child: const Text('清除'),
          ),
          ElevatedButton(
            onPressed: () => _showTagSelector(context),
            child: Text(_getActionButtonText()),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSampleRecords() {
    return [
      {'id': 1, 'title': '晨跑记录', 'tags': ['运动', '健康'], 'date': '05-21'},
      {'id': 2, 'title': '团队会议', 'tags': ['工作'], 'date': '05-21'},
      {'id': 3, 'title': '学习Flutter', 'tags': ['学习', '编程'], 'date': '05-20'},
      {'id': 4, 'title': '晚餐约会', 'tags': ['社交', '美食'], 'date': '05-20'},
      {'id': 5, 'title': '电影之夜', 'tags': ['娱乐'], 'date': '05-19'},
    ];
  }

  String _getActionButtonText() {
    switch (_selectedAction) {
      case 'add':
        return '添加标签';
      case 'remove':
        return '移除标签';
      case 'replace':
        return '替换标签';
      default:
        return '确定';
    }
  }

  void _showTagSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTagSelectorTitle(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTagChip('工作'),
                _buildTagChip('学习'),
                _buildTagChip('运动'),
                _buildTagChip('健康'),
                _buildTagChip('娱乐'),
                _buildTagChip('社交'),
                _buildTagChip('旅行'),
                _buildTagChip('美食'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _executeBatchOperation();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return FilterChip(
      label: Text(tag),
      selected: false,
      onSelected: (selected) {},
    );
  }

  String _getTagSelectorTitle() {
    switch (_selectedAction) {
      case 'add':
        return '选择要添加的标签';
      case 'remove':
        return '选择要移除的标签';
      case 'replace':
        return '选择新标签替换旧标签';
      default:
        return '选择标签';
    }
  }

  void _executeBatchOperation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_getActionButtonText()}成功，影响 ${_selectedRecords.length} 条记录',
        ),
      ),
    );
    setState(() {
      _selectedRecords.clear();
    });
  }
}