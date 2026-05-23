import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/study_timer/data/study_session_repository.dart';
import 'package:thing_note/features/study_timer/domain/study_session.dart';

class StudyTimerScreen extends ConsumerStatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  ConsumerState<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends ConsumerState<StudyTimerScreen> {
  bool _isTimerRunning = false;
  int _remainingSeconds = 0;
  String _currentSubject = '';

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(studySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习计时器'),
      ),
      body: Column(
        children: [
          // Timer display
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (_isTimerRunning) ...[
                  Text(
                    _currentSubject,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _pauseTimer(),
                        child: const Text('暂停'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _stopTimer(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('停止'),
                      ),
                    ],
                  ),
                ] else ...[
                  const Icon(Icons.timer, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('点击开始学习', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showStartSessionDialog(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始学习'),
                  ),
                ],
              ],
            ),
          ),
          // Today's stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${ref.watch(todayStudyMinutesProvider).maybeWhen(
                        data: (m) => m,
                        orElse: () => 0,
                      )}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('今日分钟'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${ref.watch(weeklyStudyMinutesProvider).maybeWhen(
                        data: (m) => m,
                        orElse: () => 0,
                      )}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('本周分钟'),
                  ],
                ),
              ],
            ),
          ),
          // Recent sessions
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(child: Text('暂无学习记录'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) => _StudySessionCard(session: sessions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog(BuildContext context) {
    final subjectController = TextEditingController();
    int selectedMinutes = 25;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('开始学习'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: '学习科目'),
              ),
              const SizedBox(height: 16),
              const Text('选择时长'),
              Wrap(
                spacing: 8,
                children: [15, 25, 45, 60, 90].map((m) => ChoiceChip(
                  label: Text('$m 分钟'),
                  selected: selectedMinutes == m,
                  onSelected: (selected) => setState(() => selectedMinutes = m),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final subject = subjectController.text.trim().isEmpty 
                    ? '学习' 
                    : subjectController.text.trim();
                _startTimer(subject, selectedMinutes);
                Navigator.pop(context);
              },
              child: const Text('开始'),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer(String subject, int minutes) {
    setState(() {
      _isTimerRunning = true;
      _currentSubject = subject;
      _remainingSeconds = minutes * 60;
    });
    
    final session = StudySession(
      subject: subject,
      durationMinutes: minutes,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    ref.read(studySessionsProvider.notifier).startSession(session);
  }

  void _pauseTimer() {
    setState(() {
      _remainingSeconds = (_remainingSeconds > 0) ? _remainingSeconds - 1 : 0;
    });
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
      _currentSubject = '';
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _StudySessionCard extends ConsumerWidget {
  final StudySession session;

  const _StudySessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.isCompleted ? Colors.green : Colors.orange,
          child: Icon(
            session.isCompleted ? Icons.check : Icons.hourglass_empty,
            color: Colors.white,
          ),
        ),
        title: Text(session.subject),
        subtitle: Text('${session.durationMinutes} 分钟'),
        trailing: Text(
          _formatDate(session.startedAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}