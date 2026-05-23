import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/folder_management/data/folder_repository.dart';
import 'package:thing_note/features/folder_management/domain/folder.dart';

class FolderManagementScreen extends ConsumerStatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  ConsumerState<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends ConsumerState<FolderManagementScreen> {
  List<FolderTreeNode> _folderTree = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final repo = ref.read(folderRepositoryProvider);
    _folderTree = await repo.getFolderTree();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件夹管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFolderDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folderTree.isEmpty
              ? _buildEmptyState()
              : _buildFolderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '暂无文件夹',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '创建文件夹来整理您的记录',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddFolderDialog(),
            icon: const Icon(Icons.add),
            label: const Text('创建文件夹'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _countNodes(_folderTree),
      itemBuilder: (context, index) {
        final node = _getNodeAtIndex(_folderTree, index);
        if (node == null) return const SizedBox.shrink();
        return _FolderTile(
          node: node,
          onTap: () => _openFolder(node.folder),
          onLongPress: () => _showFolderOptions(node.folder),
          onAddChild: () => _showAddSubfolderDialog(node.folder),
        );
      },
    );
  }

  int _countNodes(List<FolderTreeNode> nodes) {
    int count = 0;
    for (final node in nodes) {
      count++;
      count += _countNodes(node.children);
    }
    return count;
  }

  FolderTreeNode? _getNodeAtIndex(List<FolderTreeNode> nodes, int targetIndex) {
    int currentIndex = 0;
    for (final node in nodes) {
      if (currentIndex == targetIndex) return node;
      currentIndex++;
      if (currentIndex > targetIndex) return null;
      final childResult = _getNodeAtIndex(node.children, targetIndex - currentIndex);
      if (childResult != null) return childResult;
      currentIndex += _countNodes(node.children);
    }
    return null;
  }

  void _openFolder(Folder folder) {
    context.push('/folder/${folder.id}');
  }

  void _showFolderOptions(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('打开'),
            onTap: () {
              Navigator.pop(ctx);
              _openFolder(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('添加子文件夹'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddSubfolderDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('重命名'),
            onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('删除'),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await _confirmDelete(folder);
              if (confirmed) {
                final repo = ref.read(folderRepositoryProvider);
                await repo.deleteFolder(folder.id!);
                _loadFolders();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog({int? parentId}) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');
    final colorController = TextEditingController(text: '#607D8B');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentId == null ? '创建文件夹' : '添加子文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '文件夹名称'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: iconController,
                    decoration: const InputDecoration(labelText: '图标'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: '颜色'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final repo = ref.read(folderRepositoryProvider);
              final folder = Folder(
                name: nameController.text.trim(),
                icon: iconController.text.trim(),
                color: colorController.text.trim(),
                parentId: parentId,
                createdAt: DateTime.now(),
              );
              await repo.insertFolder(folder);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadFolders();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showAddSubfolderDialog(Folder parent) {
    _showAddFolderDialog(parentId: parent.id);
  }

  void _showRenameDialog(Folder folder) {
    final nameController = TextEditingController(text: folder.name);
    final iconController = TextEditingController(text: folder.icon ?? '📁');
    final colorController = TextEditingController(text: folder.color);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '文件夹名称'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: iconController,
                    decoration: const InputDecoration(labelText: '图标'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: '颜色'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final repo = ref.read(folderRepositoryProvider);
              final updated = folder.copyWith(
                name: nameController.text.trim(),
                icon: iconController.text.trim(),
                color: colorController.text.trim(),
              );
              await repo.updateFolder(updated);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadFolders();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(Folder folder) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除文件夹 "${folder.name}" 吗？\n\n子文件夹也会被删除，但记录不会被删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _FolderTile extends StatelessWidget {
  final FolderTreeNode node;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAddChild;

  const _FolderTile({
    required this.node,
    required this.onTap,
    required this.onLongPress,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(node.folder.color.replaceFirst('#', '0xFF')));
    final hasChildren = node.children.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.only(left: 16.0 * node.depth),
          child: Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    node.folder.icon ?? '📁',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              title: Text(
                node.folder.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${node.folder.recordCount} 条记录${hasChildren ? ' • ${node.children.length} 个子文件夹' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: onAddChild,
                    tooltip: '添加子文件夹',
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Folder detail screen showing records in folder
class FolderDetailScreen extends ConsumerStatefulWidget {
  final int folderId;

  const FolderDetailScreen({super.key, required this.folderId});

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  Folder? _folder;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(folderRepositoryProvider);
    final folders = await repo.getAllFolders();
    _folder = folders.firstWhere(
      (f) => f.id == widget.folderId,
      orElse: () => Folder(name: '未知', createdAt: DateTime.now()),
    );
    _records = await repo.getRecordsInFolder(widget.folderId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_folder?.name ?? '文件夹'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('文件夹为空'),
                      const SizedBox(height: 8),
                      Text(
                        '从记录列表中将记录添加到此处',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          record['note'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatDateTime(DateTime.parse(record['occurred_at'] as String)),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removeRecord(record['id'] as int),
                        ),
                        onTap: () => context.push('/record/${record['id']}'),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _removeRecord(int recordId) async {
    final repo = ref.read(folderRepositoryProvider);
    await repo.removeRecordFromFolder(widget.folderId, recordId);
    _loadData();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}