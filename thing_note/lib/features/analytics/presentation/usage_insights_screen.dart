import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:thing_note/features/analytics/domain/usage_analyzer.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class UsageInsightsScreen extends ConsumerWidget {
  const UsageInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(usageInsightsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usageInsights),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usageInsightsProvider),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.loadFailed(e.toString())),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(usageInsightsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (insights) {
          if (insights.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noInsightsYet,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          // 分类展示
          final achievements = insights.where((i) => i.type == InsightType.achievement).toList();
          final others = insights.where((i) => i.type != InsightType.achievement).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (achievements.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.emoji_events,
                  title: l10n.achievements,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                ...achievements.map((i) => _InsightCard(
                      insight: i,
                      onActionTap: i.actionRoute != null ? () => context.push(i.actionRoute!) : null,
                    )),
                const SizedBox(height: 24),
              ],
              _SectionHeader(
                icon: Icons.insights,
                title: l10n.insights,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              ...others.map((i) => _InsightCard(
                    insight: i,
                    onActionTap: i.actionRoute != null ? () => context.push(i.actionRoute!) : null,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final UsageInsight insight;
  final VoidCallback? onActionTap;

  const _InsightCard({
    required this.insight,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onActionTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(insight.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(insight.type),
                  color: _getTypeColor(insight.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            insight.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _ScoreIndicator(score: insight.score),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    if (insight.actionText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            insight.actionText!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.frequency:
        return Icons.calendar_today;
      case InsightType.duration:
        return Icons.timer;
      case InsightType.pattern:
        return Icons.schedule;
      case InsightType.streak:
        return Icons.local_fire_department;
      case InsightType.suggestion:
        return Icons.lightbulb;
      case InsightType.achievement:
        return Icons.emoji_events;
    }
  }

  Color _getTypeColor(InsightType type) {
    switch (type) {
      case InsightType.frequency:
        return Colors.blue;
      case InsightType.duration:
        return Colors.green;
      case InsightType.pattern:
        return Colors.orange;
      case InsightType.streak:
        return Colors.deepOrange;
      case InsightType.suggestion:
        return Colors.teal;
      case InsightType.achievement:
        return Colors.amber;
    }
  }
}

class _ScoreIndicator extends StatelessWidget {
  final double score;

  const _ScoreIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: _getScoreColor(score),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.grey;
  }
}