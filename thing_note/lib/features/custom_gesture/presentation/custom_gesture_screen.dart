import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/custom_gesture/data/custom_gesture_repository.dart';
import 'package:thing_note/features/custom_gesture/domain/custom_gesture.dart';

final customGestureRepoProvider = Provider((ref) => CustomGestureRepository(ref));

class CustomGestureScreen extends ConsumerStatefulWidget {
  const CustomGestureScreen({super.key});

  @override
  ConsumerState<CustomGestureScreen> createState() => _CustomGestureScreenState();
}

class _CustomGestureScreenState extends ConsumerState<CustomGestureScreen> {
  List<CustomGesture> _gestures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGestures();
  }

  Future<void> _loadGestures() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customGestureRepoProvider);
    _gestures = await repo.getAllGestures();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义手势'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gestures.isEmpty
              ? _buildEmptyState()
              : _buildGestureList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无自定义手势', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建快捷手势来快速执行操作'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('创建手势'),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gestures.length,
      itemBuilder: (context, index) {
        final gesture = _gestures[index];
        return _GestureCard(
          gesture: gesture,
          onToggle: () => _toggleGesture(gesture),
          onDelete: () => _deleteGesture(gesture.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    String gestureType = 'swipe';
    String actionType = 'navigate';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建手势'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '手势名称'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gestureType,
                  decoration: const InputDecoration(labelText: '手势类型'),
                  items: const [
                    DropdownMenuItem(value: 'swipe', child: Text('滑动手势')),
                    DropdownMenuItem(value: 'tap', child: Text('点击')),
                    DropdownMenuItem(value: 'long_press', child: Text('长按')),
                    DropdownMenuItem(value: 'double_tap', child: Text('双击')),
                  ],
                  onChanged: (v) => setDialogState(() => gestureType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: '动作类型'),
                  items: const [
                    DropdownMenuItem(value: 'navigate', child: Text('导航')),
                    DropdownMenuItem(value: 'action', child: Text('执行动作')),
                    DropdownMenuItem(value: 'shortcut', child: Text('快捷操作')),
                  ],
                  onChanged: (v) => setDialogState(() => actionType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(customGestureRepoProvider);
                await repo.insertGesture(CustomGesture(
                  name: nameController.text.trim(),
                  gestureType: gestureType,
                  actionType: actionType,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadGestures();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleGesture(CustomGesture gesture) async {
    final repo = ref.read(customGestureRepoProvider);
    await repo.toggleEnabled(gesture.id!);
    _loadGestures();
  }

  Future<void> _deleteGesture(int id) async {
    final repo = ref.read(customGestureRepoProvider);
    await repo.deleteGesture(id);
    _loadGestures();
  }
}

class _GestureCard extends StatelessWidget {
  final CustomGesture gesture;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _GestureCard({
    required this.gesture,
    required this.onToggle,
    required this.onDelete,
  });

  IconData _getGestureIcon() {
    switch (gesture.gestureType) {
      case 'swipe':
        return Icons.swipe;
      case 'tap':
        return Icons.touch_app;
      case 'long_press':
        return Icons.touch_app_outlined;
      case 'double_tap':
        return Icons.touch_app;
      default:
        return Icons.touch_app;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getGestureIcon()),
        title: Text(gesture.name),
        subtitle: Text('${gesture.gestureType} → ${gesture.actionType}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: gesture.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}