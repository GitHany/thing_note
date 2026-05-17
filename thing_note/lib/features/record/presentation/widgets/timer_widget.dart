import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';

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
    final result = await showDialog<Duration>(
      context: context,
      builder: (context) => _DurationPickerDialog(initialDuration: _duration),
    );
    if (result != null && mounted) {
      setState(() {
        _duration = result;
      });
      widget.onDurationChanged(_duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showDurationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DurationFormatter.format(_duration),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击可手动修改时间',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _duration > Duration.zero ? _finish : null,
                  icon: const Icon(Icons.check),
                  label: const Text('完成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationPickerDialog extends StatefulWidget {
  final Duration initialDuration;

  const _DurationPickerDialog({required this.initialDuration});

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: widget.initialDuration.inHours.toString(),
    );
    _minutesController = TextEditingController(
      text: widget.initialDuration.inMinutes.remainder(60).toString(),
    );
    _secondsController = TextEditingController(
      text: widget.initialDuration.inSeconds.remainder(60).toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _confirm() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final duration = Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
    Navigator.pop(context, duration);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置时间'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('小时'),
                TextField(
                  controller: _hoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(':', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('分钟'),
                TextField(
                  controller: _minutesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(':', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('秒'),
                TextField(
                  controller: _secondsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
