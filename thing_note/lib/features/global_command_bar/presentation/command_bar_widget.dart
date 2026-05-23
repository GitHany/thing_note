import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/command_models.dart';

/// 全局命令栏 Widget
class GlobalCommandBar extends ConsumerWidget {
  const GlobalCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(commandBarVisibleProvider);
    final filteredCommands = ref.watch(filteredCommandsProvider);
    // watch search query to trigger rebuild when typing
    ref.watch(commandSearchProvider);

    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: '输入命令或搜索...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(commandBarVisibleProvider.notifier).state = false;
                  ref.read(commandSearchProvider.notifier).clear();
                },
              ),
            ),
            onChanged: (value) {
              ref.read(commandSearchProvider.notifier).search(value);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: filteredCommands.length,
              itemBuilder: (context, index) {
                final cmd = filteredCommands[index];
                return ListTile(
                  leading: Icon(cmd.icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(cmd.title),
                  subtitle: cmd.subtitle != null ? Text(cmd.subtitle!) : null,
                  onTap: () {
                    ref.read(commandBarVisibleProvider.notifier).state = false;
                    ref.read(commandSearchProvider.notifier).clear();
                    context.push(cmd.route);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 命令栏快捷键处理
class CommandBarIntent extends Intent {
  const CommandBarIntent();
}

/// 打开命令栏 Action
class OpenCommandBarAction extends Action<CommandBarIntent> {
  final WidgetRef ref;

  OpenCommandBarAction(this.ref);

  @override
  Object? invoke(CommandBarIntent intent) {
    ref.read(commandBarVisibleProvider.notifier).state = true;
    return null;
  }
}