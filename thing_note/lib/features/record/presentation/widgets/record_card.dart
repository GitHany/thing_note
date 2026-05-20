import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thing_note/app/theme/app_theme.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.shadow,
                blurRadius: _isPressed ? 2 : (isLight ? 8 : 4),
                offset: Offset(0, _isPressed ? 1 : (isLight ? 2 : 1)),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcon,
                                size: 16,
                                color: cs.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.thingName != null
                                      ? '${DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo)} · ${widget.thingName}'
                                      : DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: cs.primary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDurationChip(context),
                      ],
                    ),
                    if (widget.record.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.record.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.85),
                              height: 1.5,
                            ),
                      ),
                    ],
                    if (widget.record.hasPhotos || widget.record.hasAudio || widget.record.hasVideos) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (widget.record.hasPhotos)
                            _buildBadge(
                              context,
                              icon: Icons.photo_library_outlined,
                              label: '${widget.record.photoPaths.length}',
                            ),
                          if (widget.record.hasVideos)
                            _buildBadge(
                              context,
                              icon: Icons.videocam_outlined,
                              label: '${widget.record.videoPaths.length}',
                            ),
                          if (widget.record.hasAudio)
                            _buildBadge(
                              context,
                              icon: Icons.headphones_outlined,
                              label: DurationFormatter.formatShort(Duration(seconds: widget.record.totalAudioDurationSec)),
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

  IconData get _categoryIcon {
    if (widget.record.hasPhotos && widget.record.hasAudio) {
      return Icons.category_outlined;
    }
    if (widget.record.hasPhotos) return Icons.photo_camera_outlined;
    if (widget.record.hasAudio) return Icons.mic_outlined;
    if (widget.record.hasVideos) return Icons.videocam_outlined;
    return Icons.article_outlined;
  }

  Widget _buildDurationChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        DurationFormatter.formatShort(widget.record.duration),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context,
      {required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
