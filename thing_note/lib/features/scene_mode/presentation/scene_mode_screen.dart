import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/scene_mode/data/scene_repository.dart';
import 'package:thing_note/features/scene_mode/domain/scene_mode.dart';

final scenesProvider = FutureProvider<List<SceneMode>>((ref) async {
  final repository = ref.watch(sceneModeRepositoryProvider);
  return await repository.getAllScenes();
});

final activeSceneProvider = FutureProvider<SceneMode?>((ref) async {
  final repository = ref.watch(sceneModeRepositoryProvider);
  return await repository.getActiveScene();
});

class SceneModeScreen extends ConsumerStatefulWidget {
  const SceneModeScreen({super.key});

  @override
  ConsumerState<SceneModeScreen> createState() => _SceneModeScreenState();
}

class _SceneModeScreenState extends ConsumerState<SceneModeScreen> {
  @override
  Widget build(BuildContext context) {
    final scenesAsync = ref.watch(scenesProvider);
    final activeSceneAsync = ref.watch(activeSceneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('场景模式'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSceneDialog(context),
            tooltip: '添加场景',
          ),
        ],
      ),
      body: scenesAsync.when(
        data: (scenes) => _buildContent(context, scenes, activeSceneAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<SceneMode> scenes,
    AsyncValue<SceneMode?> activeSceneAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveSceneCard(context, activeSceneAsync),
          const SizedBox(height: 24),
          Text(
            '可用场景',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...scenes.map((scene) => _buildSceneCard(context, scene)),
        ],
      ),
    );
  }

  Widget _buildActiveSceneCard(
    BuildContext context,
    AsyncValue<SceneMode?> activeSceneAsync,
  ) {
    return activeSceneAsync.when(
      data: (activeScene) {
        if (activeScene == null) {
          return Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_view,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未激活任何场景',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择一个场景以快速切换设置',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 8,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeScene.colorValue.withOpacity(0.3),
                  activeScene.colorValue.withOpacity(0.5),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '已激活',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(
                  activeScene.iconData,
                  size: 64,
                  color: activeScene.colorValue,
                ),
                const SizedBox(height: 12),
                Text(
                  activeScene.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSceneDetails(activeScene),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final repository = ref.read(sceneModeRepositoryProvider);
                        await repository.deactivateScene();
                        ref.invalidate(scenesProvider);
                        ref.invalidate(activeSceneProvider);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('退出场景'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: activeScene.colorValue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('加载失败: $e')),
        ),
      ),
    );
  }

  Widget _buildSceneDetails(SceneMode scene) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildDetailChip(Icons.notifications, scene.notificationLabel),
        if (scene.defaultReminderOffset != null)
          _buildDetailChip(
            Icons.alarm,
            '提前${scene.defaultReminderOffset}分钟',
          ),
        if (scene.themeMode != null)
          _buildDetailChip(
            scene.themeMode == 'dark' ? Icons.dark_mode : Icons.light_mode,
            scene.themeMode == 'dark' ? '深色模式' : '浅色模式',
          ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSceneCard(BuildContext context, SceneMode scene) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _activateScene(scene),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scene.colorValue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  scene.iconData,
                  size: 32,
                  color: scene.colorValue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.notificationLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (scene.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已激活',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _activateScene(scene),
                  tooltip: '激活',
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditSceneDialog(context, scene);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(context, scene);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _activateScene(SceneMode scene) async {
    final repository = ref.read(sceneModeRepositoryProvider);
    await repository.setActiveScene(scene.id!);
    ref.invalidate(scenesProvider);
    ref.invalidate(activeSceneProvider);
  }

  void _showAddSceneDialog(BuildContext context) {
    _showSceneEditDialog(context, null);
  }

  void _showEditSceneDialog(BuildContext context, SceneMode scene) {
    _showSceneEditDialog(context, scene);
  }

  void _showSceneEditDialog(BuildContext context, SceneMode? existingScene) {
    final nameController = TextEditingController(text: existingScene?.name ?? '');
    String selectedIcon = existingScene?.icon ?? 'work';
    String selectedColor = existingScene?.color ?? 'blue';
    String notificationMode = existingScene?.notificationMode ?? 'all';
    final int? reminderOffset = existingScene?.defaultReminderOffset;
    String? themeMode = existingScene?.themeMode;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingScene == null ? '添加场景' : '编辑场景'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '场景名称',
                        hintText: '例如：工作模式',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('图标'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildIconOption('work', Icons.work, selectedIcon, (s) {
                          setDialogState(() => selectedIcon = s);
                        }),
                        _buildIconOption('school', Icons.school, selectedIcon, (s) {
                          setDialogState(() => selectedIcon = s);
                        }),
                        _buildIconOption('home', Icons.home, selectedIcon, (s) {
                          setDialogState(() => selectedIcon = s);
                        }),
                        _buildIconOption('travel', Icons.flight, selectedIcon, (s) {
                          setDialogState(() => selectedIcon = s);
                        }),
                        _buildIconOption('rest', Icons.weekend, selectedIcon, (s) {
                          setDialogState(() => selectedIcon = s);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('颜色'),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildColorOption('blue', Colors.blue, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('green', Colors.green, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('orange', Colors.orange, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('purple', Colors.purple, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                        _buildColorOption('red', Colors.red, selectedColor, (s) {
                          setDialogState(() => selectedColor = s);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: notificationMode,
                      decoration: const InputDecoration(
                        labelText: '通知模式',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('全部通知')),
                        DropdownMenuItem(value: 'priority', child: Text('仅优先通知')),
                        DropdownMenuItem(value: 'silent', child: Text('免打扰')),
                        DropdownMenuItem(value: 'none', child: Text('完全静音')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => notificationMode = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: themeMode,
                      decoration: const InputDecoration(
                        labelText: '主题模式',
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('跟随系统')),
                        DropdownMenuItem(value: 'light', child: Text('浅色模式')),
                        DropdownMenuItem(value: 'dark', child: Text('深色模式')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => themeMode = value);
                      },
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
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入场景名称')),
                      );
                      return;
                    }

                    final repository = ref.read(sceneModeRepositoryProvider);
                    final scene = SceneMode(
                      id: existingScene?.id,
                      name: nameController.text,
                      icon: selectedIcon,
                      color: selectedColor,
                      notificationMode: notificationMode,
                      defaultReminderOffset: reminderOffset,
                      themeMode: themeMode,
                      isActive: existingScene?.isActive ?? false,
                      createdAt: existingScene?.createdAt ?? DateTime.now().toIso8601String(),
                    );

                    if (existingScene == null) {
                      await repository.insertScene(scene);
                    } else {
                      await repository.updateScene(scene);
                    }

                    ref.invalidate(scenesProvider);
                    ref.invalidate(activeSceneProvider);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(existingScene == null ? '添加' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIconOption(
    String value,
    IconData icon,
    String selected,
    Function(String) onSelect,
  ) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _buildColorOption(
    String value,
    Color color,
    String selected,
    Function(String) onSelect,
  ) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onSelect(value),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SceneMode scene) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除场景「${scene.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repository = ref.read(sceneModeRepositoryProvider);
                await repository.deleteScene(scene.id!);
                ref.invalidate(scenesProvider);
                ref.invalidate(activeSceneProvider);
                if (!mounted) return;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
