import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/geofence/domain/geofence.dart';
import 'package:thing_note/features/geofence/data/geofence_provider.dart';

class GeofenceScreen extends ConsumerStatefulWidget {
  const GeofenceScreen({super.key});

  @override
  ConsumerState<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends ConsumerState<GeofenceScreen> {
  @override
  Widget build(BuildContext context) {
    final geofencesAsync = ref.watch(geofenceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('地理位置围栏'),
      ),
      body: geofencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (geofences) {
          if (geofences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有设置任何围栏'),
                  const SizedBox(height: 8),
                  const Text('添加位置提醒，到达或离开时自动触发'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加围栏'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: geofences.length,
            itemBuilder: (context, index) {
              final geofence = geofences[index];
              return _GeofenceCard(
                geofence: geofence,
                onToggle: (enabled) {
                  ref.read(geofenceNotifierProvider.notifier)
                      .toggleGeofence(geofence.id!, enabled);
                },
                onEdit: () => _showEditDialog(context, geofence),
                onDelete: () => _deleteGeofence(geofence.id!),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_location),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _GeofenceEditor(),
    );
  }

  void _showEditDialog(BuildContext context, Geofence geofence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GeofenceEditor(existingGeofence: geofence),
    );
  }

  Future<void> _deleteGeofence(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除围栏'),
        content: const Text('确定要删除这个围栏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(geofenceNotifierProvider.notifier).deleteGeofence(id);
    }
  }
}

class _GeofenceCard extends StatelessWidget {
  final Geofence geofence;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GeofenceCard({
    required this.geofence,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: geofence.isEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    geofence.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: geofence.isEnabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: _getTriggerIcon(geofence.triggerType),
                  label: _getTriggerLabel(geofence.triggerType),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.radio_button_checked,
                  label: '${geofence.radiusMeters.toInt()}米',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '动作: ${_getActionLabel(geofence.actionType)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: const Text('编辑'),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTriggerIcon(String type) {
    switch (type) {
      case 'enter': return Icons.login;
      case 'exit': return Icons.logout;
      case 'dwell': return Icons.timer;
      default: return Icons.location_on;
    }
  }

  String _getTriggerLabel(String type) {
    switch (type) {
      case 'enter': return '进入';
      case 'exit': return '离开';
      case 'dwell': return '停留';
      default: return type;
    }
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'reminder': return '提醒';
      case 'notification': return '通知';
      case 'record': return '记录';
      default: return type;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _GeofenceEditor extends ConsumerStatefulWidget {
  final Geofence? existingGeofence;

  const _GeofenceEditor({this.existingGeofence});

  @override
  ConsumerState<_GeofenceEditor> createState() => _GeofenceEditorState();
}

class _GeofenceEditorState extends ConsumerState<_GeofenceEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  String _triggerType = 'enter';
  String _actionType = 'reminder';

  @override
  void initState() {
    super.initState();
    if (widget.existingGeofence != null) {
      _nameController.text = widget.existingGeofence!.name;
      _latController.text = widget.existingGeofence!.latitude.toString();
      _lngController.text = widget.existingGeofence!.longitude.toString();
      _radiusController.text = widget.existingGeofence!.radiusMeters.toInt().toString();
      _triggerType = widget.existingGeofence!.triggerType;
      _actionType = widget.existingGeofence!.actionType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingGeofence == null ? '添加围栏' : '编辑围栏',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：家、公司',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? '请输入名称' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: '纬度',
                        hintText: '39.9042',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty == true) return '必填';
                        final lat = double.tryParse(v!);
                        if (lat == null || lat < -90 || lat > 90) return '无效纬度';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(
                        labelText: '经度',
                        hintText: '116.4074',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty == true) return '必填';
                        final lng = double.tryParse(v!);
                        if (lng == null || lng < -180 || lng > 180) return '无效经度';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radiusController,
                decoration: const InputDecoration(
                  labelText: '半径 (米)',
                  hintText: '100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('触发类型'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'enter', label: Text('进入')),
                  ButtonSegment(value: 'exit', label: Text('离开')),
                  ButtonSegment(value: 'dwell', label: Text('停留')),
                ],
                selected: {_triggerType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _triggerType = selected.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('动作类型'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'reminder', label: Text('提醒')),
                  ButtonSegment(value: 'notification', label: Text('通知')),
                  ButtonSegment(value: 'record', label: Text('记录')),
                ],
                selected: {_actionType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _actionType = selected.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGeofence,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGeofence() {
    if (!_formKey.currentState!.validate()) return;

    final geofence = Geofence(
      id: widget.existingGeofence?.id,
      name: _nameController.text.trim(),
      latitude: double.parse(_latController.text),
      longitude: double.parse(_lngController.text),
      radiusMeters: double.tryParse(_radiusController.text) ?? 100,
      triggerType: _triggerType,
      isEnabled: widget.existingGeofence?.isEnabled ?? true,
      actionType: _actionType,
      createdAt: widget.existingGeofence?.createdAt ?? DateTime.now(),
    );

    if (widget.existingGeofence == null) {
      ref.read(geofenceNotifierProvider.notifier).addGeofence(geofence);
    } else {
      ref.read(geofenceNotifierProvider.notifier).updateGeofence(geofence);
    }

    Navigator.pop(context);
  }
}