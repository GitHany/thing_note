import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class TimerWidget extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  const TimerWidget({
    super.key,
    this.initialDuration = Duration.zero,
    required this.onDurationChanged,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Duration _duration;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
  }

  @override
  void didUpdateWidget(covariant TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDuration != oldWidget.initialDuration) {
      _duration = widget.initialDuration;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
      widget.onDurationChanged(_duration);
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
    widget.onDurationChanged(_duration);
  }

  Future<void> _showDurationPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => _CupertinoDurationPicker(
        initialDuration: _duration,
        onConfirm: (result) {
          if (result != null && mounted) {
            setState(() {
              _duration = result;
            });
            widget.onDurationChanged(_duration);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isWideScreen = screenWidth > 600;

    // Responsive sizing
    final cardPadding = isSmallScreen ? 12.0 : (isWideScreen ? 20.0 : 16.0);
    final displayFontSize = isSmallScreen ? 18.0 : (isWideScreen ? 26.0 : 22.0);
    final labelFontSize = isSmallScreen ? 10.0 : 12.0;
    final buttonSpacing = isSmallScreen ? 8.0 : 12.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showDurationPicker,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DurationFormatter.format(_duration),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                        fontSize: displayFontSize,
                      ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              l10n.duration,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: labelFontSize,
                  ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: Icon(Icons.play_arrow, size: isSmallScreen ? 18 : 24),
                    label: Text(l10n.startTimer, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  )
                else
                  FilledButton.icon(
                    onPressed: _pause,
                    icon: Icon(Icons.pause, size: isSmallScreen ? 18 : 24),
                    label: Text(l10n.pause, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                  ),
                SizedBox(width: buttonSpacing),
                OutlinedButton.icon(
                  onPressed: _duration > Duration.zero ? _finish : null,
                  icon: Icon(Icons.check, size: isSmallScreen ? 18 : 24),
                  label: Text(l10n.done, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoDurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration?> onConfirm;

  const _CupertinoDurationPicker({
    required this.initialDuration,
    required this.onConfirm,
  });

  @override
  State<_CupertinoDurationPicker> createState() => _CupertinoDurationPickerState();
}

class _CupertinoDurationPickerState extends State<_CupertinoDurationPicker> {
  late Duration _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 300,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(l10n.cancel),
                onPressed: () {
                  widget.onConfirm(null);
                  Navigator.pop(context);
                },
              ),
              CupertinoButton(
                child: Text(l10n.confirm),
                onPressed: () {
                  widget.onConfirm(_selectedDuration);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          Expanded(
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hms,
              initialTimerDuration: _selectedDuration,
              onTimerDurationChanged: (Duration duration) {
                setState(() {
                  _selectedDuration = duration;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
