import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/features/dashboard/presentation/providers/dashboard_provider.dart';

/// Dashboard overview widget for the home screen
class DashboardOverview extends ConsumerWidget {
  final bool isExpanded;

  const DashboardOverview({
    super.key,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return statsAsync.when(
      loading: () => const _DashboardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (!isExpanded) {
          // Compact mode - just show counts
          return _buildCompactDashboard(context, stats, l10n, theme);
        }
        return _buildFullDashboard(context, stats, l10n, theme);
      },
    );
  }

  Widget _buildCompactDashboard(
    BuildContext context,
    DashboardStats stats,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);

    // Responsive values for compact mode
    final containerPadding = isUltraSmall ? 8.0 : 12.0;
    final searchPaddingH = isUltraSmall ? 8.0 : 12.0;
    final searchPaddingV = isUltraSmall ? 6.0 : 8.0;
    final searchIconSize = isUltraSmall ? 14.0 : 16.0;
    final searchTextSize = isUltraSmall ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isUltraSmall ? 10.0 : AppSpacing.mediumBorderRadius),
      ),
      child: Column(
        children: [
          // Search bar - larger touch target for small screens
          InkWell(
            onTap: () => _showQuickSearch(context),
            borderRadius: BorderRadius.circular(isUltraSmall ? 8.0 : 10.0),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: searchPaddingH,
                vertical: searchPaddingV,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(isUltraSmall ? 8.0 : 10.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: searchIconSize,
                    color: theme.colorScheme.outline,
                  ),
                  SizedBox(width: isUltraSmall ? 6.0 : 8.0),
                  Expanded(
                    child: Text(
                      l10n.searchRecords,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: searchTextSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isUltraSmall ? 6.0 : 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CompactStatItem(
                icon: Icons.today,
                value: '${stats.todayCount}',
                label: l10n.today,
                color: Colors.blue,
                onTap: () => context.push('/?filter=today'),
                compact: isUltraSmall,
              ),
              _CompactStatItem(
                icon: Icons.star,
                value: '${stats.favoriteCount}',
                label: l10n.favorites,
                color: Colors.amber,
                onTap: () => context.push('/?filter=favorites'),
                compact: isUltraSmall,
              ),
              _CompactStatItem(
                icon: Icons.notifications,
                value: '${stats.reminderCount}',
                label: l10n.reminderRecords,
                color: Colors.orange,
                onTap: () => context.push('/?filter=reminders'),
                compact: isUltraSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullDashboard(
    BuildContext context,
    DashboardStats stats,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);

    // Responsive padding based on screen size - unified padding
    final horizontalPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final verticalSpacing = AppSpacing.getVerticalSpacing(screenWidth);

    // Small screen uses compact mode
    if (isUltraSmall || isSmall) {
      return _buildCompactDashboard(context, stats, l10n, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar - always visible for easy access
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: InkWell(
            onTap: () => _showQuickSearch(context),
            borderRadius: BorderRadius.circular(AppSpacing.mediumBorderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.mediumBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: AppSpacing.defaultIconSize,
                    color: theme.colorScheme.outline,
                  ),
                  SizedBox(width: horizontalPadding * 0.7),
                  Text(
                    l10n.searchRecords,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: verticalSpacing),
        // Stats row - top two cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.today,
                  value: '${stats.todayCount}',
                  label: l10n.today,
                  color: Colors.blue,
                  onTap: () => context.push('/?filter=today'),
                  compact: false,
                ),
              ),
              SizedBox(width: AppSpacing.getItemSpacing(screenWidth)),
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.calendar_view_week,
                  value: '${stats.weekCount}',
                  label: l10n.thisWeek,
                  color: Colors.green,
                  onTap: () => context.push('/?filter=week'),
                  compact: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.getItemSpacing(screenWidth)),
        // Stats row - bottom two cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.star,
                  value: '${stats.favoriteCount}',
                  label: l10n.favorites,
                  color: Colors.amber,
                  onTap: () => context.push('/?filter=favorites'),
                  compact: false,
                ),
              ),
              SizedBox(width: AppSpacing.getItemSpacing(screenWidth)),
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.notifications,
                  value: '${stats.reminderCount}',
                  label: l10n.reminderRecords,
                  color: Colors.orange,
                  onTap: () => context.push('/?filter=reminders'),
                  compact: false,
                ),
              ),
            ],
          ),
        ),

        // Quick actions - only show on larger screens (not small screens)
        if (!isSmall && !isUltraSmall) ...[
          SizedBox(height: verticalSpacing + 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              l10n.quickActions,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                _QuickActionChip(
                  icon: Icons.calendar_today,
                  label: l10n.calendar,
                  onTap: () => context.push('/calendar'),
                ),
                SizedBox(width: AppSpacing.getItemSpacing(screenWidth)),
                _QuickActionChip(
                  icon: Icons.timeline,
                  label: l10n.timeline,
                  onTap: () => context.push('/timeline'),
                ),
                SizedBox(width: AppSpacing.getItemSpacing(screenWidth)),
                _QuickActionChip(
                  icon: Icons.analytics,
                  label: l10n.statistics,
                  onTap: () => context.push('/statistics'),
                ),
                if (stats.recurringCount > 0) ...[
                  SizedBox(width: AppSpacing.getItemSpacing(screenWidth)),
                  _QuickActionChip(
                    icon: Icons.repeat,
                    label: l10n.recurringRecords,
                    onTap: () => context.push('/?filter=recurring'),
                  ),
                ],
              ],
            ),
          ),
        ],
        // Bottom spacing for better visual balance
        SizedBox(height: verticalSpacing),
      ],
    );
  }

  void _showQuickSearch(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quickSearch),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchRecords,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(ctx);
              context.push('/search?query=${Uri.encodeComponent(value)}');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _CompactStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 20.0;
    final padding = compact ? 6.0 : 10.0;
    final valueSize = compact ? 12.0 : 14.0;
    final labelSize = compact ? 8.0 : 9.0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: compact ? 2 : 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: valueSize,
                  ),
            ),
            SizedBox(height: compact ? 0 : 1),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: labelSize,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _DashboardStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 24.0;
    final iconPadding = compact ? 10.0 : 12.0;
    final cardPadding = compact ? 12.0 : 16.0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: compact ? 16 : 18,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: compact ? 10 : 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 14.0;
    const verticalPadding = 10.0;
    const iconSize = 18.0;
    const fontSize = 14.0;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: fontSize)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(context, 60)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(context, 60)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(context, 60)),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonBox(context, 60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(BuildContext context, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}