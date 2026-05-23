import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/app/theme/theme_provider.dart';
import 'package:thing_note/app/theme/animation_constants.dart';

/// Smart Floating Action Button with expandable menu for quick actions
class SmartFab extends ConsumerStatefulWidget {
  const SmartFab({super.key});

  @override
  ConsumerState<SmartFab> createState() => _SmartFabState();
}

class _SmartFabState extends ConsumerState<SmartFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isKeyboardOpen = bottomInset > 0;

    // 小屏幕间距改为 10，大屏保持 14
    final itemSpacing = isSmallScreen ? 10.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs when expanded
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: isKeyboardOpen ? 1 : -1,
          child: Padding(
            padding: EdgeInsets.only(bottom: isKeyboardOpen ? 0 : 20, top: isKeyboardOpen ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniFab(
                  icon: Icons.search,
                  label: l10n.quickSearch,
                  onTap: () {
                    _toggle();
                    _showSearchDialog();
                  },
                ),
                SizedBox(height: itemSpacing),
                _MiniFab(
                  icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  label: isDarkMode ? l10n.themeModeLight : l10n.themeModeDark,
                  onTap: () {
                    _toggle();
                    ref.read(themeModeProvider.notifier).setThemeMode(
                      isDarkMode ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                ),
                SizedBox(height: itemSpacing),
                _MiniFab(
                  icon: Icons.star,
                  label: l10n.favorites,
                  onTap: () {
                    _toggle();
                    context.push('/?filter=favorites');
                  },
                ),
                SizedBox(height: itemSpacing),
                _MiniFab(
                  icon: Icons.notifications,
                  label: l10n.reminderRecords,
                  onTap: () {
                    _toggle();
                    context.push('/?filter=reminders');
                  },
                ),
                SizedBox(height: itemSpacing),
                _MiniFab(
                  icon: Icons.analytics,
                  label: l10n.todayStats,
                  onTap: () {
                    _toggle();
                    context.push('/statistics');
                  },
                ),
              ],
            ),
          ),
        ),

        // Main FAB
        FloatingActionButton.extended(
          onPressed: () {
            if (_isExpanded) {
              _toggle();
            } else {
              // Quick new record
              context.push('/record/new');
            }
          },
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
      duration: AppAnimations.normal,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _expandAnimation,
            ),
          ),
          label: AnimatedSwitcher(
            duration: AppAnimations.fast,
            child: Text(
              _isExpanded ? l10n.cancel : l10n.newRecord,
              key: ValueKey(_isExpanded),
            ),
          ),
        ),
        SizedBox(height: bottomPadding > 0 ? 0 : 8),
      ],
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _QuickSearchDialog(),
    );
  }
}

class _MiniFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniFab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final labelPaddingH = isWideScreen ? 14.0 : 12.0;
    final labelPaddingV = isWideScreen ? 10.0 : 8.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: labelPaddingH, vertical: labelPaddingV),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: 'mini_fab_$icon',
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _QuickSearchDialog extends StatefulWidget {
  @override
  State<_QuickSearchDialog> createState() => _QuickSearchDialogState();
}

class _QuickSearchDialogState extends State<_QuickSearchDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.quickSearch),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: l10n.searchRecords,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.push('/search?query=$value');
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              context.push('/search?query=${Uri.encodeComponent(_controller.text)}');
              Navigator.pop(context);
            }
          },
          child: Text(l10n.search),
        ),
      ],
    );
  }
}