import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class SmartGeofenceScreen extends ConsumerStatefulWidget {
  const SmartGeofenceScreen({super.key});

  @override
  ConsumerState<SmartGeofenceScreen> createState() =>
      _SmartGeofenceScreenState();
}

class _SmartGeofenceScreenState extends ConsumerState<SmartGeofenceScreen> {
  bool _isLocationEnabled = false;
  final List<_Geofence> _geofences = [
    _Geofence(
      id: 1,
      name: '公司',
      address: '北京市朝阳区xxx',
      radius: 100,
      isActive: true,
      triggers: [
        _GeofenceTrigger(
          action: '开启专注模式',
          type: _TriggerType.onEnter,
        ),
        _GeofenceTrigger(
          action: '关闭提醒',
          type: _TriggerType.onExit,
        ),
      ],
    ),
    _Geofence(
      id: 2,
      name: '家',
      address: '北京市海淀区xxx',
      radius: 150,
      isActive: true,
      triggers: [
        _GeofenceTrigger(
          action: '开启勿扰模式',
          type: _TriggerType.onEnter,
        ),
      ],
    ),
    _Geofence(
      id: 3,
      name: '健身房',
      address: '北京市朝阳区xxx',
      radius: 50,
      isActive: false,
      triggers: [
        _GeofenceTrigger(
          action: '开始运动记录',
          type: _TriggerType.onEnter,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.smartGeofence),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Location status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isLocationEnabled ? Icons.location_on : Icons.location_off,
                    size: 40,
                    color: _isLocationEnabled ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLocationEnabled
                              ? AppLocalizations.of(context)!.locationEnabled
                              : AppLocalizations.of(context)!.locationDisabled,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _isLocationEnabled
                              ? '已激活 ${_geofences.where((g) => g.isActive).length} 个地理围栏'
                              : '点击开启位置服务',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isLocationEnabled,
                    onChanged: (value) => _toggleLocation(value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Geofence list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.myGeofences,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed: () => _showCreateGeofenceDialog(),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_geofences.map((geofence) => _buildGeofenceCard(geofence))),
          const SizedBox(height: 24),

          // Active geofence map preview
          if (_geofences.any((g) => g.isActive)) ...[
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.map),
                        const SizedBox(width: 8),
                        Text(
                          '地理围栏预览',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '地图预览区域',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Automation rules
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '位置自动化规则',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: const Text('进入公司时'),
                  subtitle: const Text('自动开启专注模式'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: const Text('离开家时'),
                  subtitle: const Text('自动记录通勤时间'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.near_me),
                  title: const Text('到达健身房时'),
                  subtitle: const Text('开始运动追踪'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceCard(_Geofence geofence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openGeofence(geofence),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: geofence.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: geofence.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          geofence.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          geofence.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: geofence.isActive,
                    onChanged: (value) {
                      setState(() => geofence.isActive = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.radar,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${geofence.radius}米范围',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.flash_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${geofence.triggers.length} 个触发器',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: geofence.triggers
                    .map((t) => Chip(
                          avatar: Icon(
                            t.type == _TriggerType.onEnter
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            size: 14,
                          ),
                          label: Text(
                            t.action,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLocation(bool value) async {
    if (value) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return;
        }
      }
    }
    setState(() => _isLocationEnabled = value);
  }

  void _showCreateGeofenceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建地理围栏'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '地址',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('范围: '),
                Expanded(
                  child: Slider(
                    value: 100,
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: '100米',
                    onChanged: (value) {},
                  ),
                ),
                const Text('100米'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _openGeofence(_Geofence geofence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('编辑围栏: ${geofence.name}')),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.battery_saver),
            title: const Text('电池优化'),
            subtitle: const Text('智能调节位置更新频率'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          const ListTile(
            leading: Icon(Icons.schedule),
            title: Text('更新频率'),
            subtitle: Text('智能调节'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('通知设置'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

enum _TriggerType { onEnter, onExit }

class _Geofence {
  final int id;
  final String name;
  final String address;
  final int radius;
  bool isActive;
  final List<_GeofenceTrigger> triggers;

  _Geofence({
    required this.id,
    required this.name,
    required this.address,
    required this.radius,
    required this.isActive,
    required this.triggers,
  });
}

class _GeofenceTrigger {
  final String action;
  final _TriggerType type;

  _GeofenceTrigger({
    required this.action,
    required this.type,
  });
}