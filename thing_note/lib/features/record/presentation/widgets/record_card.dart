import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

class RecordCard extends StatefulWidget {
  final EpisodeRecord record;
  final VoidCallback? onTap;
  final String? thingName;

  const RecordCard({super.key, required this.record, this.onTap, this.thingName});

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Card(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
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
                            widget.thingName != null
                                ? '${DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo)} · ${widget.thingName}'
                                : DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        _buildDurationChip(context),
                      ],
                    ),
                    if (widget.record.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.record.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (widget.record.hasPhotos || widget.record.hasAudio) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.record.hasPhotos)
                            _buildBadge(
                              context,
                              icon: Icons.photo,
                              label: '${widget.record.photoPaths.length}',
                            ),
                          if (widget.record.hasPhotos && widget.record.hasAudio)
                            const SizedBox(width: 8),
                          if (widget.record.hasAudio)
                            _buildBadge(
                              context,
                              icon: Icons.mic,
                              label: '${widget.record.audioPaths.length} (${DurationFormatter.formatShort(Duration(seconds: widget.record.totalAudioDurationSec))})',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
        DurationFormatter.formatShort(widget.record.duration),
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
