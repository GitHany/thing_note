import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_breathing/data/breathing_provider.dart';
import 'package:thing_note/features/focus_breathing/domain/breathing_model.dart';

class FocusBreathingScreen extends ConsumerStatefulWidget {
  const FocusBreathingScreen({super.key});

  @override
  ConsumerState<FocusBreathingScreen> createState() => _FocusBreathingScreenState();
}

class _FocusBreathingScreenState extends ConsumerState<FocusBreathingScreen>
    with SingleTickerProviderStateMixin {
  BreathingPattern _selectedPattern = BreathingPattern.relax478;
  bool _isActive = false;
  int _currentPhase = 0;
  int _countdown = 4;
  Timer? _timer;
  DateTime? _startTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注呼吸训练'),
      ),
      body: Column(
        children: [
          // Pattern Selector
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: BreathingPattern.values.map((pattern) {
                final isSelected = _selectedPattern == pattern;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPattern = pattern),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pattern.name.split(' ')[0],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Breathing Animation
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _isActive ? 200 : 150,
                    height: _isActive ? 200 : 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.8),
                          Theme.of(context).primaryColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isActive ? '$_countdown' : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isActive ? _getPhaseLabel() : '点击开始',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _selectedPattern.description.split('\n')[0],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isActive ? _stopSession : _startSession,
                    icon: Icon(_isActive ? Icons.stop : Icons.play_arrow),
                    label: Text(_isActive ? '停止' : '开始训练'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Stats
          _buildStatsSection(),
        ],
      ),
    );
  }

  String _getPhaseLabel() {
    if (_selectedPattern == BreathingPattern.box) {
      final labels = ['吸气', '屏息', '呼气', '暂停'];
      return labels[_currentPhase % 4];
    } else if (_selectedPattern == BreathingPattern.relax478) {
      final labels = ['吸气', '屏息', '呼气'];
      return labels[_currentPhase % 3];
    } else {
      return _currentPhase % 2 == 0 ? '吸气' : '呼气';
    }
  }

  void _startSession() {
    setState(() {
      _isActive = true;
      _startTime = DateTime.now();
      _currentPhase = 0;
    });
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    _timer?.cancel();
    final phases = _selectedPattern.phases;
    
    if (_selectedPattern == BreathingPattern.box) {
      _runBoxBreathing(phases);
    } else {
      _runSimpleBreathing(phases);
    }
  }

  void _runBoxBreathing(List<int> phases) {
    int phaseIndex = _currentPhase % 4;
    int seconds = phases[phaseIndex];
    _countdown = seconds;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _currentPhase++;
          final nextPhases = _selectedPattern.phases;
          int nextIndex = _currentPhase % 4;
          _countdown = nextPhases[nextIndex];
        }
      });
    });
  }

  void _runSimpleBreathing(List<int> phases) {
    int phaseIndex = _currentPhase % phases.length;
    int seconds = phases[phaseIndex];
    _countdown = seconds;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _currentPhase++;
          final nextPhases = _selectedPattern.phases;
          int nextIndex = _currentPhase % nextPhases.length;
          _countdown = nextPhases[nextIndex];
        }
      });
    });
  }

  void _stopSession() {
    _timer?.cancel();
    
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      final session = BreathingSession(
        id: 0,
        sessionType: _selectedPattern.name,
        durationSeconds: duration,
        completed: duration > 30,
        startedAt: _startTime!,
        endedAt: DateTime.now(),
      );
      ref.read(breathingSessionNotifierProvider.notifier).saveSession(session);
    }
    
    setState(() {
      _isActive = false;
      _currentPhase = 0;
      _countdown = 4;
    });
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('今日', '3', '次'),
          _buildMiniStat('总时长', '15', '分钟'),
          _buildMiniStat('完成率', '85', '%'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          '$label $unit',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}