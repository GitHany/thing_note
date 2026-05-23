import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/cross_device_sync/data/sync_provider.dart';
import 'package:thing_note/features/cross_device_sync/domain/sync_model.dart';
import 'package:uuid/uuid.dart';

class CrossDeviceSyncScreen extends ConsumerStatefulWidget {
  const CrossDeviceSyncScreen({super.key});

  @override
  ConsumerState<CrossDeviceSyncScreen> createState() =>
      _CrossDeviceSyncScreenState();
}

class _CrossDeviceSyncScreenState extends ConsumerState<CrossDeviceSyncScreen> {
  final _uuid = const Uuid();
  
  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(syncNotifierProvider);
    final statsAsync = ref.watch(syncStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('跨设备同步'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _triggerSync(),
            tooltip: '立即同步',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Devices List
          Expanded(
            child: devicesAsync.when(
              data: (devices) => _buildDevicesList(devices),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDevice(),
        icon: const Icon(Icons.add),
        label: const Text('添加设备'),
      ),
    );
  }

  Widget _buildStatsCard(SyncStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('设备数', '${stats.totalDevices}', Icons.devices),
              _buildStatItem('活跃', '${stats.activeDevices}', Icons.check_circle),
              _buildStatItem('待同步', '${stats.pendingChanges}', Icons.pending),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.lastSyncTime != null)
            Text(
              '上次同步: ${_formatTime(stats.lastSyncTime!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stats.syncSuccessRate,
            backgroundColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDevicesList(List<DeviceSyncState> devices) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无设备',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击 + 添加新设备',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(DeviceSyncState device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.status == 'active'
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            Icons.smartphone,
            color: device.status == 'active' ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          device.deviceId.length > 20
              ? '${device.deviceId.substring(0, 20)}...'
              : device.deviceId,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: ${device.syncVersion}'),
            Text(
              '最后同步: ${_formatTime(device.lastSyncTime)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: device.status == 'active'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                device.status == 'active' ? '活跃' : '离线',
                style: TextStyle(
                  color: device.status == 'active' ? Colors.green : Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmRemoveDevice(device),
            ),
          ],
        ),
      ),
    );
  }

  void _addDevice() {
    final deviceId = _uuid.v4();
    ref.read(syncNotifierProvider.notifier).registerDevice(deviceId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加设备: $deviceId')),
    );
  }

  void _triggerSync() {
    ref.read(syncNotifierProvider.notifier).triggerSync();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('同步已触发...')),
    );
  }

  void _confirmRemoveDevice(DeviceSyncState device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: const Text('确定要移除此设备吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(syncNotifierProvider.notifier).removeDevice(device.deviceId);
              Navigator.pop(context);
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}