import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/tag/domain/tag.dart';

class RecordCard extends StatefulWidget {
  final EpisodeRecord record;
  final VoidCallback? onTap;
  final String? thingName;
  final List<Tag> tags;

  const RecordCard({super.key, required this.record, this.onTap, this.thingName, this.tags = const []});

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  bool _isPressed = false;
  final Map<String, Color> _tagColorCache = {};

  Color _getTagColor(String hexColor) {
    return _tagColorCache.putIfAbsent(
      hexColor,
      () => Color(int.parse(hexColor.replaceFirst('#', '0xFF'))),
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

  String get _categorySemanticLabel {
    if (widget.record.hasPhotos && widget.record.hasAudio) {
      return 'Record with photos and audio';
    }
    if (widget.record.hasPhotos) return 'Record with photos';
    if (widget.record.hasAudio) return 'Record with audio';
    if (widget.record.hasVideos) return 'Record with videos';
    return 'Text note';
  }

  String _buildSemanticLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[];

    if (widget.record.isFavorite) {
      parts.add(l10n.favorites);
    }

    parts.add(DateFormatter.formatRelative(
      widget.record.occurredAt,
      justNow: l10n.justNow,
      minutesAgo: l10n.minutesAgo,
      hoursAgo: l10n.hoursAgo,
      yesterday: l10n.yesterday,
      daysAgo: l10n.daysAgo,
    ));

    if (widget.thingName != null) {
      parts.add(widget.thingName!);
    }

    if (widget.record.note.isNotEmpty) {
      parts.add(widget.record.note);
    }

    parts.add(DurationFormatter.formatShort(widget.record.duration));

    return parts.join(', ');
  }

  Widget _buildDurationChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isUltraSmall ? 6.0 : (isSmall ? 7.0 : 8.0),
        vertical: isUltraSmall ? 3.0 : (isSmall ? 3.5 : 4.0),
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(153),
        borderRadius: BorderRadius.circular(isUltraSmall ? 5.0 : (isSmall ? 6.0 : 8.0)),
      ),
      child: Text(
        DurationFormatter.formatShort(widget.record.duration),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: isUltraSmall ? 9.0 : (isSmall ? 10.0 : 11.0),
            ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, {required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0),
        vertical: isUltraSmall ? 2.0 : (isSmall ? 2.5 : 3.0),
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(isUltraSmall ? 4.0 : (isSmall ? 5.0 : 5.0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isUltraSmall ? 10.0 : (isSmall ? 11.0 : 12.0), color: cs.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: isUltraSmall ? 9.0 : (isSmall ? 10.0 : 11.0),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use AppSpacing for consistent responsive values
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);

    // Responsive sizing - unified design with consistent spacing
    const borderRadius = AppSpacing.mediumBorderRadius;
    final cardPadding = isUltraSmall ? 10.0 : (isSmall ? 12.0 : 14.0);
    final iconSize = isUltraSmall ? 14.0 : (isSmall ? 16.0 : 18.0);
    final titleFontSize = isUltraSmall ? 11.0 : (isSmall ? 12.0 : 13.0);
    final noteFontSize = isUltraSmall ? 12.0 : 13.0;
    final titleSpacing = isUltraSmall ? 6.0 : (isSmall ? 8.0 : 10.0);
    final badgeSpacing = isUltraSmall ? 4.0 : 6.0;
    final badgeRunSpacing = isUltraSmall ? 4.0 : 6.0;
    // Optimized spacing: compact but with visual breathing room
    final elementSpacing = isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0);

    return Semantics(
      label: _buildSemanticLabel(context),
      child: Listener(
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
              borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: cs.shadow,
                blurRadius: _isPressed ? 2 : (isLight ? 4 : 2),
                offset: Offset(0, _isPressed ? 1 : (isLight ? 1 : 0.5)),
                spreadRadius: 0,
              ),
            ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.record.note.isNotEmpty
                    ? () {
                        Clipboard.setData(ClipboardData(text: widget.record.note));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.content_copy, size: 18),
                                SizedBox(width: 8),
                                Text('已复制笔记内容'),
                              ],
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    : null,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _categoryIcon,
                            size: iconSize,
                            color: cs.primary.withAlpha(179),
                            semanticLabel: _categorySemanticLabel,
                          ),
                          SizedBox(width: elementSpacing),
                          Expanded(
                            child: Text(
                              widget.thingName != null
                                  ? '${DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo)} · ${widget.thingName}'
                                  : DateFormatter.formatRelative(widget.record.occurredAt, justNow: AppLocalizations.of(context)!.justNow, minutesAgo: AppLocalizations.of(context)!.minutesAgo, hoursAgo: AppLocalizations.of(context)!.hoursAgo, yesterday: AppLocalizations.of(context)!.yesterday, daysAgo: AppLocalizations.of(context)!.daysAgo),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: cs.primary,
                                    fontSize: titleFontSize,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.record.isFavorite) ...[
                            SizedBox(width: elementSpacing),
                            Icon(
                              Icons.star,
                              size: isSmall ? 12 : 14,
                              color: Colors.amber,
                              semanticLabel: 'Favorite',
                            ),
                          ],
                          SizedBox(width: elementSpacing),
                          _buildDurationChip(context),
                        ],
                      ),
                      if (widget.record.note.isNotEmpty) ...[
                        SizedBox(height: titleSpacing),
                        Text(
                          widget.record.note,
                          maxLines: AppSpacing.isUltraSmall(screenWidth) ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withAlpha(217),
                                height: 1.5,
                                fontSize: noteFontSize,
                              ),
                        ),
                      ],
                      if (widget.record.hasPhotos || widget.record.hasAudio || widget.record.hasVideos || widget.tags.isNotEmpty) ...[
                        SizedBox(height: titleSpacing),
                        Wrap(
                          spacing: badgeSpacing,
                          runSpacing: badgeRunSpacing,
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
                            ...widget.tags.take(isSmall ? 2 : 3).map((tag) {
                              final tagColor = _getTagColor(tag.color);
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0),
                                  vertical: isUltraSmall ? 2.0 : (isSmall ? 2.5 : 3.0),
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withAlpha(31),
                                  borderRadius: BorderRadius.circular(isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0)),
                                  border: Border.all(color: tagColor.withAlpha(64)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isUltraSmall ? 5.0 : (isSmall ? 6.0 : 7.0),
                                      height: isUltraSmall ? 5.0 : (isSmall ? 6.0 : 7.0),
                                      decoration: BoxDecoration(
                                        color: tagColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: isUltraSmall ? 3.0 : (isSmall ? 3.5 : 4.0)),
                                    Flexible(
                                      child: Text(
                                        tag.name,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: tagColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: isUltraSmall ? 9.0 : (isSmall ? 10.0 : 11.0),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (widget.tags.length > (isSmall ? 2 : 3))
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0),
                                  vertical: isUltraSmall ? 2.0 : (isSmall ? 2.5 : 3.0),
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh.withAlpha(153),
                                  borderRadius: BorderRadius.circular(isUltraSmall ? 4.0 : (isSmall ? 5.0 : 6.0)),
                                ),
                                child: Text(
                                  '+${widget.tags.length - (isSmall ? 2 : 3)}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                        fontSize: isUltraSmall ? 9.0 : (isSmall ? 10.0 : 11.0),
                                      ),
                                ),
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
      ),
    );
  }
}