import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class MindfulMomentsScreen extends ConsumerStatefulWidget {
  const MindfulMomentsScreen({super.key});

  @override
  ConsumerState<MindfulMomentsScreen> createState() => _MindfulMomentsScreenState();
}

class _MindfulMomentsScreenState extends ConsumerState<MindfulMomentsScreen>
    with TickerProviderStateMixin {
  int _selectedMinutes = 5;
  bool _isRunning = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  int _sessionsCompleted = 0;
  int _totalMinutesMeditated = 0;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _totalSeconds = _selectedMinutes * 60;
      _remainingSeconds = _totalSeconds;
    });
    _runTimer();
  }

  void _runTimer() async {
    while (_remainingSeconds > 0 && _isRunning && !_isPaused) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRunning && !_isPaused) {
        setState(() => _remainingSeconds--);
      }
    }
    if (_remainingSeconds == 0 && mounted) {
      _completeSession();
    }
  }

  void _pauseSession() {
    setState(() => _isPaused = true);
  }

  void _resumeSession() {
    setState(() => _isPaused = false);
    _runTimer();
  }

  void _stopSession() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
    });
  }

  void _completeSession() {
    setState(() {
      _sessionsCompleted++;
      _totalMinutesMeditated += _selectedMinutes;
      _isRunning = false;
      _isPaused = false;
    });
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(ctx)!.sessionCompleted),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_selectedMinutes ${AppLocalizations.of(ctx)!.minutes}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(ctx)!.greatJob),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.done),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mindfulMoments),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.check_circle,
                      value: '$_sessionsCompleted',
                      label: AppLocalizations.of(context)!.sessions,
                    ),
                    _StatItem(
                      icon: Icons.timer,
                      value: '$_totalMinutesMeditated',
                      label: AppLocalizations.of(context)!.totalMinutes,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timer display
            if (_isRunning) ...[
              Center(
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_remainingSeconds),
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              if (_isPaused)
                                Text(
                                  AppLocalizations.of(context)!.paused,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isPaused)
                    FilledButton.icon(
                      onPressed: _resumeSession,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(AppLocalizations.of(context)!.resume),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _pauseSession,
                      icon: const Icon(Icons.pause),
                      label: Text(AppLocalizations.of(context)!.pause),
                    ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _stopSession,
                    icon: const Icon(Icons.stop),
                    label: Text(AppLocalizations.of(context)!.stop),
                  ),
                ],
              ),
            ] else ...[
              // Duration selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectDuration,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [3, 5, 10, 15, 20, 30].map((minutes) {
                          final isSelected = _selectedMinutes == minutes;
                          return ChoiceChip(
                            label: Text('$minutes ${AppLocalizations.of(context)!.minutesShort}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedMinutes = minutes);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Breathing guide
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _breathingAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 120 * _breathingAnimation.value,
                            height: 120 * _breathingAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.self_improvement,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.breathingGuide,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _breathingController.isAnimating
                            ? AppLocalizations.of(context)!.inhaleExhale
                            : '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start button
              FilledButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  '${AppLocalizations.of(context)!.startSession} ($_selectedMinutes ${AppLocalizations.of(context)!.minutes})',
                  style: const TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.meditationHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(AppLocalizations.of(context)!.sessionsCompleted),
              trailing: Text('$_sessionsCompleted'),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.totalTime),
              trailing: Text('$_totalMinutesMeditated ${AppLocalizations.of(context)!.minutes}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}