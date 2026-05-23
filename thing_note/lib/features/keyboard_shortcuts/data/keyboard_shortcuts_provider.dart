import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/keyboard_shortcuts/domain/keyboard_shortcut.dart';

/// Keyboard shortcuts enabled state
final keyboardShortcutsEnabledProvider =
    StateNotifierProvider<KeyboardShortcutsEnabledNotifier, bool>((ref) {
  return KeyboardShortcutsEnabledNotifier();
});

class KeyboardShortcutsEnabledNotifier extends StateNotifier<bool> {
  static const _key = 'keyboard_shortcuts_enabled';

  KeyboardShortcutsEnabledNotifier() : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    final newState = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newState);
    state = newState;
  }
}

/// Keyboard shortcuts provider for handling shortcuts
final keyboardShortcutsHandlerProvider = Provider<KeyboardShortcutsHandler>((ref) {
  return KeyboardShortcutsHandler();
});

class KeyboardShortcutsHandler {
  /// Handle a key event and return true if handled
  bool handleKeyEvent(
    RawKeyEvent event, {
    required VoidCallback? onNewRecord,
    required VoidCallback? onSearch,
    required VoidCallback? onSave,
    required VoidCallback? onSettings,
    required VoidCallback? onTimeline,
    required VoidCallback? onCalendar,
    required VoidCallback? onStatistics,
    required VoidCallback? onEscape,
  }) {
    if (event is! RawKeyDownEvent) return false;

    // Check each shortcut
    for (final shortcut in AppShortcuts.all) {
      if (shortcut.matches(event)) {
        _executeShortcut(
          shortcut,
          onNewRecord: onNewRecord,
          onSearch: onSearch,
          onSave: onSave,
          onSettings: onSettings,
          onTimeline: onTimeline,
          onCalendar: onCalendar,
          onStatistics: onStatistics,
          onEscape: onEscape,
        );
        return true;
      }
    }

    return false;
  }

  void _executeShortcut(
    KeyboardShortcut shortcut, {
    VoidCallback? onNewRecord,
    VoidCallback? onSearch,
    VoidCallback? onSave,
    VoidCallback? onSettings,
    VoidCallback? onTimeline,
    VoidCallback? onCalendar,
    VoidCallback? onStatistics,
    VoidCallback? onEscape,
  }) {
    switch (shortcut.id) {
      case 'new_record':
        onNewRecord?.call();
        break;
      case 'search':
        onSearch?.call();
        break;
      case 'save':
        onSave?.call();
        break;
      case 'settings':
        onSettings?.call();
        break;
      case 'timeline':
        onTimeline?.call();
        break;
      case 'calendar':
        onCalendar?.call();
        break;
      case 'statistics':
        onStatistics?.call();
        break;
      case 'escape':
        onEscape?.call();
        break;
    }
  }
}