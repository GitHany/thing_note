import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

class FocusTrainingSession {
  final int? id;
  final String trainingType;
  final int durationMinutes;
  final double score;
  final int difficultyLevel;
  final double accuracyRate;
  final double improvementPercent;
  final String completedAt;
  final String createdAt;

  FocusTrainingSession({
    this.id,
    required this.trainingType,
    required this.durationMinutes,
    this.score = 0,
    this.difficultyLevel = 1,
    this.accuracyRate = 0,
    this.improvementPercent = 0,
    required this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'training_type': trainingType, 'duration_minutes': durationMinutes,
    'score': score, 'difficulty_level': difficultyLevel, 'accuracy_rate': accuracyRate,
    'improvement_percent': improvementPercent, 'completed_at': completedAt, 'created_at': createdAt,
  };
}

final focusTrainingProvider = StateNotifierProvider<FocusTrainingNotifier, List<FocusTrainingSession>>((ref) {
  return FocusTrainingNotifier();
});

class FocusTrainingNotifier extends StateNotifier<List<FocusTrainingSession>> {
  FocusTrainingNotifier() : super([]);

  void addSession(FocusTrainingSession session) {
    state = [session, ...state];
  }
}

class FocusTrainingScreen extends ConsumerStatefulWidget {
  const FocusTrainingScreen({super.key});
  @override
  ConsumerState<FocusTrainingScreen> createState() => _FocusTrainingScreenState();
}

class _FocusTrainingScreenState extends ConsumerState<FocusTrainingScreen> {
  bool _isTraining = false;
  int _currentGame = 0;
  int _score = 0;
  int _timeLeft = 30;
  List<int> _sequence = [];
  int _userIndex = 0;

  final _games = ['记忆力', '注意力', '反应力', '视觉搜索'];

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(focusTrainingProvider);
    final avgScore = sessions.isEmpty ? 0.0 : sessions.map((s) => s.score).reduce((a, b) => a + b) / sessions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('专注力训练')),
      body: _isTraining ? _buildTrainingView() : _buildHomeView(avgScore, sessions.length),
    );
  }

  Widget _buildHomeView(double avgScore, int totalSessions) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.psychology, size: 48, color: Colors.purple),
                const SizedBox(height: 16),
                Text('平均分: ${avgScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('已完成 $totalSessions 次训练', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('训练项目', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._games.asMap().entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${e.key + 1}')),
            title: Text(e.value),
            subtitle: const Text('点击开始训练'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _startTraining(e.key),
          ),
        )),
      ],
    );
  }

  Widget _buildTrainingView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('游戏 ${_currentGame + 1}: ${_games[_currentGame]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildGameContent(),
          const SizedBox(height: 24),
          Text('分数: $_score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('剩余时间: $_timeLeft秒', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _endTraining,
            child: const Text('结束训练'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_currentGame) {
      case 0: return _buildMemoryGame();
      case 1: return _buildAttentionGame();
      case 2: return _buildReactionGame();
      case 3: return _buildVisualGame();
      default: return const Text('选择游戏');
    }
  }

  Widget _buildMemoryGame() {
    return Column(
      children: [
        const Text('记住数字序列', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(9, (i) {
            final show = _sequence.isEmpty || _userIndex > 0;
            return GestureDetector(
              onTap: () => _checkMemoryTap(i),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: show ? Colors.blue.withOpacity(0.2) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: show ? Text('${i + 1}', style: const TextStyle(fontSize: 24)) : const Text('?')),
              ),
            );
          }),
        ),
        if (_sequence.isEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sequence = List.generate(4, (_) => Random().nextInt(9));
                _userIndex = 0;
              });
            },
            child: const Text('开始记忆'),
          ),
        ],
      ],
    );
  }

  Widget _buildAttentionGame() {
    return Column(
      children: [
        const Text('数一数有多少个"X"', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'X O X X O O X X X O X O X O X X O X O X X X O X O O X X',
            style: TextStyle(fontSize: 16, letterSpacing: 4),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [12, 14, 15, 16].map((n) => ElevatedButton(onPressed: () => _checkAnswer(n == 16), child: Text('$n'))).toList(),
        ),
      ],
    );
  }

  Widget _buildReactionGame() {
    return Column(
      children: [
        const Text('点击反应测试', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('等待...', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() => _score += 10);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反应+10!')));
          },
          child: const Text('点击'),
        ),
      ],
    );
  }

  Widget _buildVisualGame() {
    return Column(
      children: [
        const Text('找出不同的颜色', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final isOdd = i % 2 == 1;
            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isOdd ? Colors.blue : Colors.blue.shade200,
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3, 4, 5].map((n) => ElevatedButton(
            onPressed: () => _checkAnswer(n == 2),
            child: Text('$n'),
          )).toList(),
        ),
      ],
    );
  }

  void _startTraining(int gameIndex) {
    setState(() {
      _isTraining = true;
      _currentGame = gameIndex;
      _score = 0;
      _timeLeft = 30;
      _sequence = [];
    });
  }

  void _checkMemoryTap(int index) {
    if (_userIndex < _sequence.length && index == _sequence[_userIndex]) {
      setState(() {
        _score += 5;
        _userIndex++;
      });
      if (_userIndex >= _sequence.length) {
        setState(() {
          _sequence = List.generate(4, (_) => Random().nextInt(9));
          _userIndex = 0;
        });
      }
    }
  }

  void _checkAnswer(bool correct) {
    setState(() => _score += correct ? 20 : -5);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(correct ? '正确 +20!' : '错误 -5')),
    );
  }

  void _endTraining() {
    final session = FocusTrainingSession(
      trainingType: _games[_currentGame],
      durationMinutes: 30 - _timeLeft,
      score: _score.toDouble(),
      difficultyLevel: 1,
      accuracyRate: _score / 100,
      completedAt: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
    ref.read(focusTrainingProvider.notifier).addSession(session);
    setState(() => _isTraining = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('训练完成！得分: $_score')));
  }
}