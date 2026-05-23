import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/link_saver/data/link_saver_repository.dart';
import 'package:thing_note/features/link_saver/domain/saved_link.dart';

class LinkSaverScreen extends ConsumerStatefulWidget {
  const LinkSaverScreen({super.key});

  @override
  ConsumerState<LinkSaverScreen> createState() => _LinkSaverScreenState();
}

class _LinkSaverScreenState extends ConsumerState<LinkSaverScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(savedLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('链接收藏'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'unread', child: Text('未读')),
              const PopupMenuItem(value: 'reading', child: Text('阅读中')),
              const PopupMenuItem(value: 'done', child: Text('已完成')),
            ],
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
                hintText: '搜索链接...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: linksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (links) {
                final filteredLinks = _filterLinks(links);
                
                if (filteredLinks.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredLinks.length,
                  itemBuilder: (context, index) {
                    return _LinkCard(
                      link: filteredLinks[index],
                      onStatusChange: (status) => _updateStatus(filteredLinks[index].id!, status),
                      onDelete: () => _deleteLink(filteredLinks[index].id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLinkDialog(context),
        child: const Icon(Icons.add_link),
      ),
    );
  }

  List<SavedLink> _filterLinks(List<SavedLink> links) {
    var filtered = links;
    
    if (_filterStatus != 'all') {
      filtered = filtered.where((l) => l.status == _filterStatus).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((l) {
        return (l.title?.toLowerCase().contains(query) ?? false) ||
            (l.description?.toLowerCase().contains(query) ?? false) ||
            l.url.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? '未找到匹配的链接' : '暂无收藏链接',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddLinkDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加链接'),
          ),
        ],
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context) {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加链接'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '标题（可选）'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                final link = SavedLink(
                  url: urlController.text.trim(),
                  title: titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  createdAt: DateTime.now(),
                );
                ref.read(savedLinksProvider.notifier).addLink(link);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(int id, String status) {
    ref.read(savedLinksProvider.notifier).updateStatus(id, status);
  }

  void _deleteLink(int id) {
    ref.read(savedLinksProvider.notifier).deleteLink(id);
  }
}

class _LinkCard extends StatelessWidget {
  final SavedLink link;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _LinkCard({
    required this.link,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onStatusChange(link.status == 'unread' ? 'reading' : 'done'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(link.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getStatusIcon(link.status), color: _getStatusColor(link.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title ?? '无标题',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          link.url,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      } else {
                        onStatusChange(value);
                      }
                    },
                    itemBuilder: (context) => [
                      if (link.status != 'reading')
                        const PopupMenuItem(value: 'reading', child: Text('标记阅读中')),
                      if (link.status != 'done')
                        const PopupMenuItem(value: 'done', child: Text('标记已完成')),
                      if (link.status != 'unread')
                        const PopupMenuItem(value: 'unread', child: Text('标记未读')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              if (link.description != null && link.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(link.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(link.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(link.status),
                      style: TextStyle(fontSize: 12, color: _getStatusColor(link.status)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(link.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'reading': return Icons.auto_stories;
      case 'done': return Icons.check_circle;
      default: return Icons.link;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reading': return Colors.blue;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'reading': return '阅读中';
      case 'done': return '已完成';
      default: return '未读';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}