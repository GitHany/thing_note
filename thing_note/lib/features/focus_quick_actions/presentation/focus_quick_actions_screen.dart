import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Focus Mode State Provider
final focusModeActiveProvider = StateProvider<bool>((ref) => false);
final focusModeDurationProvider = StateProvider<int>((ref) => 25 * 60); // 25 minutes default
final focusModeRemainingProvider = StateProvider<int>((ref) => 25 * 60);

// Quick Actions for Focus Mode
final focusQuickActionsProvider = StateNotifierProvider<FocusQuickActionsNotifier, List<FocusQuickAction>>((ref) {
  return FocusQuickActionsNotifier();
});

class FocusQuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final bool enabled;

  FocusQuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.enabled = true,
  });

  FocusQuickAction copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    String? route,
    bool? enabled,
  }) {
    return FocusQuickAction(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      route: route ?? this.route,
      enabled: enabled ?? this.enabled,
    );
  }
}

class FocusQuickActionsNotifier extends StateNotifier<List<FocusQuickAction>> {
  FocusQuickActionsNotifier() : super([
    FocusQuickAction(
      id: '1',
      title: '新建记录',
      icon: Icons.add_circle,
      color: Colors.blue,
      route: '/record/new',
    ),
    FocusQuickAction(
      id: '2',
      title: '语音记录',
      icon: Icons.mic,
      color: Colors.red,
      route: '/voice-recorder',
    ),
    FocusQuickAction(
      id: '3',
      title: '拍照',
      icon: Icons.camera_alt,
      color: Colors.green,
      route: '/quick-photo-capture',
    ),
    FocusQuickAction(
      id: '4',
      title: '查看收藏',
      icon: Icons.star,
      color: Colors.amber,
      route: '/record-favorites',
    ),
    FocusQuickAction(
      id: '5',
      title: '搜索',
      icon: Icons.search,
      color: Colors.purple,
      route: '/search',
    ),
    FocusQuickAction(
      id: '6',
      title: '快速笔记',
      icon: Icons.note,
      color: Colors.teal,
      route: '/quick-notes',
    ),
  ]);

  void updateAction(FocusQuickAction action) {
    state = [
      for (final a in state)
        if (a.id == action.id) action else a,
    ];
  }

  void reorderActions(int oldIndex, int newIndex) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == oldIndex)
          state[newIndex]
        else if (i == newIndex)
          state[oldIndex]
        else
          state[i],
    ];
  }
}

class FocusQuickActionsScreen extends ConsumerStatefulWidget {
  const FocusQuickActionsScreen({super.key});

  @override
  ConsumerState<FocusQuickActionsScreen> createState() => _FocusQuickActionsScreenState();
}

class _FocusQuickActionsScreenState extends ConsumerState<FocusQuickActionsScreen> {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ref.read(focusModeDurationProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = ref.read(focusModeDurationProvider);
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _completedPomodoros++;
    });
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('专注完成!'),
          ],
        ),
        content: Text('你完成了 $_completedPomodoros 个番茄钟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _remainingSeconds = ref.read(focusModeDurationProvider);
              });
            },
            child: const Text('继续专注'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(focusQuickActionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('专注模式', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimer(),
          const SizedBox(height: 32),
          Expanded(
            child: _buildActionsGrid(actions),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = 1 - (_remainingSeconds / ref.read(focusModeDurationProvider));

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: _isRunning ? Colors.green : Colors.white,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRunning ? '专注中...' : '准备开始',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRunning)
              _buildTimerButton(
                icon: Icons.play_arrow,
                label: '开始',
                color: Colors.green,
                onPressed: _startTimer,
              )
            else
              _buildTimerButton(
                icon: Icons.pause,
                label: '暂停',
                color: Colors.orange,
                onPressed: _pauseTimer,
              ),
            const SizedBox(width: 16),
            _buildTimerButton(
              icon: Icons.refresh,
              label: '重置',
              color: Colors.grey,
              onPressed: _resetTimer,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              '$_completedPomodoros 个番茄钟',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildActionsGrid(List<FocusQuickAction> actions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷操作',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(action);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(FocusQuickAction action) {
    return InkWell(
      onTap: action.enabled ? () => context.push(action.route) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: action.enabled ? action.color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(
                color: action.enabled ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final durations = [15, 25, 30, 45, 60];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentDuration = ref.read(focusModeDurationProvider);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '专注设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '专注时长',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: durations.map((d) {
                    final isSelected = currentDuration == d * 60;
                    return ChoiceChip(
                      label: Text('$d 分钟'),
                      selected: isSelected,
                      selectedColor: Colors.green,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(focusModeDurationProvider.notifier).state = d * 60;
                          setState(() {
                            _remainingSeconds = d * 60;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('保存设置'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
