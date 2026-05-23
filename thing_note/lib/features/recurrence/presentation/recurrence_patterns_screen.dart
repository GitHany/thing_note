import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/recurrence/domain/recurrence_pattern.dart';
import 'package:thing_note/features/recurrence/presentation/providers/recurrence_provider.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

/// 重复模式管理屏幕
class RecurrencePatternsScreen extends ConsumerWidget {
  const RecurrencePatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(savedRecurrencePatternsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurrencePatterns),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.analyze,
            onPressed: () {
              ref.read(recurrenceDetectorProvider.notifier).analyzeAllThingNames();
              ref.invalidate(savedRecurrencePatternsProvider);
            },
          ),
        ],
      ),
      body: patternsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (patterns) {
          if (patterns.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.builder(
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return _buildPatternCard(context, ref, pattern);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noRecurrencePatterns,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createRecordsToDetect,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(recurrenceDetectorProvider.notifier).analyzeAllThingNames();
              ref.invalidate(savedRecurrencePatternsProvider);
            },
            icon: const Icon(Icons.search),
            label: Text(l10n.analyze),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BuildContext context, WidgetRef ref, RecordRecurrencePattern pattern) {
    final l10n = AppLocalizations.of(context)!;
    final confidencePercent = (pattern.confidence * 100).toInt();
    final repeatTypeText = _getRepeatTypeText(pattern.repeatType, l10n);
    final dayText = _getDayText(pattern.dayOfWeek, l10n);
    final timeText = '${pattern.suggestedHour.toString().padLeft(2, '0')}:${pattern.suggestedMinute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRepeatTypeIcon(pattern.repeatType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pattern.thingName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.delete),
                        content: Text(l10n.confirmDeletePattern),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && pattern.thingNameId != null) {
                      final patternRepo = ref.read(recurrencePatternServiceProvider);
                      await patternRepo.deletePattern(pattern.thingNameId!);
                      ref.invalidate(savedRecurrencePatternsProvider);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(
                  context,
                  repeatTypeText,
                  Icons.repeat,
                ),
                const SizedBox(width: 8),
                _buildChip(context, dayText, Icons.calendar_today),
                const SizedBox(width: 8),
                _buildChip(context, timeText, Icons.access_time),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.confidenceLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pattern.confidence,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$confidencePercent%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getConfidenceColor(pattern.confidence),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (pattern.repeatType == 'monthly' && pattern.occurrenceDays.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                pattern.occurrenceDays.map((d) => l10n.monthlyOn(d)).join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _getRepeatTypeText(String repeatType, AppLocalizations l10n) {
    switch (repeatType) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'biweekly':
        return l10n.biweekly;
      case 'monthly':
        return l10n.monthly;
      case 'quarterly':
        return l10n.quarterly;
      case 'yearly':
        return l10n.yearly;
      default:
        return repeatType;
    }
  }

  String _getDayText(int dayOfWeek, AppLocalizations l10n) {
    return l10n.dayOfWeek(dayOfWeek);
  }

  IconData _getRepeatTypeIcon(String repeatType) {
    switch (repeatType) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'biweekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      case 'quarterly':
        return Icons.calendar_view_month;
      case 'yearly':
        return Icons.event;
      default:
        return Icons.repeat;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// 扩展 AppLocalizations 添加 dayOfWeek 方法
extension AppLocalizationsDayOfWeek on AppLocalizations {
  String dayOfWeek(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (day >= 1 && day <= 7) {
      return days[day - 1];
    }
    return 'Day $day';
  }
}