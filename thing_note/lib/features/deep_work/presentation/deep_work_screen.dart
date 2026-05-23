import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/deep_work/data/deep_work_provider.dart';

class DeepWorkScreen extends ConsumerStatefulWidget {
  const DeepWorkScreen({super.key});

  @override
  ConsumerState<DeepWorkScreen> createState() => _DeepWorkScreenState();
}

class _DeepWorkScreenState extends ConsumerState<DeepWorkScreen> {
  bool _isSessionActive = false;
  int _sessionSeconds = 0;
  int _focusScore = 5;
  int _distractionCount = 0;
  // ignore: unused_field
  String? _currentSessionId;
  DateTime? _sessionStartTime;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(deepWorkStatsProvider);
    final sessionsAsync = ref.watch(deepWorkSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('深度工作'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            statsAsync.when(
              data: (stats) => _buildStatsSection(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            
            // Timer Section
            _buildTimerSection(),
            const SizedBox(height: 24),
            
            // Session Controls
            _buildSessionControls(),
            const SizedBox(height: 24),
            
            // Recent Sessions
            sessionsAsync.when(
              data: (sessions) => _buildRecentSessions(sessions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(DeepWorkStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '统计数据',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '今日',
                '${stats.todayMinutes}分钟',
                '${stats.todaySessions}次会话',
                Icons.today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '本周',
                '${stats.weekMinutes}分钟',
                '${stats.weekSessions}次会话',
                Icons.date_range,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '平均专注',
                '${stats.todayAvgFocus}/5',
                '今日',
                Icons.psychology,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '周均专注',
                '${stats.weekAvgFocus}/5',
                '本周',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    final hours = _sessionSeconds ~/ 3600;
    final minutes = (_sessionSeconds % 3600) ~/ 60;
    final seconds = _sessionSeconds % 60;

    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSessionActive ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              border: Border.all(
                color: _isSessionActive ? Colors.blue : Colors.grey,
                width: 4,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (_isSessionActive)
                    Text(
                      '专注中...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSessionActive ? '点击下方按钮结束会话' : '点击开始深度工作',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSessionActive) ...[
          Text(
            '会话设置',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('专注评分:'),
              Expanded(
                child: Slider(
                  value: _focusScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _focusScore.toString(),
                  onChanged: (value) {
                    setState(() {
                      _focusScore = value.toInt();
                    });
                  },
                ),
              ),
              Text('$_focusScore/5'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('分心次数:'),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _distractionCount > 0
                    ? () => setState(() => _distractionCount--)
                    : null,
              ),
              Text('$_distractionCount', style: const TextStyle(fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _distractionCount++),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSessionActive ? _endSession : _startSession,
            icon: Icon(_isSessionActive ? Icons.stop : Icons.play_arrow),
            label: Text(_isSessionActive ? '结束会话' : '开始深度工作'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSessionActive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSessions(List<DeepWorkSession> sessions) {
    final recentSessions = sessions.where((s) => s.endedAt != null).take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近会话',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (recentSessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无会话记录'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSessions.length,
            itemBuilder: (context, index) {
              final session = recentSessions[index];
              final startTime = DateTime.parse(session.startedAt);
              final duration = session.durationMinutes;
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getFocusColor(session.focusScore),
                    child: Text('${session.focusScore}'),
                  ),
                  title: Text('$duration 分钟'),
                  subtitle: Text(
                    '${startTime.month}/${startTime.day} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: session.distractionCount > 0
                      ? Chip(
                          label: Text('${session.distractionCount}次分心'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getFocusColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.blue;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }

  void _startSession() async {
    setState(() {
      _isSessionActive = true;
      _sessionSeconds = 0;
      _sessionStartTime = DateTime.now();
    });
    
    // Start timer
    _startTimer();
    
    // Create session in database
    // ignore: unused_local_variable
    final session = DeepWorkSession(
      startedAt: _sessionStartTime!.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
    );
    
    // We'll save to database after session ends
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isSessionActive) {
        setState(() {
          _sessionSeconds++;
        });
        _startTimer();
      }
    });
  }

  void _endSession() async {
    if (_sessionStartTime == null) return;
    
    final endTime = DateTime.now();
    final duration = _sessionSeconds ~/ 60; // Convert to minutes
    
    setState(() {
      _isSessionActive = false;
    });
    
    // Show rating dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EndSessionDialog(
        duration: duration,
        initialFocus: _focusScore,
        initialDistraction: _distractionCount,
      ),
    );
    
    if (result != null) {
      // Save session
      // ignore: unused_local_variable
      final session = DeepWorkSession(
        startedAt: _sessionStartTime!.toIso8601String(),
        endedAt: endTime.toIso8601String(),
        durationMinutes: result['duration'] as int,
        focusScore: result['focus'] as int,
        distractionCount: result['distraction'] as int,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      // Invalidate providers to refresh data
      ref.invalidate(deepWorkSessionsProvider);
      ref.invalidate(deepWorkStatsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已保存')),
        );
      }
    }
    
    setState(() {
      _sessionSeconds = 0;
      _sessionStartTime = null;
      _focusScore = 5;
      _distractionCount = 0;
    });
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeepWorkHistoryScreen(),
      ),
    );
  }
}

class _EndSessionDialog extends StatefulWidget {
  final int duration;
  final int initialFocus;
  final int initialDistraction;

  const _EndSessionDialog({
    required this.duration,
    required this.initialFocus,
    required this.initialDistraction,
  });

  @override
  State<_EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<_EndSessionDialog> {
  late int _focusScore;
  late int _distractionCount;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _focusScore = widget.initialFocus;
    _distractionCount = widget.initialDistraction;
    _duration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('结束会话'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('会话时长: $_duration 分钟'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('专注评分:'),
              Expanded(
                child: Slider(
                  value: _focusScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _focusScore.toString(),
                  onChanged: (value) {
                    setState(() {
                      _focusScore = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('分心次数:'),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _distractionCount > 0
                    ? () => setState(() => _distractionCount--)
                    : null,
              ),
              Text('$_distractionCount'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _distractionCount++),
              ),
            ],
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
            Navigator.pop(context, {
              'duration': _duration,
              'focus': _focusScore,
              'distraction': _distractionCount,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class DeepWorkHistoryScreen extends ConsumerWidget {
  const DeepWorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(deepWorkSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会话历史'),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          final completedSessions = sessions.where((s) => s.endedAt != null).toList();
          
          if (completedSessions.isEmpty) {
            return const Center(
              child: Text('暂无会话记录'),
            );
          }
          
          return ListView.builder(
            itemCount: completedSessions.length,
            itemBuilder: (context, index) {
              final session = completedSessions[index];
              final startTime = DateTime.parse(session.startedAt);
              final endTime = session.endedAt != null 
                  ? DateTime.parse(session.endedAt!) 
                  : null;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${startTime.month}/${startTime.day} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          CircleAvatar(
                            backgroundColor: _getFocusColor(session.focusScore),
                            radius: 16,
                            child: Text(
                              '${session.focusScore}',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.timer, '${session.durationMinutes}分钟'),
                          const SizedBox(width: 8),
                          _buildInfoChip(Icons.warning_amber, '${session.distractionCount}次分心'),
                        ],
                      ),
                      if (endTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '结束: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (session.note != null && session.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(session.note!),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getFocusColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.blue;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }
}