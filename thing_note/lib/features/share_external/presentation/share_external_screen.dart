import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/share_external/domain/share_service.dart';

class ShareExternalScreen extends ConsumerStatefulWidget {
  final int? recordId;

  const ShareExternalScreen({super.key, this.recordId});

  @override
  ConsumerState<ShareExternalScreen> createState() => _ShareExternalScreenState();
}

class _ShareExternalScreenState extends ConsumerState<ShareExternalScreen> {
  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(shareDestinationsProvider);
    final shareService = ref.read(shareServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享到外部'),
      ),
      body: destinationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (destinations) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quick share options
              const Text(
                '快速分享',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.email,
                      label: '邮件',
                      color: Colors.red,
                      onPressed: () => _share(shareService.shareToEmail('记录分享', '内容')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShareButton(
                      icon: Icons.share,
                      label: '系统分享',
                      color: Colors.blue,
                      onPressed: () => _systemShare(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Saved destinations
              const Text(
                '已保存的分享目标',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (destinations.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('还没有保存任何分享目标'),
                      ],
                    ),
                  ),
                )
              else
                ...destinations.map((dest) => _DestinationCard(destination: dest)),
              const SizedBox(height: 24),
              // Add new destination
              OutlinedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('添加分享目标'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _share(Future<ShareRecordResult> future) async {
    final result = await future;
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? '分享成功'),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  void _systemShare() {
    // TODO: Implement system share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('系统分享功能开发中')),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _AddDestinationSheet(),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final ShareDestination destination;

  const _DestinationCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getTypeIcon(destination.type),
          color: _getTypeColor(destination.type),
        ),
        title: Text(destination.name),
        subtitle: Text(_getTypeLabel(destination.type)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: destination.isEnabled,
              onChanged: (v) {
                // TODO: Toggle enabled
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // TODO: Delete
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'email': return Icons.email;
      case 'twitter': return Icons.alternate_email;
      case 'facebook': return Icons.facebook;
      case 'weibo': return Icons.cloud;
      case 'notion': return Icons.description;
      case 'api': return Icons.api;
      default: return Icons.share;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'email': return Colors.red;
      case 'twitter': return Colors.blue;
      case 'facebook': return Colors.indigo;
      case 'weibo': return Colors.orange;
      case 'notion': return Colors.black;
      case 'api': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'email': return '邮件';
      case 'twitter': return 'Twitter';
      case 'facebook': return 'Facebook';
      case 'weibo': return '微博';
      case 'notion': return 'Notion';
      case 'api': return 'API';
      default: return type;
    }
  }
}

class _AddDestinationSheet extends StatefulWidget {
  const _AddDestinationSheet();

  @override
  State<_AddDestinationSheet> createState() => _AddDestinationSheetState();
}

class _AddDestinationSheetState extends State<_AddDestinationSheet> {
  final _nameController = TextEditingController();
  final _configController = TextEditingController();
  String _selectedType = 'email';

  final List<Map<String, dynamic>> _types = [
    {'value': 'email', 'label': '邮件', 'icon': Icons.email},
    {'value': 'twitter', 'label': 'Twitter', 'icon': Icons.alternate_email},
    {'value': 'facebook', 'label': 'Facebook', 'icon': Icons.facebook},
    {'value': 'weibo', 'label': '微博', 'icon': Icons.cloud},
    {'value': 'notion', 'label': 'Notion', 'icon': Icons.description},
    {'value': 'api', 'label': 'API', 'icon': Icons.api},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '添加分享目标',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '类型',
                border: OutlineInputBorder(),
              ),
              items: _types.map((t) => DropdownMenuItem(
                value: t['value'] as String,
                child: Row(
                  children: [
                    Icon(t['icon'] as IconData),
                    const SizedBox(width: 8),
                    Text(t['label'] as String),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _configController,
              decoration: const InputDecoration(
                labelText: '配置 (可选)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _configController.dispose();
    super.dispose();
  }
}