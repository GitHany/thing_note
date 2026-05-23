import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class FocusZonesScreen extends ConsumerStatefulWidget {
  const FocusZonesScreen({super.key});

  @override
  ConsumerState<FocusZonesScreen> createState() => _FocusZonesScreenState();
}

class _FocusZonesScreenState extends ConsumerState<FocusZonesScreen> {
  List<FocusZone> _zones = [];
  FocusZone? _activeZone;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isBreak = false;
  int _completedPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _zones = [
      FocusZone(name: 'Work', focusDuration: 25, breakDuration: 5, color: Colors.blue),
      FocusZone(name: 'Study', focusDuration: 45, breakDuration: 10, color: Colors.green),
      FocusZone(name: 'Creative', focusDuration: 90, breakDuration: 15, color: Colors.purple),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Zones'),
      ),
      body: _activeZone != null ? _buildActiveSession() : _buildZoneList(),
      floatingActionButton: _activeZone == null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddZoneDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Zone'),
            )
          : null,
    );
  }

  Widget _buildZoneList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _startSession(zone),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: zone.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timer, color: zone.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${zone.focusDuration}min focus • ${zone.breakDuration}min break',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    color: Colors.green,
                    onPressed: () => _startSession(zone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSession() {
    // ignore: unused_local_variable
    final progress = _elapsedSeconds / (_isBreak
        ? (_activeZone!.breakDuration * 60)
        : (_activeZone!.focusDuration * 60));
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _activeZone!.color,
                width: 8,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isBreak ? 'Break' : 'Focus',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _activeZone!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pomodoro #${_completedPomodoros + 1}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (_isBreak) {
                    _startFocus();
                  } else {
                    _startBreak();
                  }
                },
                icon: Icon(_isBreak ? Icons.play_arrow : Icons.pause),
                label: Text(_isBreak ? 'Start Focus' : 'Take Break'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _stopSession,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSession(FocusZone zone) {
    setState(() {
      _activeZone = zone;
      _elapsedSeconds = 0;
      _isBreak = false;
    });
    _startFocus();
  }

  void _startFocus() {
    setState(() => _isBreak = false);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
      
      if (_elapsedSeconds >= _activeZone!.focusDuration * 60) {
        timer.cancel();
        _showFocusCompleteDialog();
      }
    });
  }

  void _startBreak() {
    setState(() {
      _isBreak = true;
      _elapsedSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
      
      if (_elapsedSeconds >= _activeZone!.breakDuration * 60) {
        timer.cancel();
        _completedPomodoros++;
        _showBreakCompleteDialog();
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() {
      _activeZone = null;
      _elapsedSeconds = 0;
      _isBreak = false;
    });
  }

  void _showFocusCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Focus Complete! 🎉'),
        content: const Text('Time for a break. Would you like to rest?'),
        actions: [
          TextButton(
            onPressed: _stopSession,
            child: const Text('End Session'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startBreak();
            },
            child: const Text('Take Break'),
          ),
        ],
      ),
    );
  }

  void _showBreakCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break Over'),
        content: const Text('Ready for another focus session?'),
        actions: [
          TextButton(
            onPressed: _stopSession,
            child: const Text('End'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startFocus();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showAddZoneDialog(BuildContext context) {
    final nameController = TextEditingController();
    int focusDuration = 25;
    int breakDuration = 5;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Focus Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Zone Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Focus: '),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() {
                        if (focusDuration > 5) focusDuration -= 5;
                      }),
                    ),
                    Text('$focusDuration min'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => focusDuration += 5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Break: '),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() {
                        if (breakDuration > 1) breakDuration -= 1;
                      }),
                    ),
                    Text('$breakDuration min'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => breakDuration += 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red]
                      .map((color) => GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _zones.add(FocusZone(
                      name: nameController.text,
                      focusDuration: focusDuration,
                      breakDuration: breakDuration,
                      color: selectedColor,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class FocusZone {
  final String name;
  final int focusDuration;
  final int breakDuration;
  final Color color;

  FocusZone({
    required this.name,
    required this.focusDuration,
    required this.breakDuration,
    required this.color,
  });
}