import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

class RecordCard extends StatelessWidget {
  final EpisodeRecord record;
  final VoidCallback? onTap;
  final String? thingName;

  const RecordCard({super.key, required this.record, this.onTap, this.thingName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      thingName != null
                          ? '${DateFormatter.formatRelative(record.occurredAt)} · $thingName'
                          : DateFormatter.formatRelative(record.occurredAt),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _buildDurationChip(context),
                ],
              ),
              if (record.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (record.hasPhotos || record.hasAudio) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (record.hasPhotos)
                      _buildBadge(
                        context,
                        icon: Icons.photo,
                        label: '${record.photoPaths.length}',
                      ),
                    if (record.hasPhotos && record.hasAudio)
                      const SizedBox(width: 8),
                    if (record.hasAudio)
                      _buildBadge(
                        context,
                        icon: Icons.mic,
                        label: '${record.audioPaths.length} (${DurationFormatter.formatShort(Duration(seconds: record.totalAudioDurationSec))})',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        DurationFormatter.formatShort(record.duration),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context,
      {required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
