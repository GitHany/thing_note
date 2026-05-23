import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/keyboard_shortcuts/data/keyboard_shortcuts_provider.dart';
import 'package:thing_note/features/keyboard_shortcuts/domain/keyboard_shortcut.dart';

class KeyboardShortcutsScreen extends ConsumerWidget {
  const KeyboardShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(keyboardShortcutsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Shortcuts'),
      ),
      body: ListView(
        children: [
          // Enable/Disable toggle
          SwitchListTile(
            secondary: Icon(isEnabled ? Icons.keyboard : Icons.keyboard_hide),
            title: const Text('Enable Shortcuts'),
            subtitle: const Text('Use keyboard shortcuts for faster navigation'),
            value: isEnabled,
            onChanged: (_) {
              ref.read(keyboardShortcutsEnabledProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // Shortcuts list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Available Shortcuts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...AppShortcuts.all.map((shortcut) => _ShortcutTile(
                shortcut: shortcut,
                enabled: isEnabled,
              )),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final KeyboardShortcut shortcut;
  final bool enabled;

  const _ShortcutTile({
    required this.shortcut,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          shortcut.displayString,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: enabled
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Colors.grey,
          ),
        ),
      ),
      title: Text(
        shortcut.label,
        style: TextStyle(
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        shortcut.description,
        style: TextStyle(
          color: enabled ? null : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Widget that wraps content and handles keyboard shortcuts
class KeyboardShortcutsWrapper extends ConsumerWidget {
  final Widget child;
  final VoidCallback onNewRecord;
  final VoidCallback onSearch;
  final VoidCallback onSave;
  final VoidCallback onSettings;
  final VoidCallback onTimeline;
  final VoidCallback onCalendar;
  final VoidCallback onStatistics;
  final VoidCallback onEscape;

  const KeyboardShortcutsWrapper({
    super.key,
    required this.child,
    required this.onNewRecord,
    required this.onSearch,
    required this.onSave,
    required this.onSettings,
    required this.onTimeline,
    required this.onCalendar,
    required this.onStatistics,
    required this.onEscape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(keyboardShortcutsEnabledProvider);
    final handler = ref.read(keyboardShortcutsHandlerProvider);

    if (!isEnabled) return child;

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) {
        handler.handleKeyEvent(
          event,
          onNewRecord: onNewRecord,
          onSearch: onSearch,
          onSave: onSave,
          onSettings: onSettings,
          onTimeline: onTimeline,
          onCalendar: onCalendar,
          onStatistics: onStatistics,
          onEscape: onEscape,
        );
      },
      child: child,
    );
  }
}