import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

/// 快捷操作菜单提供商
final quickActionMenuExpandedProvider = StateProvider<bool>((ref) => false);

/// 快捷操作数据模型
class QuickAction {
  final String id;
  final IconData icon;
  final String labelKey; // 用于国际化
  final VoidCallback onTap;
  final Color? backgroundColor;

  const QuickAction({
    required this.id,
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.backgroundColor,
  });
}

/// 快捷操作菜单
class QuickActionMenu extends ConsumerWidget {
  final Widget child;

  const QuickActionMenu({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(quickActionMenuExpandedProvider);

    return Stack(
      children: [
        child,
        // 遮罩层
        if (isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        // 快捷操作按钮
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 展开的操作按钮
              if (isExpanded) ..._buildActionButtons(context, ref),
              const SizedBox(height: 16),
              // 主按钮
              _buildMainButton(context, ref, isExpanded),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isExpanded = ref.watch(quickActionMenuExpandedProvider);
    final actions = _getActions(context, l10n);

    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isExpanded ? 1.0 : 0.0),
        duration: Duration(milliseconds: 200 + (index * 50)),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActionButton(context, ref, action),
        ),
      );
    }).toList();
  }

  Widget _buildMainButton(BuildContext context, WidgetRef ref, bool isExpanded) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: () {
        ref.read(quickActionMenuExpandedProvider.notifier).state = !isExpanded;
      },
      backgroundColor: theme.colorScheme.primary,
      child: AnimatedRotation(
        turns: isExpanded ? 0.125 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, QuickAction action) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getLocalizedLabel(action.labelKey, l10n),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: action.backgroundColor ?? theme.colorScheme.secondaryContainer,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            onTap: () {
              ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              action.onTap();
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                action.icon,
                color: action.backgroundColor != null
                    ? Colors.white
                    : theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<QuickAction> _getActions(BuildContext context, AppLocalizations? l10n) {
    return [
      QuickAction(
        id: 'search',
        icon: Icons.search,
        labelKey: 'search',
        backgroundColor: Colors.blue,
        onTap: () {
          context.push('/search');
        },
      ),
      QuickAction(
        id: 'favorites',
        icon: Icons.star,
        labelKey: 'favorites',
        backgroundColor: Colors.amber,
        onTap: () {
          context.push('/?filter=favorites');
        },
      ),
      QuickAction(
        id: 'calendar',
        icon: Icons.calendar_today,
        labelKey: 'calendar',
        backgroundColor: Colors.green,
        onTap: () {
          context.push('/calendar');
        },
      ),
      QuickAction(
        id: 'timeline',
        icon: Icons.timeline,
        labelKey: 'timeline',
        backgroundColor: Colors.purple,
        onTap: () {
          context.push('/timeline');
        },
      ),
      QuickAction(
        id: 'statistics',
        icon: Icons.bar_chart,
        labelKey: 'statistics',
        backgroundColor: Colors.orange,
        onTap: () {
          context.push('/statistics');
        },
      ),
    ];
  }

  String _getLocalizedLabel(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'search':
        return l10n?.search ?? 'Search';
      case 'favorites':
        return l10n?.favorites ?? 'Favorites';
      case 'calendar':
        return l10n?.calendar ?? 'Calendar';
      case 'timeline':
        return l10n?.timeline ?? 'Timeline';
      case 'statistics':
        return l10n?.statistics ?? 'Statistics';
      default:
        return key;
    }
  }
}

/// 快捷操作FAB（替代主界面的悬浮按钮）
class QuickActionFab extends ConsumerWidget {
  const QuickActionFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(quickActionMenuExpandedProvider);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 展开的操作按钮
        if (isExpanded) ...[
          _buildMiniAction(
            context,
            Icons.search,
            'Search',
            () {
              ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              context.push('/search');
            },
          ),
          const SizedBox(height: 8),
          _buildMiniAction(
            context,
            Icons.star,
            'Favorites',
            () {
              ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              context.push('/?filter=favorites');
            },
          ),
          const SizedBox(height: 8),
          _buildMiniAction(
            context,
            Icons.calendar_today,
            'Calendar',
            () {
              ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              context.push('/calendar');
            },
          ),
          const SizedBox(height: 8),
          _buildMiniAction(
            context,
            Icons.timeline,
            'Timeline',
            () {
              ref.read(quickActionMenuExpandedProvider.notifier).state = false;
              context.push('/timeline');
            },
          ),
          const SizedBox(height: 16),
        ],
        // 主按钮
        FloatingActionButton(
          onPressed: () {
            ref.read(quickActionMenuExpandedProvider.notifier).state = !isExpanded;
          },
          backgroundColor: theme.colorScheme.primary,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.menu,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: 'mini_$label',
          onPressed: onTap,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}