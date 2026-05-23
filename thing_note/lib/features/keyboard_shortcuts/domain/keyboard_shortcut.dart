import 'package:flutter/services.dart';

/// Keyboard shortcut definition
class KeyboardShortcut {
  final String id;
  final String label;
  final String description;
  final LogicalKeyboardKey key;
  final bool ctrlRequired;
  final bool shiftRequired;
  final bool altRequired;

  const KeyboardShortcut({
    required this.id,
    required this.label,
    required this.description,
    required this.key,
    this.ctrlRequired = true,
    this.shiftRequired = false,
    this.altRequired = false,
  });

  String get displayString {
    final parts = <String>[];
    if (ctrlRequired) parts.add('Ctrl');
    if (shiftRequired) parts.add('Shift');
    if (altRequired) parts.add('Alt');
    parts.add(key.keyLabel);
    return parts.join(' + ');
  }

  bool matches(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return false;
    return event.logicalKey == key &&
        HardwareKeyboard.instance.isControlPressed == ctrlRequired &&
        HardwareKeyboard.instance.isShiftPressed == shiftRequired &&
        HardwareKeyboard.instance.isAltPressed == altRequired;
  }
}

/// All available keyboard shortcuts
class AppShortcuts {
  static const List<KeyboardShortcut> all = [
    KeyboardShortcut(
      id: 'new_record',
      label: 'New Record',
      description: 'Create a new event record',
      key: LogicalKeyboardKey.keyN,
    ),
    KeyboardShortcut(
      id: 'search',
      label: 'Search',
      description: 'Open search',
      key: LogicalKeyboardKey.keyF,
    ),
    KeyboardShortcut(
      id: 'save',
      label: 'Save',
      description: 'Save current record',
      key: LogicalKeyboardKey.keyS,
    ),
    KeyboardShortcut(
      id: 'settings',
      label: 'Settings',
      description: 'Open settings',
      key: LogicalKeyboardKey.comma,
    ),
    KeyboardShortcut(
      id: 'timeline',
      label: 'Timeline',
      description: 'Switch to timeline view',
      key: LogicalKeyboardKey.keyT,
    ),
    KeyboardShortcut(
      id: 'calendar',
      label: 'Calendar',
      description: 'Switch to calendar view',
      key: LogicalKeyboardKey.keyC,
    ),
    KeyboardShortcut(
      id: 'statistics',
      label: 'Statistics',
      description: 'Open statistics',
      key: LogicalKeyboardKey.keyE,
    ),
    KeyboardShortcut(
      id: 'escape',
      label: 'Cancel / Close',
      description: 'Cancel current action or close dialog',
      key: LogicalKeyboardKey.escape,
      ctrlRequired: false,
    ),
  ];

  static KeyboardShortcut? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}