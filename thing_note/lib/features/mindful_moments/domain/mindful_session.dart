import 'package:flutter_riverpod/flutter_riverpod.dart';

class MindfulSession {
  final int? id;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isCompleted;

  MindfulSession({
    this.id,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    this.isCompleted = false,
  });

  MindfulSession copyWith({
    int? id,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isCompleted,
  }) {
    return MindfulSession(
      id: id ?? this.id,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

final mindfulSessionProvider = StateNotifierProvider<MindfulSessionNotifier, AsyncValue<List<MindfulSession>>>((ref) {
  return MindfulSessionNotifier();
});

class MindfulSessionNotifier extends StateNotifier<AsyncValue<List<MindfulSession>>> {
  MindfulSessionNotifier() : super(const AsyncValue.loading());

  Future<void> loadSessions() async {
    state = const AsyncValue.data([]);
  }

  Future<void> addSession(MindfulSession session) async {
    state = AsyncValue.data([...state.value ?? [], session]);
  }

  Future<void> completeSession(int sessionId) async {
    final sessions = state.value ?? [];
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      sessions[index] = sessions[index].copyWith(
        isCompleted: true,
        endedAt: DateTime.now(),
      );
      state = AsyncValue.data([...sessions]);
    }
  }
}