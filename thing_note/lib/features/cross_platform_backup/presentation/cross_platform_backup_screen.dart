import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/cross_platform_backup/data/cross_platform_backup_repository.dart';
import 'package:thing_note/features/cross_platform_backup/domain/backup_models.dart';

class CrossPlatformBackupScreen extends ConsumerStatefulWidget {
  const CrossPlatformBackupScreen({super.key});

  @override
  ConsumerState<CrossPlatformBackupScreen> createState() => _CrossPlatformBackupScreenState();
}

class _CrossPlatformBackupScreenState extends ConsumerState<CrossPlatformBackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BackupEntry> _backups = [];
  bool _isLoading = true;
  bool _isBackingUp = false;
  int _totalBackupSize = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(crossPlatformBackupRepositoryProvider);
    _backups = await repo.getAllBackups();
    _totalBackupSize = await repo.getTotalBackupSize();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跨平台备份'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '本地备份', icon: Icon(Icons.folder)),
            Tab(text: '云端备份', icon: Icon(Icons.cloud)),
            Tab(text: '设置', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalBackupTab(),
          _buildCloudBackupTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBackingUp ? null : _createBackup,
        icon: _isBackingUp
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.backup),
        label: Text(_isBackingUp ? '备份中...' : '新建备份'),
      ),
    );
  }

  Widget _buildLocalBackupTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStorageSummary(),
              Expanded(
                child: _backups.isEmpty
                    ? _buildEmptyState()
                    : _buildBackupList(),
              ),
            ],
          );
  }

  Widget _buildStorageSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StorageStat(
                icon: Icons.folder,
                value: '${_backups.length}',
                label: '备份数量',
                color: Colors.blue,
              ),
              _StorageStat(
                icon: Icons.storage,
                value: _formatBytes(_totalBackupSize),
                label: '总大小',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.backup_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无备份'),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建第一个备份',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return _BackupCard(
          backup: backup,
          onRestore: () => _restoreBackup(backup),
          onExport: () => _exportBackup(backup),
          onDelete: () => _deleteBackup(backup),
        );
      },
    );
  }

  Widget _buildCloudBackupTab() {
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
                  const Row(
                    children: [
                      Icon(Icons.cloud_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '云端存储',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '支持的云端服务',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _CloudServiceTile(
                    icon: Icons.storage,
                    name: 'Google Drive',
                    description: 'Google 云端硬盘',
                    isConnected: false,
                    onConnect: () {},
                  ),
                  _CloudServiceTile(
                    icon: Icons.cloud,
                    name: 'OneDrive',
                    description: '微软 OneDrive',
                    isConnected: false,
                    onConnect: () {},
                  ),
                  _CloudServiceTile(
                    icon: Icons.cloud_upload,
                    name: 'Dropbox',
                    description: 'Dropbox 云存储',
                    isConnected: false,
                    onConnect: () {},
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
                  const Row(
                    children: [
                      Icon(Icons.sync, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '自动同步',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('启用自动备份'),
                    subtitle: const Text('每天凌晨自动备份数据'),
                    value: false,
                    onChanged: (v) {},
                  ),
                  ListTile(
                    title: const Text('备份时间'),
                    subtitle: const Text('每天 02:00'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('压缩备份文件'),
                  subtitle: const Text('节省存储空间'),
                  value: true,
                  onChanged: (v) {},
                ),
                SwitchListTile(
                  title: const Text('加密备份'),
                  subtitle: const Text('保护数据安全'),
                  value: false,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('保留天数'),
                  subtitle: const Text('30 天'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('清理旧备份'),
                  subtitle: const Text('删除超过保留期限的备份'),
                  onTap: _cleanOldBackups,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('关于备份'),
              subtitle: Text('版本 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    
    try {
      final repo = ref.read(crossPlatformBackupRepositoryProvider);
      await repo.createBackup();
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
      }
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup(BackupEntry backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复备份'),
        content: const Text('这将用备份数据替换当前数据，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(crossPlatformBackupRepositoryProvider);
      final success = await repo.restoreBackup(backup);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '恢复成功' : '恢复失败')),
        );
      }
    }
  }

  Future<void> _exportBackup(BackupEntry backup) async {
    // Export to file location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中')),
    );
  }

  Future<void> _deleteBackup(BackupEntry backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备份'),
        content: const Text('确定要删除此备份吗？'),
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
    );

    if (confirmed == true) {
      final repo = ref.read(crossPlatformBackupRepositoryProvider);
      await repo.deleteBackupFile(backup.name);
      await repo.deleteBackupEntry(backup.id!);
      await _loadData();
    }
  }

  Future<void> _cleanOldBackups() async {
    final repo = ref.read(crossPlatformBackupRepositoryProvider);
    final deletedCount = await repo.cleanOldBackups(30);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清理 $deletedCount 个旧备份')),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _StorageStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StorageStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

class _BackupCard extends StatelessWidget {
  final BackupEntry backup;
  final VoidCallback onRestore;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _BackupCard({
    required this.backup,
    required this.onRestore,
    required this.onExport,
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.backup, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(backup.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        backup.formattedSize,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${backup.recordCount} 条记录',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'restore', child: Text('恢复')),
                const PopupMenuItem(value: 'export', child: Text('导出')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
              onSelected: (value) {
                if (value == 'restore') onRestore();
                if (value == 'export') onExport();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _CloudServiceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final bool isConnected;
  final VoidCallback onConnect;

  const _CloudServiceTile({
    required this.icon,
    required this.name,
    required this.description,
    required this.isConnected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isConnected ? Colors.green : Colors.grey),
      title: Text(name),
      subtitle: Text(description),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : OutlinedButton(
              onPressed: onConnect,
              child: const Text('连接'),
            ),
    );
  }
}