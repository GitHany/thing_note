import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/app/theme/theme_provider.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clearTempZips(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有临时压缩包吗？\n\n此操作不会删除记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final zipDir = Directory('${tempDir.path}/exported_zips');
        if (await zipDir.exists()) {
          await zipDir.delete(recursive: true);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('临时压缩包已清除')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('事情名称管理'),
            subtitle: const Text('管理可用的事情名称列表'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/thing-names'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除临时压缩包'),
            subtitle: const Text('删除分享时生成的临时文件'),
            onTap: () => _clearTempZips(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '清除所有数据',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          const Divider(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '事件记录 v0.0.2',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: ThemeMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Radio<ThemeMode>(
                  value: mode,
                  groupValue: current,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                ),
                Text(_themeModeLabel(mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有数据吗？此操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recordRepositoryProvider).deleteAll();
              ref.invalidate(recordListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('所有数据已清除')),
                );
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }
}
