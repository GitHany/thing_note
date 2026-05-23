import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/break_timer/data/break_timer_repository.dart';
import 'package:thing_note/features/break_timer/domain/break_session.dart';

class BreakTimerScreen extends ConsumerStatefulWidget {
  const BreakTimerScreen({super.key});

  @override
  ConsumerState<BreakTimerScreen> createState() => _BreakTimerScreenState();
}

class _BreakTimerScreenState extends ConsumerState<BreakTimerScreen> {
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(breakSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('休息计时')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 计时器
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRunning ? Colors.green.shade50 : Colors.grey.shade100,
                border: Border.all(
                  color: _isRunning ? Colors.green : Colors.grey.shade300,
                  width: 4,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _isRunning ? Colors.green : Colors.grey,
                      ),
                    ),
                    Text(
                      _isRunning ? '休息中...' : '准备开始',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 控制按钮
            if (!_isRunning)
              ElevatedButton.icon(
                onPressed: _startBreak,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始休息'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pauseBreak,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _endBreak,
                    icon: const Icon(Icons.stop),
                    label: const Text('结束'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            // 休息建议
            const Text('休息建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      _startBreakWithSuggestion(s);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${s.durationMinutes}分钟', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startBreak() {
    final now = DateTime.now();
    final session = BreakSession(
      startedAt: now,
      createdAt: now,
    );
    ref.read(breakTimerRepositoryProvider).startBreak(session);
    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _startBreakWithSuggestion(BreakSuggestion suggestion) {
    _startBreak();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('建议: ${suggestion.description}')),
    );
  }

  void _pauseBreak() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _endBreak() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('休息了 ${_elapsedSeconds ~/ 60} 分钟！')),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
